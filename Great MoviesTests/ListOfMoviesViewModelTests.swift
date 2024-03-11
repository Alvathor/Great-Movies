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

    private var sut: ListOfMoviesViewModel!
    @MainActor
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let interactor = LisOfMoviesInteractor()
        let factory = MovieDataFactory()
        lazy var container: ModelContainer = {
            do {
                let fullSchema = Schema([PersistedMovieData.self])
                let config = ModelConfiguration("initialConfig", schema: fullSchema, isStoredInMemoryOnly: true)
                let container = try ModelContainer(for: fullSchema, configurations: config)
                container.mainContext.insert(
                    PersistedMovieData(
                        movieId: 0,
                        backdropData: nil,
                        genres: [],
                        overview: "",
                        popularity: 0.0,
                        posterData: nil,
                        releaseDate: "",
                        title: "",
                        voteAverage: 0.0,
                        voteCount: 0
                    )
                )
                try container.mainContext.save()
                return container
            } catch {
                fatalError("Failed to configure SwiftData container.")
            }
        }()
        let sut = ListOfMoviesViewModel(interactor: interactor, factory: factory, container: container)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_() async {
        await sut.fetchMovies()


    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
