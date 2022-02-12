//
//  ViewController.swift
//  AVPlayerViewController-Subtitles
//
//  Created by mhergon on 23/12/15.
//  Copyright © 2015 mhergon. All rights reserved.
//

import UIKit
import AVKit

class ViewController: UIViewController {
    
    // MARK: - Actions
    
    @IBAction func showVideo(_ sender: UIButton) {
        // Video file
        let videoFile = Bundle.main.path(forResource: "trailer_720p", ofType: "mov")
                
        // Remote subtitle file
        let subtitleRemoteUrl = URL(string: "https://raw.githubusercontent.com/furkanhatipoglu/AVPlayerViewController-Subtitles/master/Example/AVPlayerViewController-Subtitles/trailer_720p.srt")
        
        // Movie player
        let moviePlayer = AVPlayerViewController()
        moviePlayer.player = AVPlayer(url: URL(fileURLWithPath: videoFile!))
        present(moviePlayer, animated: true, completion: nil)
        
//        // Local subtitle file
//        let subtitleFile = Bundle.main.path(forResource: "trailer_720p", ofType: "srt")
//        let subtitleURL = URL(fileURLWithPath: subtitleFile!)
//        
//        // Add subtitles - local
//        moviePlayer.addSubtitles().open(fileFromLocal: subtitleURL)
//        moviePlayer.addSubtitles().open(fileFromLocal: subtitleURL, encoding: .utf8)
        
        // Add subtitles - remote
        moviePlayer.addSubtitles()
        moviePlayer.open(fileFromRemote: subtitleRemoteUrl!)
        
        // Change text properties
        moviePlayer.subtitleLabel?.textColor = UIColor.red
        
        // Play
        moviePlayer.player?.play()
    }
    
    func subtitleParser() {
        // Subtitle file
        let subtitleFile = Bundle.main.path(forResource: "trailer_720p", ofType: "srt")
        let subtitleURL = URL(fileURLWithPath: subtitleFile!)
        
        // Subtitle parser
        let parser = try? Subtitles(file: subtitleURL, encoding: .utf8)
        
        // Do something with result
        _ = parser?.searchSubtitles(at: 2.0) // Search subtitle at 2.0 seconds
    }
    
}
