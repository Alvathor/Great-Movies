//
//  MovieDetailView.swift
//  Great Movies
//
//  Created by Juliano Alvarenga on 09/03/24.
//

import SwiftUI
import SwiftData
import Charts

struct MovieDetailView: View {
    @Bindable var viewModel: MovieDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var offSet: CGPoint = .zero
    @State private var progress: CGFloat = 1
    var body: some View {
        GeometryReader { geo in
            OffsetObservingScrollView(offset: $offSet) {
                    VStack(spacing: 16) {
                        makeBackdropView(with: geo)
                        VStack(spacing: 16) {
                            HStack {
                                posterView
                                headerInfoView
                                Spacer()
                            }
                            // Overview
                            Text(viewModel.movie.overview)
                                .multilineTextAlignment(.leading)
                                .padding(.bottom)
                            Divider()
                            // Chart
                            Text("Genres")
                                .padding(.top)
                                .font(.title2)
                                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                            makePieChartView(with: geo)
                            Divider()
                                .padding()
                            Text("Related Movies")
                                .padding(.top)
                                .font(.title2)
                                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                .padding(.bottom)

                            ScrollView(.horizontal) {
                                LazyHGrid(
                                    rows:[
                                        GridItem(.flexible())
                                    ],spacing: 8
                                ) {
                                    ForEach(viewModel.relatedMovies) { movie in
                                        NavigationLink(value: movie) {
                                            VStack(alignment: .center, spacing: 4) {
                                                AsyncCachedImageView(
                                                    urlString: movie.posterPath,
                                                    data: movie.posterData,
                                                    size: .init(width: 200, height: 250),
                                                    aspect: .fill
                                                )
                                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                                infoView(with: movie)
                                                    .frame(maxWidth: 200)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20.0))
                        .padding()
                        .offset(y: -100)
                    }
                    .frame(width: geo.size.width)
                    .onChange(of: offSet) { oldValue, newValue in
                        progress = 1 - offSet.y * 0.001
                    }
            }
            .task { await viewModel.fetchMovieDetail() }
        }
    }
}

// MARK: View Components
extension MovieDetailView {

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

    @ViewBuilder
    private func makeBackdropView(with geo: GeometryProxy) -> some View {
        ZStack {
            AsyncCachedImageView(
                urlString: viewModel.movie.backdropPath,
                data: viewModel.movie.backdropData,
                size: .init(width: geo.size.width, height: geo.size.width),
                aspect: .fill
            )
            .scaleEffect(offSet.y < 0 ? progress : 1)
            .frame(height: geo.size.width)
            .offset(y: offSet.y)
            Rectangle()
                .foregroundStyle(
                    LinearGradient(colors: [.clear,.black, .blackAndWhite], startPoint: .top, endPoint: .bottom)
                )
                .frame(width: geo.size.width, height: geo.size.width)
                .offset(y: geo.size.width / 2 + offSet.y)
        }
    }
    @ViewBuilder
    private var posterView: some View {
        AsyncCachedImageView(
            urlString: viewModel.movie.posterPath,
            data: viewModel.movie.posterData,
            size: .init(
                width: 100,
                height: 100
            ), aspect: .fill
        )
        .clipShape(Circle())
    }

    private var headerInfoView: some View {
        VStack(alignment: .leading) {
            Text(viewModel.movie.title)
                .font(.title)
                .fontWeight(.bold)
            HStack(alignment: .bottom, spacing: 4) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.subheadline)
                }
                Text("\(viewModel.movie.voteAverage)")
                    .font(.caption)
                    .foregroundColor(.title)
                Text("(\(viewModel.movie.voteCount))")
                    .font(.caption)
                    .foregroundColor(.secondary)

            }
            Text("Date release: \(viewModel.movie.releaseDate)")
                .foregroundStyle(.secondary)
                .font(.footnote)
        }
    }

    @ViewBuilder
    func  makePieChartView(with geo: GeometryProxy) -> some View {
        if viewModel.movieDetailsState == .loading {
            ProgressView()
                .frame(width: geo.size.width / 2, height: geo.size.width / 2)
        } else {
            Chart(viewModel.movie.genres, id: \.self) { genre in
                SectorMark(
                    angle: .value("Genre", genre.count),
                    innerRadius: .ratio(0),
                    angularInset: 3.0
                )
                .foregroundStyle(by: .value("Type", genre))
                .annotation(position: .overlay, alignment: .center) {
                    Text(genre)
                        .font(.caption)
                }

            }
            .chartLegend(.hidden)
            .frame(width: geo.size.width / 2, height: geo.size.width / 2)
        }
    }

}

let json = """
{
        "adult": false,
        "backdrop_path": "/4woSOUD0equAYzvwhWBHIJDCM88.jpg",
        "genre_ids": [
            28,
            27,
            53
        ],
        "id": 1096197,
        "original_language": "en",
        "original_title": "No Way Up",
        "overview": "Characters from different backgrounds are thrown together when the plane they're travelling on crashes into the Pacific Ocean. A nightmare fight for survival ensues with the air supply running out and dangers creeping in from all sides.",
        "popularity": 1480.125,
        "poster_path": "/hu40Uxp9WtpL34jv3zyWLb5zEVY.jpg",
        "release_date": "2024-01-18",
        "title": "No Way Up",
        "video": false,
        "vote_average": 5.776,
        "vote_count": 127
    }
""".data(using: .utf8)

#Preview {
    
    lazy var movie: Movie = {
        try! JSONDecoder().decode(Movie.self, from: json!)
    }()

    func makeUrl(for path: String?) -> String {
        let baseURL = "https://image.tmdb.org/t/p/"
        let size = "w500"
        let fullURL = baseURL + size + (path ?? "")
        return fullURL
    }

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
    return NavigationStack{

        MovieDetailView(
            viewModel: .init(
                interactor: MovieDetailInteractor(),
                factory: MovieDataFactory(),
                container: makeContainer,
                movie:.init(
                    movieId: 100,
                    backdropPath: makeUrl(for: movie.backdropPath),
                    backdropData: nil,
                    genres: [],
                    overview: movie.overview,
                    popularity: movie.popularity,
                    posterPath: movie.posterPath ?? "",
                    posterData: nil,
                    releaseDate: movie.releaseDate,
                    title: movie.title,
                    voteAverage: movie.voteAverage.round,
                    voteCount: movie.voteCount
                )
            )
        )
        .ignoresSafeArea(.container, edges: .top)
    }

}
