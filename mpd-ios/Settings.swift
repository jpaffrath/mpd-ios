//
//  Settings.swift
//  mpd-ios
//
//  Created by Julius Paffrath on 14.12.16.
//  Copyright © 2016 Julius Paffrath. All rights reserved.
//

import Foundation

class Settings: NSObject {
    private let SETTING_SERVER: String = "mpd-ios.setting.server"
    private let SETTING_PORT:   String = "mpd-ios.setting.port"
    
    private var settings: UserDefaults
    
    /// Shared Instance of the Settings object
    static let sharedInstance: Settings = {
        return Settings()
    }()
    
    override init() {
        self.settings = UserDefaults.standard
    }
    
    func setServer(server: String) {
        self.settings.setValue(server, forKey: SETTING_SERVER)
    }
    
    func setPort(port: String) {
        self.settings.setValue(port, forKey: SETTING_PORT)
    }
    
    func getServer() -> String {
        if let server = self.settings.string(forKey: SETTING_SERVER) {
            return server
        }
        return ""
    }
    
    func getPort() -> Int32 {
        return Int32(self.settings.integer(forKey: self.SETTING_PORT))
    }
    
    func checkSettings() -> Bool {
        return self.getServer() != "" && self.getPort() != 0
    }
    
    func deleteSettings() {
        self.settings.removeObject(forKey: SETTING_SERVER)
        self.settings.removeObject(forKey: SETTING_PORT)
    }
}
