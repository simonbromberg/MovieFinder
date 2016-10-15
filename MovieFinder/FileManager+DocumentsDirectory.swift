//
//  FileManager+DocumentsDirectory.swift
//  MovieFinder
//
//  Created by Simon Bromberg on 2016-10-13.
//  Copyright © 2016 Bupkis. All rights reserved.
//

import Foundation

extension FileManager {
    var applicationDocumentsDirectoryURL : URL {
        return urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    var applicationDocumentsDirectoryPath : String {
        return applicationDocumentsDirectoryURL.path
    }
}
