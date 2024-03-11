//
//  Movies.swift
//  Great Movies
//
//  Created by Juliano Alvarenga on 08/03/24.
//

import Foundation

// MARK: - MovieData
struct MovieData: Codable {
    let page: Int
    let movies: [Movie]
    let totalPages, totalResults: Int

    enum CodingKeys: String, CodingKey {
        case page = "page"
        case movies = "results"
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

// MARK: - Movie
struct Movie: Codable, Identifiable {
    let backdropPath: String?
    let id: Int
    let overview: String
    let popularity: Double
    let posterPath, releaseDate, title: String
    let voteAverage: Double
    let voteCount: Int

    enum CodingKeys: String, CodingKey {
        case backdropPath = "backdrop_path"
        case id
        case overview, popularity
        case posterPath = "poster_path"
        case releaseDate = "release_date"
        case title
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
    }
}


// MARK: - MovieDetail
struct MovieDetail: Codable {
    let genres: [Genre]
}

// MARK: - Genre
struct Genre: Codable {
    let id: Int
    let name: String
}


// MARK: Persisted Data

import SwiftData

@Model
final class PersistedMovieData: Sendable {
    let movieId: Int
    @Attribute(.externalStorage) let backdropData: Data?
    var genres: [String]
    let overview: String
    let popularity: Double
    @Attribute(.externalStorage) let posterData: Data?
    let releaseDate: String
    let title: String
    let voteAverage: Double
    let voteCount: Int

    init(
        movieId: Int,
        backdropData: Data?,
        genres: [String],        
        overview: String,
        popularity: Double,
        posterData: Data?,
        releaseDate: String,
        title: String,
        voteAverage: Double,
        voteCount: Int
    ) {
        self.movieId = movieId
        self.backdropData = backdropData
        self.genres = genres
        self.overview = overview
        self.popularity = popularity
        self.posterData = posterData
        self.releaseDate = releaseDate
        self.title = title        
        self.voteAverage = voteAverage
        self.voteCount = voteCount
    }
}
