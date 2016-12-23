//
//  MPDAlbum.swift
//  mpd-ios
//
//  Created by Julius Paffrath on 22.12.16.
//  Copyright © 2016 Julius Paffrath. All rights reserved.
//

import Foundation

class MPDAlbum: NSObject {
    private(set) var name: String = ""
    private(set) var songs: [MPDSong] = []
    
    init(name: String) {
        self.name = name
    }
    
    init(name: String, songs: [MPDSong]) {
        self.name = name
        self.songs = songs
    }
    
    func addSong(input: String) {
        self.songs.append(MPDSong(input: input))
    }
    
    func addSong(song: MPDSong) {
        self.songs.append(song)
    }
}
