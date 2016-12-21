//
//  MPD.swift
//  mpd-ios
//
//  Created by Julius Paffrath on 14.12.16.
//  Copyright © 2016 Julius Paffrath. All rights reserved.
//

import SwiftSocket

class MPD: NSObject {
    private let TIMEOUT: Int = 2
    private let DATALEN: Int = 1024*10
    
    private let client: TCPClient
    private(set) var version: String
    
    // MARK: Init
    
    /// Shared Instance of the MPD object
    static let sharedInstance: MPD = {
        return MPD(settings: Settings.sharedInstance)
    }()
    
    init(settings: Settings) {
        self.client = TCPClient(address: settings.getServer(), port: settings.getPort())
        self.version = ""
    }
    
    // MARK: Private Methods
    
    /// Strips a mpd server result
    ///
    /// - parameters:
    ///     - result: result to strip
    ///     - part: number of element to return
    ///
    /// - returns: optional string containing the stripped part or nil
    private func stripResult(result: String, part: Int) -> String? {
        let stripped = result.characters.split(separator: " ").map(String.init)[part]
        // drops the \n at the end of a mpd response
        return String(stripped.characters.dropLast())
    }
    
    /// Strips a mpd server list result
    ///
    /// - parameters:
    ///     - by: sequence to strip by
    ///     - input: input to strip
    ///
    /// - returns: string array containing the stripped part or empty array
    private func stripListResult(by: String, input: String) -> [String] {
        var values: [String] = []
        
        for line in input.components(separatedBy: "\n") {
            if line.contains(by) == true {
                values.append(line.substring(from: by.endIndex))
            }
        }
        
        return values
    }
    
    /// Connects to a mpd server
    ///
    /// - returns: true if the connection was successfull, otherwise false
    private func connect() -> Bool {
        switch self.client.connect(timeout: self.TIMEOUT) {
            case .success:
                if let resultData = self.client.read(self.DATALEN) {
                    let result = String.init(bytes: resultData, encoding: String.Encoding.utf8)
                    
                    if let version = self.stripResult(result: result!, part: 2) {
                        self.version = version
                        print("Connection open: \(version)")
                        return true
                    }
                }

            default: break
        }
        
        return false
    }
    
    /// Closes an active connection to a mpd server
    private func disconnect() {
        self.client.close()
        print("Connection closed")
    }
    
    /// Sends a command async to a mpd server
    ///
    /// - parameters:
    ///     - command: command to send to the server
    ///     - handler: is called with the response when the response is received
    private func sendCommand(command: String, resultHandler:@escaping (String?)->Void) {
        // dispatch communication with mpd server to background
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
            // stores the response from the mpd server
            var response: String = ""

            if self.connect() == true {
                // mpd wants \n terminating command
                switch self.client.send(string: "\(command)\n") {
                case .success:
                    // read as long as the response is not finished
                    while true {
                        if let responseData = self.client.read(self.DATALEN) {
                            if let append = String.init(bytes: responseData, encoding: String.Encoding.utf8) {
                                response.append(append)
                                
                                // if finished with MPD's OK status, response is complete
                                if response.hasSuffix("OK\n") {
                                    break
                                }
                            }
                        }
                    }
                default: break
                }

                self.disconnect()
            }
            
            DispatchQueue.main.async {
                if (response.isEmpty) {
                    resultHandler(nil)
                }
                else {
                    resultHandler(response)
                }
            }
        }
    }
    
    /// Sends a command list async to a mpd server
    ///
    /// - parameters:
    ///     - commands: command list to send to the server
    ///     - handler: is called with the response when the response is received
    private func sendCommandList(commands: [String], handler:@escaping ()->Void) -> Void {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
            
            handleCommands:
            if self.connect() == true {
                
                switch self.client.send(string: "command_list_begin\n") {
                    case .success: break
                    default: break handleCommands
                }
                
                for command in commands {
                    switch self.client.send(string: "\(command)\n") {
                        case .success: break
                        default: break handleCommands
                    }
                }
                
                switch self.client.send(string: "command_list_end\n") {
                    case .success: break
                    default: break handleCommands
                }
                
                if self.client.read(self.DATALEN) != nil {
                    
                }

                self.disconnect()
            }

            DispatchQueue.main.async {
                handler()
            }
        }
    }
    
    // MARK: Public Functions
    
    /// Gets the current mpd status
    ///
    /// - parameters:
    ///     - handler: is called with the current mpd status when the command has finished
    func getStatus(handler:@escaping (MPDStatus?)->Void) {
        self.sendCommand(command: "status", resultHandler: { (result: String?) in
            if result != nil {
                let status = MPDStatus()
                if status.parseInput(input: result!) == nil {
                    handler(status)
                }
                else {
                    handler(nil)
                }
            }
            else {
                handler(nil)
            }
        })
    }
    
    /// Gets the current playlist
    ///
    /// - parameters:
    ///     - handler: is called with an array containing the songs of the current playlist when the command has finished
    func getCurrentPlaylist(handler:@escaping ([MPDSong])->Void) {
        self.sendCommand(command: "playlistinfo", resultHandler: { (result: String?) in
            if let res = result {
                var songs: [MPDSong] = []
                let metadata: [String] = res.components(separatedBy: "file: ")
                
                for input in metadata {
                    
                    if input.isEmpty == false {
                        songs.append(MPDSong.init(input: input))
                    }
                }
                
                handler(songs)
            }
            else {
                handler([])
            }
        })
    }
    
    /// Gets all playlists
    ///
    /// - parameters:
    ///     - handler: is called with the playlists when the command has finished
    func getPlaylists(handler:@escaping ([String])->Void) {
        self.sendCommand(command: "listplaylists", resultHandler: { (result: String?) in
            if let res = result {
                var playlists = res.characters.split(separator: "\n").map(String.init)
                // remove every second element from array, just keep 'playlist: NAME' and 'OK' from response
                playlists = playlists.enumerated().flatMap { index, element in index % 2 == 0 ? element : nil }
                
                // removes 'OK' from mpd response
                if playlists.count > 1 {
                    playlists.removeLast()
                }
                
                var names: [String] = []
                
                for playlist in playlists {
                    // maps the actual playlist name from 'playlist: NAME' to array
                    names.append(playlist.substring(from: "playlist: ".endIndex))
                }
                
                handler(names)
            }
            else {
                handler([])
            }
        })
    }
    
    /// Gets songs from a playlist
    ///
    /// - parameters:
    ///     - playlist: name of the playlist
    ///     - handler: is called with an array of songs from the given playlist when the command has finished
    func getSongsFromPlaylist(playlist: String, handler:@escaping ([MPDSong])->Void) {
        // playlist with whitespaces have to be escaped with quotes
        self.sendCommand(command: "listplaylistinfo \"\(playlist)\"", resultHandler: { (result: String?) in
            if let res = result {
                var songs: [MPDSong] = []
                let metadata: [String] = res.components(separatedBy: "file: ")

                for input in metadata {
                    
                    if input.isEmpty == false {
                        songs.append(MPDSong.init(input: input))
                    }
                }
                
                handler(songs)
            }
            else {
                handler([])
            }
        })
    }
    
    /// Gets all artists
    ///
    /// - parameters:
    ///     - handler: is called with the artists when the command has finished
    func getArtists(handler:@escaping ([String])->Void) {
        self.sendCommand(command: "list artist") { (result: String?) in
            var artists: [String] = []

            if result != nil {
                artists = self.stripListResult(by: "Artist: ", input: result!)
            }
            
            handler(artists)
        }
    }
    
    /// Gets all albums
    ///
    /// - parameters:
    ///     - handler: is called with the albums when the command has finished
    func getAlbums(handler:@escaping ([String])->Void) {
        self.sendCommand(command: "list album") { (result: String?) in
            var albums: [String] = []
            
            if result != nil {
                albums = self.stripListResult(by: "Album: ", input: result!)
            }
            
            handler(albums)
        }
    }
    
    /// Gets all albums by a given artist
    ///
    /// - parameters:
    ///     - forArtist: artist to query albums
    ///     - handler: is called with the albums when the command has finished
    func getAlbums(forArtist: String, handler:@escaping ([String])->Void) {
        self.sendCommand(command: "list album \"\(forArtist)\"") { (result: String?) in
            var albums: [String] = []
            
            if result != nil {
                albums = self.stripListResult(by: "Album: ", input: result!)
            }
            
            handler(albums)
        }
    }
    
    /// Gets all songs for a given album by a given artist
    ///
    /// - parameters:
    ///     - forAlbum: album to query songs
    ///     - byArtist: artist from album
    ///     - handler: is called with the songs when the command has finished
    func getSongs(forAlbum: String, byArtist: String, handler:@escaping ([String])->Void) {
        self.sendCommand(command: "list title album \"\(forAlbum)\" artist \"\(byArtist)\"") { (result: String?) in
            var songs: [String] = []
            
            if result != nil {
                songs = self.stripListResult(by: "Title: ", input: result!)
            }
            
            handler(songs)
        }
    }
    
    /// Begins playing the playlist
    ///
    /// - parameters:
    ///     - nr: song number to start playing with
    func play(nr: Int, handler:@escaping ()->Void) {
        self.sendCommand(command: "play \(nr)", resultHandler: { (result: String?) in
            handler()
        })
    }
    
    /// Plays next song in the playlist
    func playNextSong() {
        self.sendCommand(command: "next", resultHandler: {(result: String?) in
        })
    }
    
    /// Plays next song in the playlist
    ///
    /// - parameters:
    ///     - handler: is called with the current song when the command has finished
    func playNextSong(handler:@escaping (MPDSong?)->Void) {
        self.sendCommand(command: "next", resultHandler: {(result: String?) in
            self.getCurrentSong(handler: { (song: MPDSong?) in
                handler(song)
            })
        })
    }
    
    /// Plays previous song in the playlist
    func playPreviousSong() {
        self.sendCommand(command: "previous", resultHandler: {(result: String?) in
        })
    }
    
    /// Plays previous song in the playlist
    ///
    /// - parameters:
    ///     - handler: is called with the current song when the command has finished
    func playPreviousSong(handler:@escaping (MPDSong?)->Void) {
        self.sendCommand(command: "previous", resultHandler: {(result: String?) in
            self.getCurrentSong(handler: { (song: MPDSong?) in
                handler(song)
            })
        })
    }
    
    /// Resumes playing
    func resume(handler:@escaping ()->Void) {
        self.sendCommand(command: "pause 0", resultHandler: {(result: String?) in
            handler()
        })
    }
    
    /// Pauses playing
    func pause(handler:@escaping ()->Void) {
        self.sendCommand(command: "pause 1", resultHandler: {(result: String?) in
            handler()
        })
    }
    
    /// Stops playing
    func stop(handler:@escaping ()->Void) {
        self.sendCommand(command: "stop", resultHandler: {(result: String?) in
            handler()
        })
    }
    
    /// Gets the current song in the playlist
    ///
    /// - parameters:
    ///     - handler: is called with the current song when the command has finished
    func getCurrentSong(handler:@escaping (MPDSong?)->Void) {
        self.sendCommand(command: "currentsong", resultHandler: {(result: String?) in
            if result != nil {
                if result != "OK\n" {
                    handler(MPDSong.init(input: result!))
                }
            }
            else {
                handler(nil)
            }
        })
    }
    
    /// Loads a playlist
    ///
    /// - parameters:
    ///     - playlist: playlist to load
    ///     - handler: is called when the command has finished
    func loadPlaylist(playlist: String, handler:@escaping ()->Void) {
        self.sendCommand(command: "load \"\(playlist)\"", resultHandler: {(result: String?) in
            handler()
        })
    }
    
    /// Loads a song from a given playlist
    ///
    /// - parameters:
    ///     - playlist: name of the playlist containing the song
    ///     - songNr: number of the song
    ///     - handler: is called when the command has finished
    func loadSongFromPlaylist(playlist: String, songNr: Int, handler:@escaping ()->Void) {
        self.sendCommandList(commands: ["clear", "load \"\(playlist)\"", "play \(songNr)"], handler: handler)
    }
    
    /// Clears the current playlist
    ///
    /// - parameters:
    ///     - handler: is called when the command has finished
    func clearCurrentPlaylist(handler:@escaping ()->Void) {
        self.sendCommand(command: "clear", resultHandler: {(result: String?) in
            handler()
        })
    }
    
    /// Sets the volume
    ///
    /// - parameters:
    ///     - volume: volume to be set. Has to be in the range 0 - 100
    ///     - handler: is called when the command has finished
    func setVolume(volume: UInt, handler:@escaping ()->Void) {
        if (volume > 100) {
            print("Error: The range of volume is 0-100!")
            return
        }

        self.sendCommand(command: "setvol \(volume)", resultHandler: {(result: String?) in
            handler()
        })
    }
    
    /// Sets random
    ///
    /// - parameters:
    ///     - state: new random state
    ///     - handler: is called when the command has finished
    func setRandom(state: Bool, handler:@escaping ()->Void) {
        self.sendCommand(command: "random \(state ? "1" : "0")", resultHandler: {(result: String?) in
            handler()
        })
    }
    
    /// Sets repeat
    ///
    /// - parameters:
    ///     - state: new repeat state
    ///     - handler: is called when the command has finished
    func setRepeat(state: Bool, handler:@escaping ()->Void) {
        self.sendCommand(command: "repeat \(state ? "1" : "0")", resultHandler: {(result: String?) in
            handler()
        })
    }
    
    /// Sets single
    ///
    /// - parameters:
    ///     - state: new single state
    ///     - handler: is called when the command has finished
    func setSingle(state: Bool, handler:@escaping ()->Void) {
        self.sendCommand(command: "single \(state ? "1" : "0")", resultHandler: {(result: String?) in
            handler()
        })
    }
}
