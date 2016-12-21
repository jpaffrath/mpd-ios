//
//  ViewControllerHome.swift
//  mpd-ios
//
//  Created by Julius Paffrath on 14.12.16.
//  Copyright © 2016 Julius Paffrath. All rights reserved.
//

import UIKit
import SwiftSocket

class ViewControllerHome: UIViewController, UITableViewDelegate, UITableViewDataSource {
	private let TAG_LABEL_SONGNR:   Int = 100
	private let TAG_LABEL_SONGNAME: Int = 101
	private let COLOR_BLUE = UIColor.init(colorLiteralRed: Float(55.0/255), green: Float(111.0/255), blue: Float(165.0/255), alpha: 1)
	
	private let buttonImagePlay = UIImage(named: "play")
	private let buttonImagePlayDisabled = UIImage(named: "play_disabled")
	
	private let buttonImagePause = UIImage(named: "pause")
	private let buttonImagePauseDisabled = UIImage(named: "pause_disabled")
	
	private let buttonImageStop = UIImage(named: "stop")
	private let buttonImageStopDisabled = UIImage(named: "stop_disabled")
	
	private let buttonImageNext = UIImage(named: "next")
	private let buttonImageNextDisabled = UIImage(named: "next_disabled")
	
	private let buttonImagePrevious = UIImage(named: "previous")
	private let buttonImagePreviousDisabled = UIImage(named: "previous_disabled")

	private var currentPlaylist: [MPDSong] = []
	private var mpdState: MPDStatus.MPDState = MPDStatus.MPDState.stop
	
	private var updateTimer: Timer? = nil
	
    @IBOutlet weak var buttonPlay: UIButton!
    @IBOutlet weak var buttonNext: UIButton!
    @IBOutlet weak var buttonPrevious: UIButton!
    
    @IBOutlet weak var tableViewSongs: UITableView!
    @IBOutlet weak var labelCurrentSong: UILabel!
	
	// MARK: Init
	
	override func viewDidAppear(_ animated: Bool) {
		if Settings.sharedInstance.getServer() == "" {
			self.showSettingsViewController()
		}
		else {
			self.initUpdateTimer()
		}
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		self.updateTimer?.invalidate()
	}
	
	override func viewDidLoad() {
		self.buttonNext.setImage(self.buttonImageNextDisabled, for: UIControlState.disabled)
		self.buttonPrevious.setImage(self.buttonImagePreviousDisabled, for: UIControlState.disabled)
	}
	
	private func initUpdateTimer() {
		if #available(iOS 10.0, *) {
			self.updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (timer: Timer) in
				self.loadState()
			})
		} else {

		}
	}
	
	// IBActions
	
	@IBAction func play(_ sender: Any) {
		self.disableButtons()
		
		if self.mpdState == .play {
			self.buttonPlay.setImage(self.buttonImagePlayDisabled, for: UIControlState.disabled)
			
			MPD.sharedInstance.pause {
				self.buttonPlay.setImage(self.buttonImagePlay, for: UIControlState.normal)
				self.mpdState = .pause
				self.enableButtons()
			}
		}
		else {
			self.buttonPlay.setImage(self.buttonImagePauseDisabled, for: UIControlState.disabled)
			
			MPD.sharedInstance.resume {
				self.buttonPlay.setImage(self.buttonImagePause, for: UIControlState.normal)
				self.mpdState = .play
				self.enableButtons()
			}
		}
	}
	
	@IBAction func next(_ sender: Any) {
		self.disableButtons()
		
		MPD.sharedInstance.playNextSong { (song: MPDSong?) in
			self.enableButtons()
			self.buttonPlay.setImage(self.buttonImagePause, for: UIControlState.normal)
			self.loadCurrentSong(song: song)
		}
	}
	
	@IBAction func previous(_ sender: Any) {
		self.disableButtons()
		
		MPD.sharedInstance.playPreviousSong { (song: MPDSong?) in
			self.enableButtons()
			self.buttonPlay.setImage(self.buttonImagePause, for: UIControlState.normal)
			self.loadCurrentSong(song: song)
		}
	}
	
	// MARK: Private Methods

	private func showSettingsViewController() {
		let alertController = UIAlertController(title: "Settings", message: "Please enter your server connection", preferredStyle: .alert)

		alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (alertAction: UIAlertAction) in
			let textFieldServer = alertController.textFields![0] as UITextField
			let textFieldPort   = alertController.textFields![1] as UITextField

			let settings: Settings = Settings.sharedInstance
			settings.setServer(server: textFieldServer.text!)
			settings.setPort(port: textFieldPort.text!)
			
			self.loadState()
		}))
		
		alertController.addTextField { (textField: UITextField) in
			textField.placeholder = "Server"
			textField.keyboardType = UIKeyboardType.URL
		}

		alertController.addTextField { (textField: UITextField) in
			textField.placeholder = "Port"
			textField.keyboardType = UIKeyboardType.numbersAndPunctuation
		}

		present(alertController, animated: true, completion: nil)
	}
	
	private func loadState() {
		MPD.sharedInstance.getStatus { (status: MPDStatus?) in
			if status != nil {
				self.mpdState = status!.state
				
				switch self.mpdState {
				case .play:
					self.buttonPlay.setImage(UIImage(named: "pause"), for: UIControlState.normal)
					break
				case .pause:
					self.buttonPlay.setImage(UIImage(named: "play"), for: UIControlState.normal)
					break
				case .stop:
					self.buttonPlay.setImage(UIImage(named: "play"), for: UIControlState.normal)
					break
				}
			}
			
			MPD.sharedInstance.getCurrentPlaylist { (songs: [MPDSong]) in
				self.currentPlaylist = songs
				self.tableViewSongs.reloadData()
				
				MPD.sharedInstance.getCurrentSong { (song: MPDSong?) in
					self.loadCurrentSong(song: song)
				}
			}
		}
	}
	
	private func enableButtons() {
		self.buttonPlay.isEnabled = true
		self.buttonNext.isEnabled = true
		self.buttonPrevious.isEnabled = true
	}
	
	private func disableButtons() {
		self.buttonPlay.isEnabled = false
		self.buttonNext.isEnabled = false
		self.buttonPrevious.isEnabled = false
	}
	
	private func loadCurrentSong(song: MPDSong?) {
		if let title = song?.title, let artist = song?.artist {
			self.labelCurrentSong.text = "\(title) - \(artist)"
		}
		else {
			self.labelCurrentSong.text = "No current song"
		}
	}
	
	// MARK: TableView Delegates
	
	func numberOfSections(in tableView: UITableView) -> Int {
		if self.currentPlaylist.count > 0 {
			self.tableViewSongs.separatorStyle = UITableViewCellSeparatorStyle.singleLine
			self.tableViewSongs.backgroundView = nil
			return 1
		}
		else {
			let size = self.tableViewSongs.bounds.size
			let labelMsg = UILabel.init(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: size.width, height: size.height)))

			labelMsg.text = "Empty playlist"
			labelMsg.textColor = self.COLOR_BLUE
			labelMsg.numberOfLines = 0
			labelMsg.textAlignment = NSTextAlignment.center
			labelMsg.font = UIFont.init(name: "Avenir", size: 20)
			labelMsg.sizeToFit()

			self.tableViewSongs.backgroundView = labelMsg
			self.tableViewSongs.separatorStyle = UITableViewCellSeparatorStyle.none
		}
		
		return 0
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.currentPlaylist.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "myCell", for: indexPath)
		
		let labelSongnr: UILabel = cell.viewWithTag(self.TAG_LABEL_SONGNR) as! UILabel
		labelSongnr.text = String(self.currentPlaylist[indexPath.row].track)
		
		let labelSongname: UILabel = cell.viewWithTag(self.TAG_LABEL_SONGNAME) as! UILabel
		labelSongname.text = self.currentPlaylist[indexPath.row].title
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return "Current Playlist"
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		MPD.sharedInstance.play(nr: indexPath.row) { 
			self.tableViewSongs.deselectRow(at: indexPath, animated: true)
			self.loadState()
		}
	}
}
