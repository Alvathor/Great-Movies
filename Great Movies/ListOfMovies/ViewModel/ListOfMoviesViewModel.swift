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

    /// Represents the current state of data fetching operation.
    var state: OprationState = .notStarted

    /// An array of `DataModel` representing the movies fetched.
    var movies = [DataModel]()

    /// Current page for pagination control. Starts at 1.
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

    /// Initializes the ViewModel with required dependencies.
    ///
    /// - Parameters:
    ///   - interactor: An object conforming to `LisOfMoviesInteracting` for data fetching.
    ///   - factory: An object conforming to `MovieDataFactoring` for data model transformation.
    ///   - container: A `ModelContainer` for offline data management.
    init(interactor: LisOfMoviesInteracting, factory: MovieDataFactoring, container: ModelContainer) {
        self.interactor = interactor
        self.factory = factory
        self.container = container

        persistedCount = fetchCount()
    }

    /// Initiates the process to fetch movies from the API or storage based on the current pagination and storage status.
    func fetchMovies() async {
        if page <= totalOFpersistedPage {
            await fetchMoviesFromStorage()
        } else {
            await fetchMoviesFromApi()
        }

    }

    /// Fetches the total count of persisted movies from local storage.
       /// - Returns: The count of movies available in local storage.
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

    /// Fetches movies from the remote API and updates the ViewModel state accordingly.
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

    /// Fetches movies from local storage and updates the ViewModel state accordingly.
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

    /// Saves fetched movies into local storage for offline access.
    /// - Parameter movies: An array of `PersistedMovieData` to be saved.
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

    /// Creates and returns a `MovieDetailViewModel` for the selected movie.
    /// - Parameter movie: A `DataModel` object representing the selected movie.
    /// - Returns: A configured `MovieDetailViewModel`.
    func makeMovieDetailViewModel(with movie: DataModel) -> MovieDetailViewModel {
        .init(
            interactor: MovieDetailInteractor(),
            factory: factory,
            container: container,
            movie: movie
        )
    }

    /// A data model representing essential information of a movie for UI presentation.
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

