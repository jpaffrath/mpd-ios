//
//  ViewControllerSettings.swift
//  mpd-ios
//
//  Created by Julius Paffrath on 14.12.16.
//  Copyright © 2016 Julius Paffrath. All rights reserved.
//

import UIKit

class ViewControllerSettings: UITableViewController, UITextFieldDelegate {
    @IBOutlet weak var cellServerTextField: UITextField!
    @IBOutlet weak var cellPortTextField: UITextField!
    
    // MARK: Init
    
    override func viewDidAppear(_ animated: Bool) {
        let settings: Settings = Settings.sharedInstance
        
        cellServerTextField.text = settings.getServer()
        cellPortTextField.text   = String(settings.getPort())
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        let settings: Settings = Settings.sharedInstance
        
        if let server = cellServerTextField.text, let port = cellPortTextField.text {
            settings.setServer(server: server)
            settings.setPort(port: port)
        }
        else {
            settings.deleteSettings()
        }
    }
    
    // MARK: TextField Delegates
    
    // needed to dismiss the keyboard
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false;
    }
}
