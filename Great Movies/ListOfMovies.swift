//
//  ContentView.swift
//  Great Movies
//
//  Created by Juliano Alvarenga on 08/03/24.
//


import SwiftUI
import Observation
import SwiftData

enum OprationState: Equatable {
    case success
    case failure
    case loading
    case notStarted
}

@Observable
class ListOfMoviesViewModel {

    var state: OprationState = .notStarted
    var movies = [Movie]()
    var movies2 = [DataModel]()

    let interactor: LisOfMoviesInteracting

    init(interactor: LisOfMoviesInteracting) {
        self.interactor = interactor
    }

    @MainActor
    func fetchMovies(in page: Int) async throws -> [FetchedMovie] {
        state = .loading
        do {
            let items = try await interactor.fetchMovies(in: page)
            state = .success
            return makeFetchedMovie(with: items.movies)
        } catch {
            print(error.localizedDescription)
            state = .failure // handle UI failure
            throw error
        }
    }

    private func makeFetchedMovie(with movies: [Movie]) -> [FetchedMovie]{
        movies.map {
            .init(
                adult: $0.adult,
                backdropPath: $0.backdropPath,
                genreIDS: $0.genreIDS,
                originalLanguage: $0.originalLanguage,
                originalTitle: $0.originalLanguage,
                overview: $0.overview,
                popularity: $0.popularity,
                posterPath: $0.posterPath,
                releaseDate: $0.releaseDate,
                title: $0.title,
                video: $0.video,
                voteAverage: $0.voteAverage,
                voteCount: $0.voteCount
            )
        }
    }

    func makeUrl(for path: String?) -> String {
        let baseURL = "https://image.tmdb.org/t/p/"
        let size = "w200"
        let fullURL = baseURL + size + (path ?? "")
        return fullURL
    }

    // Creating data model for isolation and unique ID.
    struct FetchedMovie: Identifiable, Hashable {
        let id = UUID()
        let adult: Bool
        let backdropPath: String?
        let genreIDS: [Int]
        let originalLanguage: String
        let originalTitle, overview: String
        let popularity: Double
        let posterPath, releaseDate, title: String
        let video: Bool
        let voteAverage: Double
        let voteCount: Int
    }
}

typealias DataModel = ListOfMoviesViewModel.FetchedMovie
struct ListOfMovies: View {
    @State var paginationOffset: Int?
    @State var viewModel = ListOfMoviesViewModel(interactor: LisOfMoviesInteractor())
    var body: some View {
        NavigationStack {
                ScrollView {
                    Paginating(
                        viewModel: $viewModel,
                        paginationOffset: $paginationOffset) { movies in
                            LazyVGrid(
                                columns:[
                                    GridItem(.flexible(), spacing: -4),
                                    GridItem(.flexible())
                                ],spacing: 16
                            ) {
                                ForEach(movies) { movie in
                                    NavigationLink(value: movie) {
                                        VStack(alignment: .leading) {
                                            AsyncImageView(
                                                urlString: viewModel.makeUrl(for: movie.posterPath),
                                                size: .init(width: 200, height: 250)
                                            )
                                            Text(movie.title)
                                                .font(.subheadline)
                                                .fontWeight(.bold)
                                                .lineLimit(1)
                                                .foregroundColor(.title)
                                            Text("\(movie.voteAverage)")
                                                .font(.subheadline)
                                                .foregroundColor(.title)
                                                .onAppear {
                                                    if paginationOffset != nil, movies.last?.id == movie.id {
                                                        paginationOffset! += 1
                                                    }
                                                }
                                        }
                                    }

                                }
                            }
                        }
                }
                .navigationDestination(for: DataModel.self, destination: { movie in
                    Text(movie.title)
                })
                .navigationTitle("Movies")
                .task(priority: .background) {
                    paginationOffset = 1
                }
                if viewModel.state == .loading {
                    ProgressView()
                }
        }
    }
    
}


struct Paginating<Content: View>: View {
    @Binding var viewModel: ListOfMoviesViewModel
    @Binding var paginationOffset: Int?
    @ViewBuilder var content: ([DataModel]) -> Content
    @State private var movies = [DataModel]()
    @Environment(\.modelContext) private var context
    var body: some View {
        content(movies)
            .onChange(of: paginationOffset) { oldValue, newValue in
                guard let newValue else { return }
                print(newValue)
                Task {
                    let fetchedMovies = try await viewModel.fetchMovies(in: newValue)
                    movies.append(contentsOf: fetchedMovies)
                }

            }
    }
}





#Preview {
    NavigationStack {
        ListOfMovies()
    }
}



struct AsyncImageView: View {
    @State private var image: UIImage?
    let urlString: String
    let size: CGSize
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size.width)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .clipped()
            } else {
                ZStack {
                    Rectangle()
                        .foregroundStyle(.gray)
                        .frame(width: size.width, height: size.height)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    ProgressView()
                }
            }
        }
        .onAppear {
            if let url = URL(string: urlString) {
                ImageLoader.shared.loadImage(from: url) { loadedImage in
                    self.image = loadedImage
                }

            }
        }
    }
}


final class ImageLoader: ObservableObject {
    static let shared = ImageLoader()
    private let cache = NSCache<NSString, UIImage>()

    private init() {}

    func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        // Check cache first
        if let cachedImage = cache.object(forKey: url.absoluteString as NSString) {
            completion(cachedImage)
            return
        }

        // Download image if not in cache
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let image = UIImage(data: data) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            DispatchQueue.main.async {
                self.cache.setObject(image, forKey: url.absoluteString as NSString)
                completion(image)
            }
        }.resume()
    }
}
