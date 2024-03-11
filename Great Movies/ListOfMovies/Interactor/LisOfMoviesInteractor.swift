//
//  LisOfMoviesInteractor.swift
//  Great Movies
//
//  Created by Juliano Alvarenga on 08/03/24.
//

import Foundation

protocol LisOfMoviesInteracting {
    func fetchMovies(in page: Int) async throws -> MovieData
}

class LisOfMoviesInteractor: LisOfMoviesInteracting {

    enum Errors: Error {
        case failToFetchMovies
        case invalidURL
    }
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
