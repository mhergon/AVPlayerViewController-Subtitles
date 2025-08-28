//
//  ContentView.swift
//  Shared
//
//  Created by TungLim on 21/6/2022.
//  Copyright © 2022 Marc Hervera. All rights reserved.
//

import SwiftUI
import AVKit
import Combine

struct ContentView: View {
    @State private var currentTime: TimeInterval = 0
    @State private var currentText = ""
    
    private let timeObserver: PlayerTimeObserver
    private let avplayer: AVPlayer
    private let parser: Subtitles?

    
    init() {
        avplayer = AVPlayer(url:  Bundle.main.url(forResource: "trailer_720p", withExtension: "mov")!)
        parser = try? Subtitles(file: URL(fileURLWithPath: Bundle.main.path(forResource: "trailer_720p", ofType: "srt")!), encoding: .utf8)
        timeObserver = PlayerTimeObserver(player: avplayer)
    }
    
    var body: some View {
        VideoPlayer(player: avplayer) {
            VStack {
                Spacer()
                Text(currentText)
                    .foregroundColor(.white)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding()
                    .onReceive(timeObserver.publisher) { time in
                        currentText = parser?.searchSubtitles(at: time) ?? ""
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            avplayer.play()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


class PlayerTimeObserver {
  let publisher = PassthroughSubject<TimeInterval, Never>()
  private var timeObservation: Any?
  
  init(player: AVPlayer) {
    // Periodically observe the player's current time, whilst playing
    timeObservation = player.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 60), queue: nil) { [weak self] time in
      guard let self = self else { return }
      // Publish the new player time
      self.publisher.send(time.seconds)
    }
  }
}

