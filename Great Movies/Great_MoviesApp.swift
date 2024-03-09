//
//  Great_MoviesApp.swift
//  Great Movies
//
//  Created by Juliano Alvarenga on 08/03/24.
//

import SwiftUI
import SwiftData

@main
struct Great_MoviesApp: App {

    var container: ModelContainer

    init() {
        do {
            let fullSchema = Schema([PersistedMovieData.self])
            let config = ModelConfiguration("initialConfig", schema: fullSchema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: fullSchema, configurations: config)
        } catch {
            fatalError("Failed to configure SwiftData container.")
        }
    }

    var body: some Scene {

        @State var viewModel = ListOfMoviesViewModel(interactor: LisOfMoviesInteractor(), container: container)

        WindowGroup {
            ListOfMovies(viewModel: viewModel)
        }
        .modelContainer(container)
    }
}
