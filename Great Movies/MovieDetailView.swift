//
//  MovieDetailView.swift
//  Great Movies
//
//  Created by Juliano Alvarenga on 09/03/24.
//

import SwiftUI


struct MovieDetailView: View {
    var movie: DataModel
    @Environment(\.dismiss) private var dismiss
    @State var offSet: CGPoint = .zero
    @State var progress: CGFloat = 1
    var body: some View {
        GeometryReader { geo in
            OffsetObservingScrollView(offset: $offSet) {
                VStack(spacing: 16) {
                    if let data = movie.backdropData,
                       let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .scaleEffect(offSet.y < 0 ? progress : 1)
                            .frame(height: geo.size.width)
                            .offset(y: offSet.y)
                    } else {
                        AsyncImage(url: URL(string: movie.backdropPath)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .scaleEffect(offSet.y < 0 ? progress : 1)
                                .frame(height: geo.size.width)
                                .offset(y: offSet.y)

                        } placeholder: {
                            ///
                        }
                    }
                    VStack(spacing: 16) {
                        HStack {
                            AsyncImage(url: URL(string: movie.backdropPath)) { image in
                                image

                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .clipped()

                            } placeholder: {
                                ///
                            }
                            VStack(alignment: .leading) {
                                Text(movie.title)
                                    .font(.title)
                                    .fontWeight(.bold)
                                HStack(alignment: .bottom, spacing: 4) {
                                    HStack {
                                        Image(systemName: "star.fill")
                                            .foregroundStyle(.yellow)
                                            .font(.subheadline)
                                    }
                                    Text("\(movie.voteAverage)")
                                        .font(.caption)
                                        .foregroundColor(.title)
                                    Text("(\(movie.voteCount))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                }
                                Text("Date release: \(movie.releaseDate)")
                                    .foregroundStyle(.secondary)
                                    .font(.footnote)
                            }
                            Spacer()
                        }
                        Text(movie.overview)
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

    return NavigationStack{

        MovieDetailView(
            movie: .init(
                adult: movie.adult,
                backdropPath: makeUrl(for: movie.backdropPath),
                backdropData: nil,
                genreIDS: movie.genreIDS,
                originalLanguage: movie.originalLanguage,
                originalTitle: movie.title,
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
