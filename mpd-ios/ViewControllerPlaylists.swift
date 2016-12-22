//
//  ViewControllerPlaylists.swift
//  mpd-ios
//
//  Created by Julius Paffrath on 22.12.16.
//  Copyright © 2016 Julius Paffrath. All rights reserved.
//

import UIKit

class ViewControllerPlaylists: UITableViewController {
    private let TAG_LABEL_PLAYLIST: Int = 100
    private let COLOR_BLUE = UIColor.init(colorLiteralRed: Float(55.0/255), green: Float(111.0/255), blue: Float(165.0/255), alpha: 1)
    
    private var playlists: [String] = []
    
    // MARK: Init
    
    override func viewDidLoad() {
        self.refreshControl = UIRefreshControl.init()
        self.refreshControl?.backgroundColor = self.COLOR_BLUE
        self.refreshControl?.tintColor = UIColor.white
        self.refreshControl?.addTarget(self, action: #selector(ViewControllerPlaylists.reloadPlaylists), for: UIControlEvents.valueChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.reloadPlaylists()
    }
    
    // MARK: Private Methods
    
    func reloadPlaylists() {
        MPD.sharedInstance.getPlaylists { (playlists: [String]) in
            self.playlists = playlists
            self.tableView.reloadData()
            self.refreshControl?.endRefreshing()
        }
    }
    
    // MARK: TableView Delegates
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if self.playlists.count > 0 {
            self.tableView.separatorStyle = UITableViewCellSeparatorStyle.singleLine
            self.tableView.backgroundView = nil
            return 1
        }
        else {
            let size = self.view.bounds.size
            let labelMsg = UILabel.init(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: size.width, height: size.height)))
            
            labelMsg.text = "No playlists available! Pull to refresh"
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
        return self.playlists.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "myCell", for: indexPath)
        
        let labelPlaylist: UILabel = cell.viewWithTag(self.TAG_LABEL_PLAYLIST) as! UILabel
        labelPlaylist.text = self.playlists[indexPath.row]
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let viewController = self.storyboard?.instantiateViewController(withIdentifier: "ViewControllerPlaylistSongs") as! ViewControllerPlaylistSongs
        viewController.playlist = self.playlists[indexPath.row]
        self.navigationController?.pushViewController(viewController, animated: true)
    }
}
