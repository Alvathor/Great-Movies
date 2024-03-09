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
final class ListOfMoviesViewModel: Sendable {

    enum Errors: Error {
        case failtToMakePersistedMovieData
        case failtToFetchPersistedMoviesCount
    }

    var state: OprationState = .notStarted
    var movies = [DataModel]()
    var page = 1
    var totalOFpersistedPage = 0
    var persistedCount = 0 { didSet {
        totalOFpersistedPage = persistedCount / itemPerPage
    }}
    private let itemPerPage = 20

    let interactor: LisOfMoviesInteracting

    /// Injecting `ModelContainer` because it's sendable and we can create `modelContext`
    /// for background havy tasks
    let container: ModelContainer

    init(interactor: LisOfMoviesInteracting, container: ModelContainer) {
        self.interactor = interactor
        self.container = container

        persistedCount = fetchCount()


        Task { await fetchMovies() }
    }

    func fetchMovies() async  {
        if page <= totalOFpersistedPage {
            await fetchMoviesFromStorage()
        } else {
            await fetchMoviesFromApi()
        }

    }

    private func fetchCount() -> Int {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<PersistedMovieData>()
        do {
            return try context.fetchCount(descriptor)
        } catch {
            print(error.localizedDescription)
        }
        return 0
    }


    func fetchMoviesFromApi() async {
        state = .loading
        do {
            let items = try await interactor.fetchMovies(in: page)
            state = .success
            movies.append(contentsOf: makeDataModel(with: items.movies))
            await save(movies: makePersistedMovieData(with: items.movies))
        } catch {
            print(error.localizedDescription)
            state = .failure // handle UI failure
        }
    }

    private func fetchMoviesFromStorage() async {
        let context = ModelContext(container)
        var descriptor = FetchDescriptor<PersistedMovieData>()
        descriptor.fetchLimit = itemPerPage
        do {
            let totalCount = try context.fetchCount(descriptor)

            let pageOffset = min(persistedCount, movies.count)
            descriptor.fetchOffset = pageOffset

            let persistedMovies = try context.fetch(descriptor)
            let fetchedMovies = await makeDataModel(with: persistedMovies)
            movies.append(contentsOf: fetchedMovies)
            page = movies.count / itemPerPage
        } catch {
            
        }
    }

    // Example method to fetch and save an image, returning the file path
    private func fetchAndSaveImage(for imagePath: String?) async throws -> String {
        var filePath = ""
        do {
            let fileManager = FileManager.default
            let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let fileURL = documentDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
            let imageData = await fetchData(for: imagePath)
            try imageData?.write(to: fileURL)
            filePath = fileURL.path
        } catch {
            throw Errors.failtToMakePersistedMovieData
        }

        return filePath
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
        await withTaskGroup(of: PersistedMovieData?.self) { group in
            for movie in movies {
                group.addTask { [weak self] in
                    do {
                        let backdropPathData = try await self?.fetchAndSaveImage(for: self?.makeUrl(for: movie.backdropPath))
                        let posterPathData = try await self?.fetchAndSaveImage(for: self?.makeUrl(for: movie.posterPath))

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
                    } catch {
                        return nil
                    }
                }
            }

            // Collect results from all tasks
            for await persistedMovie in group {
                guard let persistedMovie else { return }
                persistedMovies.append(persistedMovie)
            }
        }

        return persistedMovies
    }

    private func makeDataModel(with movies: [Movie]) -> [DataModel]{
        movies.map {
            .init(
                adult: $0.adult,
                backdropPath: makeUrl(for: $0.backdropPath),
                genreIDS: $0.genreIDS,
                originalLanguage: $0.originalLanguage,
                originalTitle: $0.originalLanguage,
                overview: $0.overview,
                popularity: $0.popularity,
                posterPath: makeUrl(for: $0.posterPath),
                releaseDate: $0.releaseDate,
                title: $0.title,
                video: $0.video,
                voteAverage: $0.voteAverage.round,
                voteCount: $0.voteCount
            )
        }
    }

    private func makeDataModel(with movies: [PersistedMovieData]) async -> [DataModel] {
        var persistedMovies: [DataModel] = []

        // Create a task group to perform concurrent downloads
        await withTaskGroup(of: DataModel?.self) { group in
            for movie in movies {
                group.addTask { [weak self] in
                    do {
                        let backdropPathData = try await self?.fetchAndSaveImage(for: self?.makeUrl(for: movie.backdropPath))
                        let posterPathData = try await self?.fetchAndSaveImage(for: self?.makeUrl(for: movie.posterPath))

                        // Create and return a PersistedMovieData object
                        return DataModel(
                            adult: movie.adult,
                            backdropPath: backdropPathData ?? "",
                            genreIDS: movie.genreIDS,
                            originalLanguage: movie.originalLanguage,
                            originalTitle: movie.title,
                            overview: movie.overview,
                            popularity: movie.popularity,
                            posterPath: posterPathData ?? "",
                            releaseDate: movie.releaseDate,
                            title: movie.title,
                            video: movie.video,
                            voteAverage: movie.voteAverage.round,
                            voteCount: movie.voteCount
                        )
                    } catch {
                        return nil
                    }
                }
            }

            // Collect results from all tasks
            for await persistedMovie in group {
                guard let persistedMovie else { return }
                persistedMovies.append(persistedMovie)
            }
        }

        return persistedMovies
    }

    func makeUrl(for path: String?) -> String {
        let baseURL = "https://image.tmdb.org/t/p/"
        let size = "w200"
        let fullURL = baseURL + size + (path ?? "")
        return fullURL
    }

    // Creating data model for isolation and unique ID.
    struct DataModel: Identifiable, Hashable {
        let id = UUID()
        let adult: Bool
        let backdropPath: String
        let genreIDS: [Int]
        let originalLanguage: String
        let originalTitle, overview: String
        let popularity: Double
        let posterPath, releaseDate, title: String
        let video: Bool
        let voteAverage: String
        let voteCount: Int
    }
}

extension Double {
    var round: String {
        String(format: "%.2f", self)
    }
}

typealias DataModel = ListOfMoviesViewModel.DataModel
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
                            VStack(alignment: .center, spacing: 4) {
                                AsyncImageView(
                                    urlString: movie.posterPath,
                                    size: .init(width: 160, height: 240)
                                )
                                infoView(with: movie)
                            }
                            .onAppear {
                                if viewModel.movies.last?.id == movie.id {
                                    viewModel.page += 1
                                }
                            }
                        }

                    }
                }
                .onChange(of: viewModel.page) { oldValue, newValue in
//                    Task { await viewModel.fetchMoviesFromApi() }
                    Task { await viewModel.fetchMovies() }
                }
                .navigationDestination(for: DataModel.self, destination: { movie in
                    Text(movie.title)
                })
            }
            .padding()
            .navigationTitle("Movies")
            if viewModel.state == .loading {
                ProgressView()
            }
        }
    }

    @ViewBuilder
    func infoView(with movie: DataModel) -> some View {
        Text(movie.title)
            .font(.subheadline)
            .fontWeight(.bold)
            .lineLimit(1)
            .foregroundColor(.title)
            .padding(.top, 4)
        HStack(alignment: .bottom, spacing: 4) {
            Image(systemName: "star.fill")
                .foregroundStyle(.yellow)
                .font(.subheadline)
            Text("\(movie.voteAverage)")
                .font(.caption)
                .foregroundColor(.title)
            Text("(\(movie.voteCount))")
                .font(.caption)
                .foregroundColor(.secondary)

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

//
//#Preview {
//
//    lazy var makeContainer: ModelContainer = {
//        do {
//            let fullSchema = Schema([PersistedMovieData.self])
//            let config = ModelConfiguration("initialConfig", schema: fullSchema, isStoredInMemoryOnly: true)
//            let container = try ModelContainer(for: fullSchema, configurations: config)
//            container.mainContext.insert(
//                PersistedMovieData(
//                    id: 0,
//                    adult: true,
//                    backdropPath: "",
//                    genreIDS: [],
//                    originalLanguage: "",
//                    originalTitle: "",
//                    overview: "",
//                    popularity: 0.0,
//                    posterPath: "",
//                    releaseDate: "",
//                    title: "",
//                    video: false,
//                    voteAverage: 0.0,
//                    voteCount: 0
//                )
//            )
//            try container.mainContext.save()
//            return container
//        } catch {
//            fatalError("Failed to configure SwiftData container.")
//        }
//    }()
//
//    return NavigationStack {
//        ListOfMovies(viewModel: .init(interactor: LisOfMoviesInteractor(), container: makeContainer))
//    }
//
//
//}
