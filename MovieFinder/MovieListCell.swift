//
//  MovieListCell.swift
//  MovieFinder
//
//  Created by Simon Bromberg on 2016-10-13.
//  Copyright © 2016 Bupkis. All rights reserved.
//

import UIKit

class MovieListCell : UITableViewCell {
    var imageLoadDataTask:URLSessionDataTask?
    var imageURL: URL? {
        didSet {
            guard imageView != nil else {
                return
            }
            
            imageView!.image = UIImage(named: "placeholder")        
            
            imageLoadDataTask = imageView!.downloadedFrom(url: imageURL!)            
        }
    }
    
    func cancelImageLoad() {
        if let task = imageLoadDataTask {
            task.cancel()
        }
    }
}
