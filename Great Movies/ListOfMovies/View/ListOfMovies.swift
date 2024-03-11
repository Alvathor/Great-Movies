//
//  ContentView.swift
//  Great Movies
//
//  Created by Juliano Alvarenga on 08/03/24.
//


import SwiftUI
import Observation
import SwiftData

typealias DataModel = ListOfMoviesViewModel.DataModel
struct ListOfMovies: View {
    @Bindable var viewModel: ListOfMoviesViewModel
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(
                    columns:[
                        GridItem(.flexible(), spacing: -4),
                        GridItem(.flexible())
                    ],spacing: 16
                ) {
                    ForEach(viewModel.movies) { movie in
                        NavigationLink(value: movie) {
                            VStack(alignment: .center, spacing: 4) {
                                AsyncCachedImageView(
                                    urlString: movie.posterPath,
                                    data: movie.posterData,
                                    size: .init(width: 160, height: 240),
                                    aspect: .fill
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                infoView(with: movie)
                                    .frame(maxWidth: 200)
                            }
                            .onAppear {
                                if viewModel.movies.last?.id == movie.id {
                                    viewModel.page += 1
                                }
                            }
                        }
                    }
                }
                .onChange(of: viewModel.page) { oldValue, newValue in
                    Task { await viewModel.fetchMovies() }
                }
                .navigationDestination(for: DataModel.self, destination: { movie in
                    MovieDetailView(
                        viewModel: viewModel.makeMovieDetailViewModel(with: movie)
                    )
                    .ignoresSafeArea(.container, edges: .top)
                })
            }
            .padding()
            .navigationTitle("Movies")

            offLineView

            progressOrRetryView
        }
    }

}


// MARK: View Components
extension ListOfMovies {

    @ViewBuilder
    private var offLineView: some View {
        if viewModel.isOffline {
            VStack {
                Image(systemName: "wifi.slash")
                Text("No connection")
                    .font(.caption)
            }
            .foregroundStyle(.white)
            .fontWeight(.bold)
            .padding()
            .frame(maxWidth: .infinity)
            .background(.red)
            .transition(.asymmetric(
                insertion: .move(edge: .bottom),
                removal: .move(edge: .bottom)
            ))
        }
    }

    @ViewBuilder
    private var progressOrRetryView: some View {
        if viewModel.state == .loading {
            ProgressView()
        } else if viewModel.state == .failure {
            Button {
                Task { await viewModel.fetchMovies() }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise.circle.fill")
                    Text("Retry")
                }
            }
        }
    }

    @ViewBuilder
    func infoView(with movie: DataModel) -> some View {
        Text(movie.title)
            .font(.subheadline)
            .fontWeight(.bold)
            .lineLimit(1)
            .foregroundColor(.title)
            .padding(.top, 4)
        HStack(alignment: .bottom, spacing: 4) {
            Image(systemName: "star.fill")
                .foregroundStyle(.yellow)
                .font(.subheadline)
            Text("\(movie.voteAverage)")
                .font(.caption)
                .foregroundColor(.title)
            Text("(\(movie.voteCount))")
                .font(.caption)
                .foregroundColor(.secondary)

        }
    }

}


#Preview {

    lazy var makeContainer: ModelContainer = {
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

    return NavigationStack {
        ListOfMovies(viewModel: .init(interactor: LisOfMoviesInteractor(), factory: MovieDataFactory(), container: makeContainer))
    }


}
