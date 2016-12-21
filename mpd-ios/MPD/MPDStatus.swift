//
//  MPDStatus.swift
//  mpd-ios
//
//  Created by Julius Paffrath on 15.12.16.
//  Copyright © 2016 Julius Paffrath. All rights reserved.
//

import UIKit

class MPDStatus: NSObject {
    enum MPDState {
        case play
        case stop
        case pause
    }
    
    private(set) var volume:   Int
    private(set) var `repeat`: Bool
    private(set) var random:   Bool
    private(set) var single:   Bool
    private(set) var consume:  Bool
    private(set) var state:    MPDState
    
    override init() {
        self.volume  = 0
        self.repeat  = false
        self.random  = false
        self.single  = false
        self.consume = false
        self.state   = MPDState.stop
    }
    
    func parseInput(input: String) -> String? {
        var error: String? = nil
        
        let parts = input.characters.split(separator: "\n").map(String.init)
        
        for part in parts {
            let stripped = part.characters.split(separator: ":").map(String.init)
            
            if stripped.count == 2 {
                let key = stripped[0]
                let payload = stripped[1].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                
                switch key {
                    case "volume":  self.volume  = Int(payload)!;     break
                    case "repeat":  self.repeat  = payload.toBool()!; break
                    case "random":  self.random  = payload.toBool()!; break
                    case "single":  self.single  = payload.toBool()!; break
                    case "consume": self.consume = payload.toBool()!; break
                    case "error":   error        = payload;           break
                    case "state":
                        switch payload {
                            case "play":  self.state = MPDState.play;  break;
                            case "pause": self.state = MPDState.pause; break;
                            default:      self.state = MPDState.stop;  break;
                    }
                    default: break
                }
            }
        }
        
        return error
    }
}
