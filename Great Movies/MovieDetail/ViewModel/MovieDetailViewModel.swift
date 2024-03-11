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
    private let movieDataFactory: MovieDataFactoring
    private let container: ModelContainer
    var state: OprationState = .notStarted

    var movie: DataModel
    var movieDetail: MovieDetail?

    init(
        interactor: MovieDetailInteracting,
        movieDataFactory: MovieDataFactoring,
        container: ModelContainer,
        movie: DataModel
    ) {
        self.interactor = interactor
        self.movieDataFactory = movieDataFactory
        self.container = container
        self.movie = movie

        Task { await fetchMovieDetail() }
    }

    private func fetchMovieDetail() async {
        guard movie.genres.isEmpty else { return }
        state = .loading
        do {
            let movieDetail = try await interactor.fetchMovieDetail(movieId: movie.movieId)
            await MainActor.run {
                self.movieDetail = movieDetail
                movie.genres.append(contentsOf: movieDetail.genres.map(\.name))
                state = .success
            }
            await saveMovie()
        } catch {
            debugPrint(error)
            await MainActor.run {
                state = .failure
            }
        }
    }

    private func saveMovie() async {
        do {
            let context = ModelContext(container)
            context.insert(movieDataFactory.makePersistedMovieData(with: movie))
            try context.save()
        } catch {
            debugPrint(error)
        }
    }
}
