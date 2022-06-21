//
//  VideoPlayerApp.swift
//  Shared
//
//  Created by TungLim on 21/6/2022.
//  Copyright © 2022 Marc Hervera. All rights reserved.
//

import SwiftUI

@main
struct VideoPlayerApp: App {
    var body: some Scene {
        WindowGroup {
#if os(macOS)
            // use min wi & he to make the start screen 800 & 1000 and make max wi & he to infinity to make screen expandable when user stretch the screen
            ContentView().frame(minWidth: 800, maxWidth: .infinity, minHeight: 600, maxHeight: .infinity, alignment: .center)
#else
            ContentView()
#endif
        }
    }
}
