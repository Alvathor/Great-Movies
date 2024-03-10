//
//  MovieDetailView.swift
//  Great Movies
//
//  Created by Juliano Alvarenga on 09/03/24.
//

import SwiftUI
import SwiftData

protocol MovieDetailInteracting: Sendable {
    func fetchMovieDetail(movieId: Int) async throws -> MovieDetail
}

final class MovieDetailInteractor: MovieDetailInteracting {

    enum Errors: Error {
        case failToFetchMovieDetail
        case invalidURL
    }

    func fetchMovieDetail(movieId: Int) async throws -> MovieDetail{
        var components = URLComponents(string: "https://api.themoviedb.org/3/movie/\(movieId)")
        let queryItems = [
            URLQueryItem(name: "language", value: "en-US"),
            URLQueryItem(name: "api_key", value: "faecb8622454db0e4a00b38aab3a4347")
        ]
        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw Errors.invalidURL
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let movie = try JSONDecoder().decode(MovieDetail.self, from: data)
            return movie
        } catch {
            debugPrint(error)            
            throw Errors.failToFetchMovieDetail
        }
    }

}

@Observable
final class MovieDetailViewModel: Sendable {

    private let interactor: MovieDetailInteracting
    private let movieDataFactory: MovieDataFactoring
    private let container: ModelContainer
    var state: OprationState = .notStarted

    var movie: DataModel

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
        state = .loading
        do {
            let movieDetail = try await interactor.fetchMovieDetail(movieId: movie.movieId)
            movie.genres.append(contentsOf: movieDetail.genres.map(\.name))            
            await saveMovie()
        } catch {

        }
    }

    private func saveMovie() async {
        do {
            let context = ModelContext(container)
            context.insert(movieDataFactory.makePersistedMovieData(with: movie))
            try context.save()
        } catch {

        }
    }
}

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
                        Chart(viewModel.movie.genres, id: \.self) { genre in
                            SectorMark(
                                angle: .value("Genre", genre.count), innerRadius: .ratio(0.6)
                            )
                            .foregroundStyle(by: .value("Type", genre))
                        }.frame(width: geo.size.width / 2, height: geo.size.width / 2)
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
                    adult: true,
                    backdropData: nil,
                    genres: [],
                    originalLanguage: "",
                    originalTitle: "",
                    overview: "",
                    popularity: 0.0,
                    posterData: nil,
                    releaseDate: "",
                    title: "",
                    video: false,
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
                    adult: false,
                    backdropPath: makeUrl(for: movie.backdropPath),
                    backdropData: nil,
                    genres: [],
                    originalLanguage: movie.originalLanguage,
                    originalTitle: movie.originalTitle,
                    overview: movie.overview,
                    popularity: movie.popularity,
                    posterPath: movie.posterPath,
                    posterData: nil,
                    releaseDate: movie.releaseDate,
                    title: movie.title,
                    video: movie.video,
                    voteAverage: movie.voteAverage.round,
                    voteCount: movie.voteCount
                )
            )
        )
        .ignoresSafeArea(.container, edges: .top)
    }

}


struct PositionObservingView<Content: View>: View {
    var coordinateSpace: CoordinateSpace
    @Binding var position: CGPoint
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .background(GeometryReader { geometry in
                Color.clear.preference(
                    key: PreferenceKey.self,
                    value: geometry.frame(in: coordinateSpace).origin
                )
            })
            .onPreferenceChange(PreferenceKey.self) { position in
                self.position = position
            }
    }
}

private extension PositionObservingView {
    struct PreferenceKey: SwiftUI.PreferenceKey {
        static var defaultValue: CGPoint { .zero }

        static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
            // No-op
        }
    }
}

struct OffsetObservingScrollView<Content: View>: View {
    var axes: Axis.Set = [.vertical]
    var showsIndicators = true
    @Binding var offset: CGPoint
    @ViewBuilder var content: () -> Content

    private let coordinateSpaceName = UUID()

    var body: some View {
        ScrollView(axes, showsIndicators: showsIndicators) {
            PositionObservingView(
                coordinateSpace: .named(coordinateSpaceName),
                position: Binding(
                    get: { offset },
                    set: { newOffset in
                        offset = CGPoint(
                            x: -newOffset.x,
                            y: -newOffset.y
                        )
                    }
                ),
                content: content
            )
        }
        .coordinateSpace(name: coordinateSpaceName)
    }
}


import SwiftUI
import Charts

struct GenrePieChartView: View {
    @Binding var genres: [String] // This would come from the movie's genre data

    var body: some View {

        PieChart(genres: genres)
            .frame(width: 200, height: 200)
            .padding()
    }
}

struct PieChart: View {
    var genres: [String]
    var colors: [Color] = [.red, .green, .blue, .orange, .purple, .yellow] // Add more colors if necessary

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let radius = min(width, height) / 2
            let center = CGPoint(x: width / 2, y: height / 2)

            Path { path in
                for (index, _) in genres.enumerated() {
                    let startAngle = Angle(degrees: Double(index) * (360 / Double(genres.count)))
                    let endAngle = Angle(degrees: Double(index + 1) * (360 / Double(genres.count)))

                    path.move(to: center)
                    path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
                }
            }
            .fill(self.colors[0 % self.colors.count]) // Use modulo to cycle through colors if there are more genres than colors
        }
    }
}
