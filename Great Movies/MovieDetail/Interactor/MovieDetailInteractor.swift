//
//  MovieDetailInteractor.swift
//  Great Movies
//
//  Created by Juliano Alvarenga on 10/03/24.
//

import Foundation

/// A protocol defining the requirements for fetching detailed movie information and related movies.
///
/// Conform to this protocol to provide implementations for fetching detailed information of a specific movie
/// by its ID and for fetching a list of movies related to a given movie.
protocol MovieDetailInteracting: Sendable {
    /// Fetches detailed information for a movie.
    ///
    /// - Parameter movieId: The unique identifier for the movie.
    /// - Returns: A `MovieDetail` instance containing detailed information about the movie.
    /// - Throws: An error if the fetch operation fails.
    func fetchMovieDetail(movieId: Int) async throws -> MovieDetail

    /// Fetches movies related to the specified movie.
    ///
    /// - Parameter movieId: The unique identifier for the movie for which related movies are to be fetched.
    /// - Returns: A `MovieData` instance containing a list of related movies.
    /// - Throws: An error if the fetch operation fails.
    func fetchRelatedMovies(movieId: Int) async throws -> MovieData
}


/// An implementation of `MovieDetailInteracting` that interacts with a remote API to fetch movie details and related movies.
///
/// This class utilizes the The Movie Database (TMDB) API to fetch detailed information and a list of movies related
/// to a specific movie by its ID. It handles constructing URLs with appropriate query parameters and processing
/// the response data.
final class MovieDetailInteractor: MovieDetailInteracting {

    /// Defines errors that can occur during the fetching operations.
    enum Errors: Error {
        case failToFetchMovieDetail // Indicates failure in fetching movie details.
        case invalidURL // Indicates an invalid URL formation.
    }

    /// Fetches detailed information for a specific movie by its ID.
    ///
    /// - Parameter movieId: The unique identifier for the movie.
    /// - Returns: A `MovieDetail` instance containing detailed information about the movie.
    /// - Throws: `Errors.invalidURL` if URL formation fails, or `Errors.failToFetchMovieDetail` if the network request fails.
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

    /// Fetches movies related to a specific movie by its ID.
        ///
        /// - Parameter movieId: The unique identifier for the movie for which related movies are to be fetched.
        /// - Returns: A `MovieData` instance containing a list of related movies.
        /// - Throws: `Errors.invalidURL` if URL formation fails, or `Errors.failToFetchMovieDetail` if the network request fails.
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
