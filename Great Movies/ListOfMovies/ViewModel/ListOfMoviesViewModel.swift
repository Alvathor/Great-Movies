//
//  ListOfMoviesViewModel.swift
//  Great Movies
//
//  Created by Juliano Alvarenga on 10/03/24.
//

import Foundation
import SwiftData
import Network

enum OprationState: Equatable {
    case success
    case failure
    case loading
    case notStarted
}

@Observable
final class ListOfMoviesViewModel: Sendable {

    var state: OprationState = .notStarted
    var movies = [DataModel]()
    var page = 1
    
    private var totalOFpersistedPage = 0
    private var persistedCount = 0 { didSet {
        totalOFpersistedPage = persistedCount / itemPerPage
    }}
    private let itemPerPage = 20

    private let interactor: LisOfMoviesInteracting
    private let factory: MovieDataFactoring

    /// Injecting `ModelContainer` because it's sendable and we can create `modelContext`
    /// for background havy tasks
    private let container: ModelContainer    

    init(interactor: LisOfMoviesInteracting, factory: MovieDataFactoring, container: ModelContainer) {
        self.interactor = interactor
        self.factory = factory
        self.container = container

        persistedCount = fetchCount()
    }

    func fetchMovies() async {
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
            print("Fail when fetching count from descriptor \(error.localizedDescription)")
            return 0
        }
    }

    internal func fetchMoviesFromApi() async {
        state = .loading
        do {
            let items = try await interactor.fetchMovies(in: page)
            await MainActor.run {
                state = .success
                movies.append(contentsOf: factory.makeDataModel(with: items.movies))                
            }
            await save(movies: factory.makePersistedMovieData(with: items.movies))
        } catch {
            await MainActor.run {
                state = .failure // handle UI failure
            }
        }
    }

    internal func fetchMoviesFromStorage() async {
        let context = ModelContext(container)
        var descriptor = FetchDescriptor<PersistedMovieData>()
        descriptor.fetchLimit = itemPerPage
        do {
            let pageOffset = min(persistedCount, movies.count)
            descriptor.fetchOffset = pageOffset

            let persistedMovies = try context.fetch(descriptor)
            let fetchedMovies = await factory.makeDataModel(with: persistedMovies)
            movies.append(contentsOf: fetchedMovies)
            page = movies.count / itemPerPage
        } catch {
            await MainActor.run {
                state = .failure // handle UI failure
            }
            debugPrint("Fail when fetching movies from container \(error.localizedDescription)")
        }
    }

    internal func save(movies: [PersistedMovieData]) {
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

    func makeMovieDetailViewModel(with movie: DataModel) -> MovieDetailViewModel {
        .init(
            interactor: MovieDetailInteractor(),
            factory: factory,
            container: container,
            movie: movie
        )
    }

    // Creating data model for isolation and unique ID.
    struct DataModel: Identifiable, Hashable {
        let id = UUID()
        let movieId: Int
        let backdropPath: String
        let backdropData: Data?
        var genres: [String]
        let overview: String
        let popularity: Double
        let posterPath: String
        let posterData: Data?
        let releaseDate, title: String        
        let voteAverage: String
        let voteCount: Int
    }
}

