//
//  MovieEndpoints.swift
//  MovieFinder
//
//  Created by Simon Bromberg on 2016-10-10.
//  Copyright © 2016 Bupkis. All rights reserved.
//

import Foundation

struct MovieEndpoints {
    private static let idPlaceholder = ":id"
    
    private static let basePath = "https://api.themoviedb.org/3/"
    private static let popularPath = "discover/movie?sort_by=popularity.desc"
    private static let genrePath = "genre/movie/list"
    private static let searchMoviePath = "search/movie"
    
    private static let creditsPath = "movie/" + idPlaceholder + "/credits"
    
//    static let imageBasePath = "https://image.tmdb.org/t/p/" // eg + w300/imageID.jpg
    
    private  static let configurationPath = "configuration"
    
    static var popular: String {
        return basePath + popularPath
    }
    
    static var configuration: String {
        return basePath + configurationPath
    }
    
    static var genreList: String {
        return basePath + genrePath
    }
    
    static var search: String {
        return basePath + searchMoviePath
    }
    
    static func credits(forMovieID id:Int) -> String {
        return basePath + creditsPath.replacingOccurrences(of:idPlaceholder , with: "\(id)")
    }
}
