//
//  ListOfMoviesViewModelTests.swift
//  Great MoviesTests
//
//  Created by Juliano Alvarenga on 11/03/24.
//

import XCTest
@testable import Great_Movies
import SwiftData

final class ListOfMoviesViewModelTests: XCTestCase {

    let interactor = MockLisOfMoviesInteractor(state: .success)
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

    func test_initialState_listOfMoviesShouldBeEmpty() async {
        // Arrange
        let sut = await ListOfMoviesViewModel(interactor: interactor, factory: factory, container: container)
        
        // Assert
        XCTAssertEqual(sut.movies.count, 0)
    }

    func test_fetchItemFromApi_succed() async {
        // Arrange
        let sut = await ListOfMoviesViewModel(interactor: interactor, factory: factory, container: container)
        interactor.makeMockedMovies(moviesCount: 20)
        let expectation = expectation(description: "Number of movies in SUT should match the mock")

        sut.page = 1
        await sut.fetchMoviesFromApi()
        expectation.fulfill()

        let numberOfItems = sut.movies.count

        await fulfillment(of: [expectation], timeout: 1)
        XCTAssertEqual(numberOfItems, interactor.mockedData.movies.count)
    }



    func test_savingItems_shouldSucced() async {
        let sut = await ListOfMoviesViewModel(interactor: interactor, factory: factory, container: container)
        interactor.makeMockedMovies(moviesCount: 20)

        await sut.save(movies: factory.makePersistedMovieData(with: interactor.mockedData.movies) )

        let finalStoragedCount = try! await ModelContext(container).fetchCount(FetchDescriptor<PersistedMovieData>())

        XCTAssertTrue(finalStoragedCount == interactor.mockedData.movies.count, "Initial Storage should be zero.")
    }

    func test_fetchItemsLocally_shouldSucced() async {
        // Arrange
        let sut = await ListOfMoviesViewModel(interactor: interactor, factory: factory, container: container)
        interactor.makeMockedMovies(moviesCount: 20)
        await sut.save(movies: factory.makePersistedMovieData(with: interactor.mockedData.movies) )

        // Act
        // Fetching movies from local storage
        await sut.fetchMoviesFromStorage()
        // Returning the number of entities stored in the container
        let finalStoragedCount = try! await ModelContext(container).fetchCount(FetchDescriptor<PersistedMovieData>())
        // Assert
        XCTAssertTrue(finalStoragedCount == interactor.mockedData.movies.count, "Initial Storage should be equals to the fetched items from api.")
    }

    func test_makeDetailViewModel_shouldSucced() async {
        let sut = await ListOfMoviesViewModel(interactor: interactor, factory: factory, container: container)
        await sut.fetchMoviesFromApi()
        let movie = sut.movies[0]
        let mockedMovieDetailViewModel = await MovieDetailViewModel(interactor: MovieDetailInteractor(), factory: factory, container: container, movie: movie)
        let movideDetailViewModel = sut.makeMovieDetailViewModel(with: movie)
        
        XCTAssertEqual(movideDetailViewModel.movie.id, mockedMovieDetailViewModel.movie.id)
    }

}



// MARK: Mock
class MockLisOfMoviesInteractor: LisOfMoviesInteracting {
    var mockedData: MovieData =  .init(
        page: 1,
        movies: [],
        totalPages: 3,
        totalResults: 60
    )


    enum Errors: Error {
        case failToFetchMovies
        case invalidURL
    }

    private let state: OprationState
    init(state: OprationState) {
        self.state = state
    }

    func makeMockedMovies(moviesCount: Int) {
        mockedData.movies.removeAll()
        (0..<moviesCount).forEach { index in
            mockedData.movies.append(
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

    func fetchMovies(in page: Int) async throws -> MovieData {
        return mockedData
    }

}
