//
//  MovieDetailViewController.swift
//  MovieFinder
//
//  Created by Simon Bromberg on 2016-10-10.
//  Copyright © 2016 Bupkis. All rights reserved.
//

import UIKit

enum MovieDetailSection: String {
    case Overview = "Overview"
    case Cast = "Cast"
    case Title = "Title"
}

class MovieDetailViewController: UITableViewController {
    @IBOutlet private weak var imageView: UIImageView!
    var movie: Movie?
    var cast: [String] = []
    
    var imageLoadDataTask:URLSessionDataTask?
    
    func configureView() {        
        if movie != nil {
            title = movie?.title
            
            imageView.image = UIImage(named:"placeholder_wide")
            if let url = movie!.backdropURL {
                imageLoadDataTask = imageView.downloadedFrom(url: url)
            }
            else {
                self.tableView.tableHeaderView = nil
            }
        }
    }
    
    var order:[MovieDetailSection] = [.Title, .Overview]
   
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 100
        
        if let id = movie?.id {            
            DataProvider.sharedInstance.getCast(id: id, completion: { (cast:[String], error:Error?) in
                if error != nil {
                    return
                }
                
                self.cast = cast
                
                if cast.count > 0 {
                    self.order += [.Cast]
                    let section = self.order.count - 1
                    
                    self.tableView.insertSections(IndexSet(integer:section), with: .none)
                }
            })
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        imageLoadDataTask?.cancel()
        
        super.viewWillDisappear(animated)
    }
    
    // MARK: Table view
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.order.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! MovieDetailCell
        
        cell.label.text = textForCell(indexPath:indexPath)

        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.order[section].rawValue
    }
    
    func textForCell(indexPath i:IndexPath) -> String {
        let section = self.order[i.section]
        
        switch section {
        case .Overview:
            return movie?.overview ?? "N/A"
        case .Cast:
            return cast.joined(separator: ", ")
        case .Title: // some titles are too long for navigation bar (esp. in portrait)
            return movie?.title ?? "N/A"
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

