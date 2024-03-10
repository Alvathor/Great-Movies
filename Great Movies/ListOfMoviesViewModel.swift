//
//  ListOfMoviesViewModel.swift
//  Great Movies
//
//  Created by Juliano Alvarenga on 10/03/24.
//

import Foundation
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
    
    private var totalOFpersistedPage = 0
    private var persistedCount = 0 { didSet {
        totalOFpersistedPage = persistedCount / itemPerPage
    }}
    private let itemPerPage = 20

    private let interactor: LisOfMoviesInteracting

    /// Injecting `ModelContainer` because it's sendable and we can create `modelContext`
    /// for background havy tasks
    private let container: ModelContainer

    init(interactor: LisOfMoviesInteracting, container: ModelContainer) {
        self.interactor = interactor
        self.container = container

        persistedCount = fetchCount()


        Task { await fetchMovies() }



        let chartData = [String: Double]()

        for movie in movies {

        }






        for movie in movies  {
            let actionMovies = movie.genreIDS.map { $0 == 1 }

        }


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

    private func fetchMoviesFromApi() async {
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
            let pageOffset = min(persistedCount, movies.count)
            descriptor.fetchOffset = pageOffset

            let persistedMovies = try context.fetch(descriptor)
            let fetchedMovies = await makeDataModel(with: persistedMovies)
            movies.append(contentsOf: fetchedMovies)
            page = movies.count / itemPerPage
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
        await withTaskGroup(of: PersistedMovieData?.self) { group in
            for movie in movies {
                group.addTask { [weak self] in
                    let backdropPathData = await self?.fetchData(for: self?.makeUrl(for: movie.backdropPath))
                    let posterPathData = await self?.fetchData(for: self?.makeUrl(for: movie.posterPath))

                    // Create and return a PersistedMovieData object
                    return PersistedMovieData(
                        id: movie.id,
                        adult: movie.adult,
                        backdropData: backdropPathData,
                        genreIDS: movie.genreIDS,
                        originalLanguage: movie.originalLanguage,
                        originalTitle: movie.title,
                        overview: movie.overview,
                        popularity: movie.popularity,
                        posterData: posterPathData,
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
                backdropData: nil,
                genreIDS: $0.genreIDS,
                originalLanguage: $0.originalLanguage,
                originalTitle: $0.originalLanguage,
                overview: $0.overview,
                popularity: $0.popularity,
                posterPath: makeUrl(for: $0.posterPath),
                posterData: nil,
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
                group.addTask {
                    return DataModel(
                        adult: movie.adult,
                        backdropPath: "",
                        backdropData: movie.backdropData,
                        genreIDS: movie.genreIDS,
                        originalLanguage: movie.originalLanguage,
                        originalTitle: movie.title,
                        overview: movie.overview,
                        popularity: movie.popularity,
                        posterPath: "",
                        posterData: movie.posterData,
                        releaseDate: movie.releaseDate,
                        title: movie.title,
                        video: movie.video,
                        voteAverage: movie.voteAverage.round,
                        voteCount: movie.voteCount
                    )
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

    private func makeUrl(for path: String?) -> String {
        let baseURL = "https://image.tmdb.org/t/p/"
        let size = "w500"
        let fullURL = baseURL + size + (path ?? "")
        return fullURL
    }

    // Creating data model for isolation and unique ID.
    struct DataModel: Identifiable, Hashable {
        let id = UUID()
        let adult: Bool
        let backdropPath: String
        let backdropData: Data?
        let genreIDS: [Int]
        let originalLanguage: String
        let originalTitle, overview: String
        let popularity: Double
        let posterPath: String
        let posterData: Data?
        let releaseDate, title: String
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
