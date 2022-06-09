//
//  ContentView.swift
//  Ping Pong
//
//  Created by Martin Otyeka on 2022-06-08.
//

import AVKit
import SwiftUI
import AVFoundation


struct ContentView: View {

    @StateObject var theater: Theater

    init() {
        _theater = StateObject(wrappedValue: Theater())
    }

    var body: some View {
        GeometryReader { geometry in
            if let player = theater.player {
                VideoPlayer(player: player)
                    .frame(width: geometry.size.width, height: geometry.size.width)
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


