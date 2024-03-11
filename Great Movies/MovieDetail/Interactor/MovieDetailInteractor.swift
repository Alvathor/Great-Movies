//
//  MovieDetailInteractor.swift
//  Great Movies
//
//  Created by Juliano Alvarenga on 10/03/24.
//

import Foundation

protocol MovieDetailInteracting: Sendable {
    func fetchMovieDetail(movieId: Int) async throws -> MovieDetail
    func fetchRelatedMovies(movieId: Int) async throws -> MovieData
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

    func fetchRelatedMovies(movieId: Int) async throws -> MovieData {
        var components = URLComponents(string: "https://api.themoviedb.org/3/movie/\(movieId)/similar")
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
            let relatedMovies = try JSONDecoder().decode(MovieData.self, from: data)
            return relatedMovies
        } catch {
            debugPrint(error)
            throw Errors.failToFetchMovieDetail
        }
    }

}
