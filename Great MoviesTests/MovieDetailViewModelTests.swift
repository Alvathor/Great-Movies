//
//  MovieDetailViewModelTests.swift
//  Great MoviesTests
//
//  Created by Juliano Alvarenga on 11/03/24.
//

import XCTest
@testable import Great_Movies
import SwiftData

final class MovieDetailViewModelTests: XCTestCase {

    let interactor = MoclkMovieDetailInteractor()
    let factory = MovieDataFactory()
    @MainActor
    lazy var container: ModelContainer = {
        do {
            let fullSchema = Schema([PersistedMovieData.self])
            let config = ModelConfiguration("initialConfig", schema: fullSchema, isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: fullSchema, configurations: config)
            return container
        } catch {
            fatalError("Failed to configure SwiftData container.")
        }
    }()


    func test_fetchMovieDetail_shouldSucced() async {
        interactor.makeMockedMovies(moviesCount: 20)
        let movie = interactor.mockedMoviedData
        let sut = await MovieDetailViewModel(interactor: interactor, factory: factory, container: container, movie: movie)
        sut.fe
        await sut.fetchMovieDetail()

        XCTAssertEqual(sut.movieDetailsState, .success, "Movie detail should be successfully fetched ")
        XCTAssertEqual(sut.movie.genres.isEmpty, false, "Movie should contains details ")
    }

    func test_fetchMovieRelated_shouldSucced() async {
        interactor.makeMockedMovies(moviesCount: 20)
        let movie = interactor.mockedMoviedData
        let sut = await MovieDetailViewModel(interactor: interactor, factory: factory, container: container, movie: movie)

        await sut.fetchRelatedMovies()

        XCTAssertEqual(sut.relatedMoviesState, .success, "Related movies should be successfully fetched ")
        XCTAssertEqual(sut.relatedMovies.isEmpty, false, "Related movies should not be empty ")
    }

}


final class MoclkMovieDetailInteractor: MovieDetailInteracting, Sendable {

    var relatedMoviesMockedData: MovieData =  .init(
        page: 1,
        movies: [],
        totalPages: 3,
        totalResults: 60
    )

    var mockedMoviedData: DataModel = .init(
        movieId: 1,
        backdropPath: "",
        backdropData: nil,
        genres: [],
        overview: "Overview of the Movie",
        popularity: 0.0,
        posterPath: "",
        posterData: nil,
        releaseDate: "",
        title: "Movie Titla 1",
        voteAverage: "8.0",
        voteCount: 100
    )

    func makeMockedMovies(moviesCount: Int) {
        relatedMoviesMockedData.movies.removeAll()
        (0..<moviesCount).forEach { index in
            relatedMoviesMockedData.movies.append(
                .init(
                    backdropPath: "/backdropPath1.jpg",
                    id: 101,
                    overview: "Overview of Movie \(index)",
                    popularity: 100.1,
                    posterPath: "/posterPath1.jpg",
                    releaseDate: "2024-01-01",
                    title: "Movie Title \(index)",
                    voteAverage: 7.1,
                    voteCount: 100
                )
            )
        }
    }

    func fetchMovieDetail(movieId: Int) async throws -> Great_Movies.MovieDetail {
        .init(genres: [.init(id: 0, name: "Action"), .init(id: 1, name: "Crime")])
    }
    
    func fetchRelatedMovies(movieId: Int) async throws -> Great_Movies.MovieData {
        relatedMoviesMockedData
    }


}
