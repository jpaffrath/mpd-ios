//
//  ViewControllerSongs.swift
//  mpd-ios
//
//  Created by Julius Paffrath on 16.12.16.
//  Copyright © 2016 Julius Paffrath. All rights reserved.
//

import UIKit

class ViewControllerSongs: UITableViewController {
    private let TAG_LABEL_SONGNR:   Int = 100
    private let TAG_LABEL_SONGNAME: Int = 101
    private let COLOR_BLUE = UIColor.init(colorLiteralRed: Float(55.0/255), green: Float(111.0/255), blue: Float(165.0/255), alpha: 1)
    
    private var songs: [MPDSong] = []
    private var albumbs: [String] = []
    
    var playlist: String = ""
    
    // MARK: Init
    
    override func viewDidLoad() {
        self.refreshControl = UIRefreshControl.init()
        self.refreshControl?.backgroundColor = self.COLOR_BLUE
        self.refreshControl?.tintColor = UIColor.white
        self.refreshControl?.addTarget(self, action: #selector(ViewControllerSongs.reloadSongs), for: UIControlEvents.valueChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.title = self.playlist
        self.reloadSongs()
    }
    
    // MARK: Private Methods
    
    func reloadSongs() {
        MPD.sharedInstance.getSongsFromPlaylist(playlist: self.playlist, handler: { (songs: [MPDSong]) in
            self.songs = songs
            self.reloadAlbums()
            self.tableView.reloadData()
            self.refreshControl?.endRefreshing()
        })
    }
    
    private func reloadAlbums() {
        for song in self.songs {
            let album = song.album
            
            if self.albumbs.contains(album) == false {
                self.albumbs.append(album)
            }
        }
    }
    
    // MARK: TableView Delegates

    override func numberOfSections(in tableView: UITableView) -> Int {
        if self.songs.count > 0 {
            self.tableView.separatorStyle = UITableViewCellSeparatorStyle.singleLine
            self.tableView.backgroundView = nil

            return self.albumbs.count
        }
        else {
            let size = self.view.bounds.size
            let labelMsg = UILabel.init(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: size.width, height: size.height)))
            
            labelMsg.text = "No songs available! Pull to refresh playlists"
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
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.albumbs[section]
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.songs.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "myCell", for: indexPath)
        
        let labelSongnr: UILabel = cell.viewWithTag(self.TAG_LABEL_SONGNR) as! UILabel
        labelSongnr.text = String(self.songs[indexPath.row].track)

        let labelSongname: UILabel = cell.viewWithTag(self.TAG_LABEL_SONGNAME) as! UILabel
        labelSongname.text = self.songs[indexPath.row].title

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        MPD.sharedInstance.loadSongFromPlaylist(playlist: self.playlist, songNr: indexPath.row) { 
            
        }
    }
}
