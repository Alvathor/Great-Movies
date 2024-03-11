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
    var movieDetailsState: OprationState = .notStarted
    var relatedMoviesState: OprationState = .notStarted

    var movie: DataModel
    var relatedMovies = [DataModel]()

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
