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
                    if let data = viewModel.movie.backdropData,
                       let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .scaleEffect(offSet.y < 0 ? progress : 1)
                            .frame(height: geo.size.width)
                            .offset(y: offSet.y)
                    } else {
                        AsyncImage(url: URL(string: viewModel.movie.backdropPath)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .scaleEffect(offSet.y < 0 ? progress : 1)
                                .frame(height: geo.size.width)
                                .offset(y: offSet.y)

                        } placeholder: {
                            ProgressView()
                                .frame(height: geo.size.width)
                        }
                    }
                    VStack(spacing: 16) {
                        HStack {
                            if let data = viewModel.movie.posterData,
                               let image = UIImage(data: data) {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .clipped()
                            } else {
                                AsyncImage(url: URL(string: viewModel.movie.posterPath)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                        .clipped()

                                } placeholder: {
                                    ///
                                }
                            }
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
                            Spacer()
                        }
                        Text(viewModel.movie.overview)
                            .multilineTextAlignment(.leading)
                            .padding(.bottom)
                        Divider()
                        Text("Genres")
                            .padding(.top)
                            .font(.title2)
                            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                        if viewModel.state == .loading {
                            ProgressView()
                                .frame(width: geo.size.width / 2, height: geo.size.width / 2)
                        } else {
                            makePieChartView(with: geo)
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
        }
    }
}

// MARK: View Components
extension MovieDetailView {

    func  makePieChartView(with geo: GeometryProxy) -> some View {
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
                movieDataFactory: MovieDataFactory(),
                container: makeContainer,
                movie:.init(
                    movieId: 100,
                    backdropPath: makeUrl(for: movie.backdropPath),
                    backdropData: nil,
                    genres: [],
                    overview: movie.overview,
                    popularity: movie.popularity,
                    posterPath: movie.posterPath,
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
