//
//  String.swift
//  mpd-ios
//
//  Created by Julius Paffrath on 15.12.16.
//  Copyright © 2016 Julius Paffrath. All rights reserved.
//

extension String {
    
    /// converts string to boolean equivalent
    func toBool() -> Bool? {
        switch self {
        case "True", "true", "yes", "1":
            return true
        case "False", "false", "no", "0":
            return false
        default:
            return nil
        }
    }
}
