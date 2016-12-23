//
//  MPDArtist.swift
//  mpd-ios
//
//  Created by Julius Paffrath on 22.12.16.
//  Copyright © 2016 Julius Paffrath. All rights reserved.
//

import Foundation

class MPDArtist: NSObject {
    private(set) var name: String = ""
    private(set) var albums: [MPDAlbum] = []
    
    init(name: String, input: String) {
        super.init()

        self.name = name
        let metadata: [String] = input.components(separatedBy: "file: ")
        
        for line in metadata {
            if line.isEmpty {
                continue
            }
            
            let song = MPDSong(input: line)
            
            if self.containsAlbum(withName: song.album) {
                self.addSongToAlbum(song: song)
            }
            else {
                self.albums.append(MPDAlbum(name: song.album, songs: [song]))
            }
        }
    }
    
    func containsAlbum(withName: String) -> Bool {
        for album in self.albums {
            if album.name == withName {
                return true
            }
        }
        
        return false
    }
    
    func addSongToAlbum(song: MPDSong) {
        var index = 0
        
        for album in self.albums {
            if album.name == song.album {
                self.albums[index].addSong(song: song)
            }
            
            index += 1
        }
    }
}
