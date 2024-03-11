//
//  LisOfMoviesInteractor.swift
//  Great Movies
//
//  Created by Juliano Alvarenga on 08/03/24.
//

import Foundation

/// A protocol defining the requirements for fetching a list of movies from an external data source.
///
/// Implementations of this protocol should provide a method to fetch movies based on pagination.
protocol LisOfMoviesInteracting {
    /// Fetches a list of movies based on the specified page number.
       ///
       /// - Parameter page: The page number for which movies should be fetched, facilitating pagination.
       /// - Returns: A `MovieData` object containing a list of movies and pagination details.
       /// - Throws: An error if the fetch operation fails.
    func fetchMovies(in page: Int) async throws -> MovieData
}

/// An implementation of `LisOfMoviesInteracting` that fetches movies from The Movie Database (TMDB) API.
///
/// This class constructs URLs with appropriate query parameters for the TMDB API and handles
/// the network request to fetch a list of movies based on the provided page number. It processes
/// the response to return a `MovieData` object containing the movies and pagination details.
class LisOfMoviesInteractor: LisOfMoviesInteracting {

    /// Defines errors that can occur during the movie fetching operations.
    enum Errors: Error {
        case failToFetchMovies // Indicates failure in fetching the list of movies from the API.
        case invalidURL // Indicates an error in URL formation for the API request.
    }

    /// Fetches a list of movies from The Movie Database (TMDB) API based on the specified page number.
    ///
    /// - Parameter page: The page number for which movies should be fetched, facilitating pagination.
    /// - Returns: A `MovieData` object containing a list of movies and pagination details.
    /// - Throws: `Errors.invalidURL` if URL formation fails, or `Errors.failToFetchMovies` if the network request fails.
    func fetchMovies(in page: Int) async throws -> MovieData {
        var components = URLComponents(string: "https://api.themoviedb.org/3/discover/movie")
           let queryItems = [
               URLQueryItem(name: "include_adult", value: "false"),
               URLQueryItem(name: "include_video", value: "false"),
               URLQueryItem(name: "language", value: "en-US"),
               URLQueryItem(name: "page", value: "\(page)"),
               URLQueryItem(name: "sort_by", value: "popularity.desc"),
               URLQueryItem(name: "api_key", value: "faecb8622454db0e4a00b38aab3a4347")
           ]
           components?.queryItems = queryItems

           guard let url = components?.url else {
               throw Errors.invalidURL
           }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let movies = try JSONDecoder().decode(MovieData.self, from: data)
            return movies
        } catch {
            debugPrint("Fail when fetching movies from API \(error.localizedDescription)")
            throw Errors.failToFetchMovies
        }
    }

}
