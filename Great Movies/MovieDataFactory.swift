//
//  MovieDataFactory.swift
//  Great Movies
//
//  Created by Juliano Alvarenga on 10/03/24.
//

import Foundation


protocol MovieDataFactoring: Sendable {
    func fetchData(for urlString: String?) async  -> Data?
    func makePersistedMovieData(with movies: [Movie]) async -> [PersistedMovieData]
    func makePersistedMovieData(with movie: DataModel) -> PersistedMovieData
    func makeDataModel(with movies: [Movie]) -> [DataModel]
    func makeDataModel(with movies: [PersistedMovieData]) async -> [DataModel]
    func addDetails(in movie: DataModel, from details: MovieDetail) -> DataModel
}

final class MovieDataFactory: Sendable, MovieDataFactoring {

    private func makeUrl(for path: String?) -> String {
        let baseURL = "https://image.tmdb.org/t/p/"
        let size = "w500"
        let fullURL = baseURL + size + (path ?? "")
        return fullURL
    }

    func fetchData(for urlString: String?) async  -> Data? {
        guard let url = URL(string: makeUrl(for: urlString)) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return data
        } catch {
            return nil
        }

    }

    func addDetails(in movie: DataModel, from details: MovieDetail) -> DataModel {
        var dataModel = movie
        dataModel.genres = details.genres.map(\.name)        
        return dataModel
    }

    func makePersistedMovieData(with movies: [Movie]) async -> [PersistedMovieData] {
        var persistedMovies: [PersistedMovieData] = []

        // Create a task group to perform concurrent downloads
        await withTaskGroup(of: PersistedMovieData?.self) { group in
            for movie in movies {
                group.addTask { [weak self] in
                    let backdropPathData = await self?.fetchData(for: Self.makeUrl(for: movie.backdropPath))
                    let posterPathData = await self?.fetchData(for: Self.makeUrl(for: movie.posterPath))

                    // Create and return a PersistedMovieData object
                    return PersistedMovieData(
                        movieId: movie.id,
                        adult: movie.adult,
                        backdropData: backdropPathData,
                        genres: [],
                        originalLanguage: movie.originalLanguage,
                        originalTitle: movie.title,
                        overview: movie.overview,
                        popularity: movie.popularity,
                        posterData: posterPathData,
                        releaseDate: movie.releaseDate,
                        title: movie.title,
                        video: movie.video,
                        voteAverage: movie.voteAverage,
                        voteCount: movie.voteCount
                    )
                }
            }

            // Collect results from all tasks
            for await persistedMovie in group {
                guard let persistedMovie else { return }
                persistedMovies.append(persistedMovie)
            }
        }

        return persistedMovies
    }
    
    func makePersistedMovieData(with movie: DataModel) -> PersistedMovieData {
        .init(
            movieId: movie.movieId,
            adult: movie.adult,
            backdropData: movie.backdropData,
            genres: movie.genres,
            originalLanguage: movie.originalLanguage,
            originalTitle: movie.originalTitle,
            overview: movie.overview,
            popularity: movie.popularity,
            posterData: movie.posterData,
            releaseDate: movie.releaseDate,
            title: movie.title,
            video: movie.video,
            voteAverage: Double(movie.voteAverage) ?? 0.0,
            voteCount: movie.voteCount
        )
    }

    func makeDataModel(with movies: [Movie]) -> [DataModel]{
        movies.map {
            .init(
                movieId: $0.id,
                adult: $0.adult,
                backdropPath: makeUrl(for: $0.backdropPath),
                backdropData: nil,
                genres: [],
                originalLanguage: $0.originalLanguage,
                originalTitle: $0.originalLanguage,
                overview: $0.overview,
                popularity: $0.popularity,
                posterPath: makeUrl(for: $0.posterPath),
                posterData: nil,
                releaseDate: $0.releaseDate,
                title: $0.title,
                video: $0.video,
                voteAverage: $0.voteAverage.round,
                voteCount: $0.voteCount
            )
        }
    }

    func makeDataModel(with movies: [PersistedMovieData]) async -> [DataModel] {
        var persistedMovies: [DataModel] = []

        // Create a task group to perform concurrent downloads
        await withTaskGroup(of: DataModel?.self) { group in
            for movie in movies {
                group.addTask {
                    return DataModel(
                        movieId: movie.movieId,
                        adult: movie.adult,
                        backdropPath: "",
                        backdropData: movie.backdropData,
                        genres: [],
                        originalLanguage: movie.originalLanguage,
                        originalTitle: movie.title,
                        overview: movie.overview,
                        popularity: movie.popularity,
                        posterPath: "",
                        posterData: movie.posterData,
                        releaseDate: movie.releaseDate,
                        title: movie.title,
                        video: movie.video,
                        voteAverage: movie.voteAverage.round,
                        voteCount: movie.voteCount
                    )
                }
            }

            // Collect results from all tasks
            for await persistedMovie in group {
                guard let persistedMovie else { return }
                persistedMovies.append(persistedMovie)
            }
        }

        return persistedMovies
    }

    static private func makeUrl(for path: String?) -> String {
        let baseURL = "https://image.tmdb.org/t/p/"
        let size = "w500"
        let fullURL = baseURL + size + (path ?? "")
        return fullURL
    }

}

extension Double {
    var round: String {
        String(format: "%.2f", self)
    }
}
