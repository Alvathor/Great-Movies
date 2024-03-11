//
//  MovieDetailViewModel.swift
//  Great Movies
//
//  Created by Juliano Alvarenga on 10/03/24.
//

import Foundation
import SwiftData

@Observable
final class MovieDetailViewModel: Sendable {

    private let interactor: MovieDetailInteracting
    private let factory: MovieDataFactoring
    private let container: ModelContainer

    /// The state of fetching movie details operation.
    var movieDetailsState: OprationState = .notStarted

    /// The state of fetching related movies operation.
    var relatedMoviesState: OprationState = .notStarted

    /// The movie `DataModel` for which details are being presented.
    var movie: DataModel

    /// An array of `DataModel` representing related movies.
    var relatedMovies = [DataModel]()

    /// Initializes the ViewModel with required dependencies and the movie data model.
    ///
    /// - Parameters:
    ///   - interactor: An object conforming to `MovieDetailInteracting` for fetching movie details and related movies.
    ///   - factory: An object conforming to `MovieDataFactoring` for data model transformation.
    ///   - container: A `ModelContainer` for managing model contexts, enabling background data processing.
    ///   - movie: The `DataModel` object representing the movie for which details are being presented.
    init(
        interactor: MovieDetailInteracting,
        factory: MovieDataFactoring,
        container: ModelContainer,
        movie: DataModel
    ) {
        self.interactor = interactor
        self.factory = factory
        self.container = container
        self.movie = movie
    }

    /// Fetches the detailed information of the movie and updates the ViewModel state accordingly.
    /// Only fetches details if they have not already been loaded.
    func fetchMovieDetail() async {
        guard movie.genres.isEmpty else { return }
        movieDetailsState = .loading
        do {
            let movieDetail = try await interactor.fetchMovieDetail(movieId: movie.movieId)
            await MainActor.run {
                movie.genres.append(contentsOf: movieDetail.genres.map(\.name))
                movieDetailsState = .success
            }
            await fetchRelatedMovies()
            await saveMovie()
        } catch {
            debugPrint(error)
            await MainActor.run {
                movieDetailsState = .failure
            }
        }
    }

    /// Fetches movies related to the current movie and updates the ViewModel state accordingly.
    func fetchRelatedMovies() async {
        relatedMoviesState = .loading
        do {
            let movieData = try await interactor.fetchRelatedMovies(movieId: movie.movieId)
            await MainActor.run {
                relatedMovies = factory.makeDataModel(with: movieData.movies)
                relatedMoviesState = .success
            }
        } catch  {
            debugPrint(error)
            await MainActor.run {
                relatedMoviesState = .failure
            }
        }
    }

    /// Saves the current movie details to local storage for offline access.
    func saveMovie() async {
        do {
            let context = ModelContext(container)
            context.insert(factory.makePersistedMovieData(with: movie))
            try context.save()
        } catch {
            debugPrint(error)
        }
    }
}
