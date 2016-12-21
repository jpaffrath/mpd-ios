//
//  ViewControllerSongs.swift
//  mpd-ios
//
//  Created by Julius Paffrath on 21.12.16.
//  Copyright © 2016 Julius Paffrath. All rights reserved.
//

import UIKit
import Toast_Swift

class ViewControllerSongs: UITableViewController {
    private let TAG_LABEL_SONGNAME: Int = 100
    private let COLOR_BLUE = UIColor.init(colorLiteralRed: Float(55.0/255), green: Float(111.0/255), blue: Float(165.0/255), alpha: 1)

    private var songs: [String] = []
    
    var artist: String = ""
    var album: String = ""
    
    // MARK: Init
    
    override func viewDidLoad() {
        self.refreshControl = UIRefreshControl.init()
        self.refreshControl?.backgroundColor = self.COLOR_BLUE
        self.refreshControl?.tintColor = UIColor.white
        self.refreshControl?.addTarget(self, action: #selector(ViewControllerSongs.reloadSongs), for: UIControlEvents.valueChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.title = self.album
        self.reloadSongs()
    }
    
    // MARK: Private Methods
    
    func reloadSongs() {
        MPD.sharedInstance.getSongs(forAlbum: self.album, byArtist: self.artist) { (songs: [String]) in
            self.songs = songs
            self.tableView.reloadData()
            self.refreshControl?.endRefreshing()
        }
    }
    
    // MARK: TableView Delegates

    override func numberOfSections(in tableView: UITableView) -> Int {
        if self.songs.count > 0 {
            self.tableView.separatorStyle = UITableViewCellSeparatorStyle.singleLine
            self.tableView.backgroundView = nil

            return 1
        }
        else {
            let size = self.view.bounds.size
            let labelMsg = UILabel.init(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: size.width, height: size.height)))
            
            labelMsg.text = "No songs available! Pull to refresh"
            labelMsg.textColor = self.COLOR_BLUE
            labelMsg.numberOfLines = 0
            labelMsg.textAlignment = NSTextAlignment.center
            labelMsg.font = UIFont.init(name: "Avenir", size: 20)
            labelMsg.sizeToFit()
            
            self.tableView.backgroundView = labelMsg
            self.tableView.separatorStyle = UITableViewCellSeparatorStyle.none
        }
        
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.songs.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "myCell", for: indexPath)

        let labelSongname: UILabel = cell.viewWithTag(self.TAG_LABEL_SONGNAME) as! UILabel
        labelSongname.text = String(self.songs[indexPath.row])

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let song = self.songs[indexPath.row]

        MPD.sharedInstance.loadSong(title: song, fromAlbum: self.album, byArtist: self.artist) {
            self.tableView.deselectRow(at: indexPath, animated: true)
            self.tableView.makeToast("Added \(song) to current playlist", duration: 0.5, position: .center)
        }
    }
}
