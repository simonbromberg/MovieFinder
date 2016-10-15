//
//  Movie.swift
//  MovieFinder
//
//  Created by Simon Bromberg on 2016-10-11.
//  Copyright © 2016 Bupkis. All rights reserved.
//

import Foundation

struct MovieKeys {
    static let id = "id"
    static let title = "title"
    static let posterPath = "poster_path"
    static let backdropPath = "backdrop_path"
    static let genreIds = "genre_ids"
    
    static let overview = "overview"
}

class Movie : CustomDebugStringConvertible {
    var title: String
    var posterPath: String
    var backdropPath: String
    var id: Int
    var genres: [Int] = []
    var overview: String
    
    var debugDescription: String {
        return title
    }
    
    init(response:AnyObject) {
        id = response.object(forKey: MovieKeys.id) as! Int
        title = response.object(forKey: MovieKeys.title) as? String ?? ""
        
        overview = response.object(forKey: MovieKeys.overview) as? String ?? ""
        
        posterPath = response.object(forKey: MovieKeys.posterPath) as? String ?? ""
        backdropPath = response.object(forKey: MovieKeys.backdropPath) as? String ?? ""
        
        if let g = response.object(forKey: MovieKeys.genreIds) as? [Int] {
            genres = g
        }
    }
    
    var thumbnailURL: URL? {
        if let basePath = UserDefaults.standard.string(forKey: UserDefaultKeys.TMDBimageURLBasePath) {
            return URL(string:  basePath + "w92" + posterPath)
        }
        
        return nil
    }
    
    var backdropURL: URL? {
        let path = !backdropPath.isEmpty ? backdropPath : posterPath
        
        guard !path.isEmpty else {
            return nil
        }
        
        if let basePath = UserDefaults.standard.string(forKey: UserDefaultKeys.TMDBimageURLBasePath) {
            return URL(string:  basePath + "w780" + path)
        }
        
        return nil
    }
}
