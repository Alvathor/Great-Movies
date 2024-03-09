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

    enum Errors: Error {
        case failtToMakePersistedMovieData
        case failtToFetchPersistedMoviesCount
    }
    var state: OprationState = .notStarted
    var movies = [DataModel]()
    var page = 0
    var persistedCount = 0
    private let itemPerPage = 20

    let interactor: LisOfMoviesInteracting

    /// Injecting `ModelContainer` because it's sendable and we can create `modelContext`
    /// for background havy tasks
    let container: ModelContainer

    init(interactor: LisOfMoviesInteracting, container: ModelContainer) {
        self.interactor = interactor
        self.container = container

//        pagesSaved()
//        fetchMovies(in: page)
    }

    func fetchMovies(in page: Int) {
        if persistedCount > 0 {
            fetchMoviesFromStorage()
        } else {
            fetchMovies(in: page)
        }

    }

    func pagesSaved() {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<PersistedMovieData>()
        do {
            persistedCount = try context.fetchCount(descriptor)
            page = persistedCount / itemPerPage
        } catch {
            print(error.localizedDescription)
        }
    }

    @MainActor
    func fetchMoviesFromApi(in page: Int) async {
        state = .loading
        do {
            let items = try await interactor.fetchMovies(in: page)
            state = .success
//            await save(movies: makePersistedMovieData(with: items.movies))
            movies.append(contentsOf: makeFetchedMovie(with: items.movies))
        } catch {
            print(error.localizedDescription)
            state = .failure // handle UI failure
        }
    }

    private func fetchMoviesFromStorage() {
        let context = ModelContext(container)
        var descriptor = FetchDescriptor<PersistedMovieData>()
        descriptor.fetchLimit = itemPerPage
        do {
            let totalCount = try context.fetchCount(descriptor)
            page = totalCount / itemPerPage
            let movies = try context.fetch(descriptor)
            print(movies.count)
        } catch {

        }
    }

    private func fetchData(for urlString: String?) async  -> Data? {
        guard let url = URL(string: makeUrl(for: urlString)) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return data
        } catch {
            return nil
        }

    }
    private func save(movies: [PersistedMovieData]) {
        // Background context
        let context = ModelContext(container)
        movies.forEach { movie in
            context.insert(movie)
            do {
             try context.save()
            } catch {

            }
        }
       
    }

    private func makePersistedMovieData(with movies: [Movie]) async -> [PersistedMovieData] {
        var persistedMovies: [PersistedMovieData] = []

        // Create a task group to perform concurrent downloads
        await withTaskGroup(of: PersistedMovieData.self) { group in
            for movie in movies {
                group.addTask {
                    let backdropPathData = await self.fetchData(for: movie.backdropPath)
                    let posterPathData = await self.fetchData(for: movie.posterPath)

                    // Create and return a PersistedMovieData object
                    return PersistedMovieData(
                        id: movie.id,
                        adult: movie.adult,
                        backdropPath: backdropPathData,
                        genreIDS: movie.genreIDS,
                        originalLanguage: movie.originalLanguage,
                        originalTitle: movie.title,
                        overview: movie.overview,
                        popularity: movie.popularity,
                        posterPath: posterPathData,
                        releaseDate: movie.releaseDate,
                        title: movie.title,
                        video: movie.video,
                        voteAverage: movie.voteAverage,
                        voteCount: movie.voteCount
                    )
                }
            }

            // Collect results from all tasks
            for await persistedMovie in group {
                persistedMovies.append(persistedMovie)
            }
        }

        return persistedMovies
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
    @Bindable var viewModel: ListOfMoviesViewModel
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(
                    columns:[
                        GridItem(.flexible(), spacing: -4),
                        GridItem(.flexible())
                    ],spacing: 16
                ) {
                    ForEach(viewModel.movies) { movie in
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
                                        if viewModel.movies.last?.id == movie.id {
                                            viewModel.page += 1
                                        }
                                    }
                            }
                        }

                    }
                }
                .onChange(of: viewModel.page) { oldValue, newValue in
                    Task { await viewModel.fetchMoviesFromApi(in: newValue) }
                }
            }
            .navigationDestination(for: DataModel.self, destination: { movie in
                Text(movie.title)
            })
            .navigationTitle("Movies")
            .task(priority: .background) {
                viewModel.page = 1
            }
            if viewModel.state == .loading {
                ProgressView()
            }
        }
    }
    
}

//
//struct Paginating<Content: View>: View {
//    @Binding var viewModel: ListOfMoviesViewModel
//    @ViewBuilder var content: ([DataModel]) -> Content
//    @Environment(\.modelContext) private var context
//    var body: some View {
//        content(viewModel.movies)
//            .onChange(of: viewModel.page) { oldValue, newValue in
////                guard let newValue else { return }
//                print(newValue)
//                Task {
//                     await viewModel.fetchMoviesFromApi(in: newValue)
////                    movies.append(contentsOf: fetchedMovies)
//                }
//
//            }
//    }
//}





//#Preview {
//    do {
//        let fullSchema = Schema([PersistedMovieData.self])
//        let config = ModelConfiguration("initialConfig", schema: fullSchema, isStoredInMemoryOnly: true)
//        let container = try ModelContainer(for: fullSchema, configurations: config)
//    } catch {
//        fatalError("Failed to configure SwiftData container.")
//    }
//    NavigationStack {
//        ListOfMovies(viewModel: .init(interactor: LisOfMoviesInteractor(), container: container))
//    }
//}



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
