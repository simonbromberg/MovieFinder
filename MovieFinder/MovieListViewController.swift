//
//  MovieListViewController.swift
//  MovieFinder
//
//  Created by Simon Bromberg on 2016-10-10.
//  Copyright © 2016 Bupkis. All rights reserved.
//

import UIKit
import MBProgressHUD
import Speech
import AFNetworking

class MovieListViewController: UITableViewController, SFSpeechRecognizerDelegate {

    private var movies = [Movie]()
    
    private var page = 0
    
    // tmdb lists max 1000 for paging request https://developers.themoviedb.org/3/discover/movie-discover
    private var maxPage = 1000
    
    private var genreMap = [Int : String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if APIKey == APIKeyNotSet {
            alertAPIKeyMissing()
        }
        
        loadGenres()
        
        navigationItem.rightBarButtonItem = microphoneButton
        microphoneButton.isEnabled = false
        
        setupSpeechRecognition()

        loadMovies(currentPage: page)
        
        setupRefreshControl()
    }
    
    private func alertAPIKeyMissing() {
        let alert = UIAlertController(title: "API Key Error", message: "API Key missing. Please add it to APIKey.swift", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
        
        return
    }
    
    private func loadGenres() {
        DataProvider.sharedInstance.getGenreList { (genres:[Int : String], error:Error?) in
            if error != nil {
                self.alertCommunicationError()
                return
            }
            
            self.genreMap = genres
        }
    }
    
    func setupRefreshControl() {
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(refreshMovies), for: .valueChanged)
        
        tableView.refreshControl = refresh
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        title = " " // so back button doesn't waste space on navigation bar
        
        super.viewWillDisappear(animated)
        
        AFNetworkReachabilityManager.shared().stopMonitoring()
    }
    
    let titlePopularMovies = "Popular movies"
    let titleSearchResults = "Search results"
    
    var communicationError = false
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = (searchQuery ?? "").isEmpty ? titlePopularMovies : titleSearchResults
        
        setupReachabilityWatcher()
    }
    
    private func setupReachabilityWatcher() {
        AFNetworkReachabilityManager.shared().startMonitoring()
        
        AFNetworkReachabilityManager.shared().setReachabilityStatusChange { (status:AFNetworkReachabilityStatus) in
            if status != AFNetworkReachabilityStatus.notReachable {
                if self.movies.count == 0 && self.searchQuery == nil {
                    self.page = 0
                    self.loadMovies(currentPage: self.page)
                    
                    return
                }
                
                if self.genreMap.count == 0 {
                    self.loadGenres()
                }
                
                // Reload visible rows in case internet connection was lost while displaying them
                if self.communicationError {
                    if let paths = self.tableView.indexPathsForVisibleRows {
                        self.communicationError = false
                        self.tableView.reloadRows(at: paths, with: .none)
                    }
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        // If memory warning remove excess movies
        if movies.count > 20 {
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
            movies.removeSubrange(Range(uncheckedBounds: (lower: 20, upper: movies.count - 1)))
            tableView.reloadData()
        }
    }
    
    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let movie = movies[indexPath.row]
                
                let controller = segue.destination as! MovieDetailViewController
                
                controller.movie = movie
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movies.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! MovieListCell

        let movie = movies[indexPath.row]
        cell.textLabel!.text = movie.title
        cell.detailTextLabel!.text = genreIdsToText(movie.genres)
        
        cell.imageURL = movie.thumbnailURL
        
        if indexPath.row >= movies.count - 1 {
            loadMovies(currentPage:page)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        (cell as! MovieListCell).cancelImageLoad()
    }
    
    // MARK: - Load movies
    
    var loadInProgress = false
    private func loadMovies(currentPage:Int) {
        if loadInProgress || currentPage >= maxPage {
            return
        }
        
        if currentPage <= 1 {
            MBProgressHUD.showAdded(to: self.navigationController!.view, animated: true)
        }
        else {
            let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 70))
            let indicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
            indicator.activityIndicatorViewStyle = .gray
            indicator.center = view.center
            indicator.startAnimating()
            view.addSubview(indicator)
            
            tableView.tableFooterView = view
        }
        
//        let deadlineTime = DispatchTime.now() + .seconds(1)
//        DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
        
        self.loadInProgress = true
        
        if let query = self.searchQuery {
            DataProvider.sharedInstance.getSearchResults(query: query) { (movies:[Movie], pages:Int, error:Error?) in
                self.handleMoviesResponse(movies: movies, pages: pages, error: error)
            }
        }
        else {
            DataProvider.sharedInstance.getPopularMovies(page: currentPage + 1) { (movies:[Movie], pages:Int, error: Error?) in
                self.handleMoviesResponse(movies: movies, pages: pages, error: error)
            }
        }
    }
    
    private func handleMoviesResponse(movies:[Movie], pages:Int, error:Error?) {
        loadInProgress = false
        
        if refreshControl?.isRefreshing ?? false {
            refreshControl?.endRefreshing()
        }
        
        MBProgressHUD.hide(for: self.navigationController!.view, animated: true)
        tableView.tableFooterView = nil
        
        if error != nil {
            self.alertCommunicationError()
            
            return
        }
        
        page += 1
        maxPage = min(pages, self.maxPage)
        
        // insert new rows
        let count = self.movies.count
        let additional = movies.count
        
        var paths = [IndexPath]()
        for i in count..<(count + additional) {
            paths += [IndexPath(row: i, section: 0)]
        }
        
        self.movies += movies
        
        self.tableView.insertRows(at: paths, with: .fade)
        
        if self.movies.count == 0 {
            showNoResultsView()
        }
        else {
            tableView.tableFooterView = nil
        }
    }
    
    private func showNoResultsView() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 300))
        let label = UILabel(frame: view.frame.insetBy(dx: 10, dy: 10))
        label.text = (self.searchQuery ?? "").isEmpty ? "No results!" : "Your query:\n'" + self.searchQuery! + "'\nreturned no results"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 30)
        label.minimumScaleFactor = 0.4
        label.adjustsFontSizeToFitWidth = true
        label.numberOfLines = 0
        label.center = view.center
        
        view.addSubview(label)
        
        tableView.tableFooterView = view
    }
    
    @objc private func refreshMovies() {
        page = 0
        loadMovies(currentPage: page)    
    }
    
    // MARK: Communication error alert
    private var communicationAlert:UIAlertController?
    
    private func alertCommunicationError() {
        communicationError = true
        
        if communicationAlert != nil {
            return
        }
        
        communicationAlert = UIAlertController(title: "Communication error", message: "⚠", preferredStyle: .alert)
        
        communicationAlert!.addAction(UIAlertAction(title: "Retry", style: .default, handler: { (action:UIAlertAction) in
            self.communicationError = false
            
            self.loadMovies(currentPage: self.page)
            
            if let paths = self.tableView.indexPathsForVisibleRows {
                self.tableView.reloadRows(at: paths, with: .none)
            }
            
            self.communicationAlert = nil
        }))
        
        communicationAlert!.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action:UIAlertAction) in
            self.communicationAlert = nil
        }))
        
        present(communicationAlert!, animated: true)
    }
    
    // MARK: Genres
    private func genreIdsToText(_ genres:[Int]) -> String {
        if genreMap.count == 0 {
            return ""
        }
        
        var genreText = [String]()
        for id in genres {
            if let genre = genreMap[id] {
                genreText += [genre]
            }
        }
        
        return genreText.joined(separator: ", ")
    }
    
    // MARK: Search
    private lazy var microphoneButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage(named:"microphone"), style: .done, target: self, action: #selector(voiceSearch))
        return button
    }()
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private let audioEngine = AVAudioEngine()
    
    private func setupSpeechRecognition() {
        speechRecognizer.delegate = self
        SFSpeechRecognizer.requestAuthorization { authStatus in
            /*
             The callback may not be called on the main thread. Add an
             operation to the main queue to update the record button's state.
             */
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    self.microphoneButton.isEnabled = true
                default:
                    self.microphoneButton.isEnabled = false
                }
            }
        }
    }
    
    private var speechRecognitionAlert: UIAlertController?
    private var speechRecognitionTimeout: Timer?
    
    private func restartSpeechTimeout() {
        speechRecognitionTimeout?.invalidate()
        
        speechRecognitionTimeout = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(stopRecording), userInfo: nil, repeats: false)
    }
    
    @objc private func voiceSearch() {
        if navigationItem.leftBarButtonItem != nil { // already an existing search
            cancelSearch(reload:false)            
        }
        
        speechRecognitionAlert = UIAlertController(title: "Vocal search...", message: "Please say the name of the movie you wish to find:", preferredStyle: .alert)
        
        speechRecognitionAlert!.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            self.recognitionTask?.cancel()
        }))
        
        present(speechRecognitionAlert!, animated: true, completion: { _ in
            if TARGET_OS_SIMULATOR != 0 {
                self.searchMovies(query: "Back to the Future")
                self.speechRecognitionAlert?.dismiss(animated: true, completion: { 
                    self.speechRecognitionAlert = nil
                })
            }
            else {
                try! self.startRecording()
            }
        })
    }
    
    private func startRecording() throws {
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.audioEngine.stop()
            self.recognitionTask = nil
            self.recognitionRequest = nil
            self.recognitionTask = nil
            
            self.microphoneButton.isEnabled = true
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(AVAudioSessionCategoryRecord)
        try audioSession.setMode(AVAudioSessionModeMeasurement)
        try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngine.inputNode else { fatalError("Audio engine has no input node") }
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object") }
        
        // Configure request so that results are returned before audio recording is finished
        recognitionRequest.shouldReportPartialResults = true
        
        // A recognition task represents a speech recognition session.
        // We keep a reference to the task so that it can be cancelled.
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            if let result = result {
                isFinal = result.isFinal
                if let alert = self.speechRecognitionAlert {
                    alert.message = result.bestTranscription.formattedString
                }
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.microphoneButton.isEnabled = true
            }
            
            if isFinal {
                self.searchMovies(query: result!.bestTranscription.formattedString)
            }
            else {
                if error == nil {
                    self.restartSpeechTimeout()
                }
                else {
                    self.cancelSearch()
                }
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        try audioEngine.start()
    }
    
    @objc private func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        
        speechRecognitionTimeout?.invalidate()
        speechRecognitionTimeout = nil
        
        if speechRecognitionAlert != nil {
            speechRecognitionAlert!.dismiss(animated: true, completion: {
                self.speechRecognitionAlert = nil
            })
        }
    }
    
    var searchQuery:String?
    
    private func searchMovies(query:String) {
        speechRecognitionTimeout?.invalidate()
        speechRecognitionTimeout = nil
        
        if query.isEmpty {
            cancelSearch(reload:true)
            return
        }
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelSearchAction))
            
        searchQuery = query
        
        if movies.count > 0 {
            tableView.scrollToRow(at: IndexPath(row:0, section:0), at: .top, animated: false)
        }
        
        movies = []
        tableView.reloadData()
        
        title = titleSearchResults
        loadMovies(currentPage: 1)
    }
    
    @objc private func cancelSearchAction() { // action selectors can't have parameters like below
        cancelSearch()
    }
    
    private func cancelSearch(reload: Bool = true) {
        navigationItem.leftBarButtonItem = nil
        searchQuery = nil
        movies = []
        
        page = 0
        maxPage = 1000
        
        if reload {
            // don't want to bother reloading if there's an existing search in the table view
            // but do want to reload back to the popular list otherwise
            title = titlePopularMovies
            
            tableView.reloadData()
            
            loadMovies(currentPage: page)
        }
    }
}

