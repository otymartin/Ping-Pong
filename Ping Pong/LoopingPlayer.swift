//
//  LoopingPlayer.swift
//  The Bounce
//
//  Created by Martin Otyeka on 2022-06-05.
//

import UIKit
import SwiftUI
import Combine
import AVFoundation


final class LoopingPlayer: AVPlayer {
    private var cancellable: AnyCancellable?

    /**
    Loop the playback.
    */
    var loopPlayback = false {
        didSet {
            updateObserver()
        }
    }

    /**
    Bounce the playback.
    */
    var bouncePlayback = false {
        didSet {
            updateObserver()

            if !bouncePlayback, rate == -1 {
                rate = 1
            }
        }
    }

    override func replaceCurrentItem(with item: AVPlayerItem?) {
        super.replaceCurrentItem(with: item)
        cancellable = nil
        updateObserver()
    }

    private func updateObserver() {
        guard bouncePlayback || loopPlayback else {
            cancellable = nil
            actionAtItemEnd = .pause
            return
        }

        actionAtItemEnd = .none

        guard cancellable == nil else {
            // Already observing. No need to update.
            return
        }

        cancellable = NotificationCenter.default
            .publisher(for: .AVPlayerItemDidPlayToEndTime, object: currentItem)
            .sink { [weak self] _ in
                guard let self = self else {
                    return
                }
                
//                self.pause()
                
                if
                    self.bouncePlayback,
                    self.currentItem?.canPlayReverse == true,
                    self.currentTime().seconds > self.currentItem?.playbackRange?.lowerBound ?? 0
                {
                    print("👉 Seek to End")
                    self.seekToEnd()
                    self.rate = -1
                } else if self.loopPlayback {
                    print("👉 Seek to Start")
                    self.seekToStart()
                    self.rate = 1.5
                }
            }
    }
}
