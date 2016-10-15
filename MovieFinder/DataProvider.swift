//
//  DataProvider.swift
//  MovieFinder
//
//  Created by Simon Bromberg on 2016-10-10.
//  Copyright © 2016 Bupkis. All rights reserved.
//

import Foundation
import AFNetworking

struct ServerKey {
    static let results = "results"
    
    static let totalPages = "total_pages"
    static let page = "page"
    static let genres = "genres"
    static let cast = "cast"
    static let images = "images"
    static let secureBaseURL = "secure_base_url"
    
    static let name = "name"
    static let id = "id"
    
    static let query = "query"
}

class DataProvider {
    static let sharedInstance = DataProvider()
    
    private lazy var sessionManager:AFHTTPSessionManager = {
        let manager = AFHTTPSessionManager()
        manager.requestSerializer = AFJSONRequestSerializer()
        manager.responseSerializer = AFJSONResponseSerializer()

        return manager
    }()
    
    enum MoviesError: Error {
        case EmptyResponse
        case InvalidResponse
    }
    
    func getPopularMovies(page:Int = 1, completion:@escaping ([Movie], Int, Error?) -> Void) {
        let endpoint = MovieEndpoints.popular
        
        var params = defaultParams
        params[ServerKey.page] = page
        
        sessionManager.get(endpoint, parameters: params, progress: nil, success: { (task:URLSessionDataTask, responseObject:Any?) in
            guard responseObject != nil else {
                completion([], 0, MoviesError.EmptyResponse)
                return
            }
            
            let (movies, pages) = self.populateMovies(fromResponse: responseObject)
            
            if pages == -1 {
                completion([], 0, MoviesError.InvalidResponse)
                return
            }
            
            completion(movies, pages, nil)
            
            }, failure: { (task:URLSessionDataTask?, error:Error) in
                completion([], -1, error)
                print(error)
        })
    }
    
    func getConfiguration(completion:@escaping (Bool) -> Void) {
        sessionManager.get(MovieEndpoints.configuration, parameters: defaultParams, progress: nil, success: {  (task:URLSessionDataTask, responseObject:Any?) in
            guard responseObject != nil else {
                completion(false)
                return
            }
            
            let response = responseObject! as! [String : Any]
            let imagesDic = response[ServerKey.images] as! [String : Any]
            let path = imagesDic[ServerKey.secureBaseURL] as! String
            
            UserDefaults.standard.set(path, forKey: UserDefaultKeys.TMDBimageURLBasePath)
            completion(true)
            
            }, failure: { (task:URLSessionDataTask?, error:Error) in
                print(error)
                completion(false)
        })
    }
    
    // https://developers.themoviedb.org/3/genres/get-movie-list
    func getGenreList(completion:@escaping([Int:String], Error?) -> Void) {
        sessionManager.get(MovieEndpoints.genreList, parameters: defaultParams, progress: nil, success: {  (task:URLSessionDataTask, responseObject:Any?) in
            guard responseObject != nil else {
                completion([:], MoviesError.EmptyResponse)
                return
            }
            
            let response = responseObject! as! [String : Any]
            let results = response[ServerKey.genres] as! [[String : Any]]
            
            var genres = [Int : String]()
            
            for result in results {
                if let name = result[ServerKey.name] as? String {
                    let id = result[ServerKey.id] as! Int
                    genres[id] = name
                }
            }
            
            completion(genres, nil)
            
            }, failure: { (task:URLSessionDataTask?, error:Error) in
                print(error)
                completion([:], error)
        })
    }
    
    func getCast(id:Int, completion:@escaping([String], Error?) -> Void) {
        sessionManager.get(MovieEndpoints.credits(forMovieID: id), parameters: defaultParams, progress: nil, success: {  (task:URLSessionDataTask, responseObject:Any?) in
            guard responseObject != nil else {
                return
            }
            
            let response = responseObject! as! [String : Any]
            let results = response[ServerKey.cast] as! [[String : Any]]
            
            var cast = [String]()
            
            for result in results {
                if let name = result[ServerKey.name] as? String {
                    cast += [name]
                }
            }
            
            completion(cast, nil)
            
            }, failure: { (task:URLSessionDataTask?, error:Error) in
                print(error)
                completion([], error)
                
        })
    }
    
    func getSearchResults(page: Int = 1, query:String, completion:@escaping ([Movie], Int, Error?) -> Void) {
        let endpoint = MovieEndpoints.search
        
        var params = defaultParams
        params[ServerKey.page] = page
        params[ServerKey.query] = query
        
        sessionManager.get(endpoint, parameters: params, progress: nil, success: { (task:URLSessionDataTask, responseObject:Any?) in
            guard responseObject != nil else {
                completion([], 0, MoviesError.EmptyResponse)
                return
            }
            
            let (movies, pages) = self.populateMovies(fromResponse: responseObject)                        
            
            if pages == -1 {
                completion([], 0, MoviesError.InvalidResponse)
                return
            }
            
            completion(movies, pages, nil)
            
            }, failure: { (task:URLSessionDataTask?, error:Error) in
                completion([], -1, error)
                print(error)
        })
    }
        
    // MARK: Helpers
    
    func populateMovies(fromResponse response:Any) -> (movies:[Movie], totalPages:Int) {
        let responseObject = response as! [String : Any]
        guard let results = responseObject[ServerKey.results] as? [AnyObject] else {
            return ([], -1)
        }
        
        let pages = responseObject[ServerKey.totalPages] as! Int
        
        var movies = [Movie]()
        
        for result in results {
            movies += [Movie(response: result)]
        }
        
        return (movies, pages)
    }
    
    
    private var defaultParams:[String : Any] {
        return ["api_key" : APIKey]
    }
}
