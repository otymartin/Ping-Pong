//
//  AVFoundationExtensions.swift
//  The Bounce
//
//  Created by Martin Otyeka on 2022-06-05.
//

import Combine
import SwiftUI
import AVFoundation

extension AVPlayer {
    /**
    Seek to the start of the playable range of the video.

    The start might not be at `0` if, for example, the video has been trimmed in `AVPlayerView` trim mode.
    */
    func seekToStart() {
        let seconds = currentItem?.playbackRange?.lowerBound ?? 0

        seek(to: CMTime(seconds: seconds, preferredTimescale: .video),
             toleranceBefore: .zero,
             toleranceAfter: .zero)
    }

    /**
    Seek to the end of the playable range of the video.

    The start might not be at `duration` if, for example, the video has been trimmed in `AVPlayerView` trim mode.
    */
    func seekToEnd() {
        guard let seconds = currentItem?.playbackRange?.upperBound ?? currentItem?.duration.seconds else {
            return
        }
        seek(to: CMTime(seconds: seconds, preferredTimescale: .video),
            toleranceBefore: .zero,
            toleranceAfter: .zero)
    }
}

extension AVPlayerItem {
    /**
    The duration range of the item.

    Can be `nil` when the `.duration` is not available, for example, when the asset has not yet been fully loaded or if it's a live stream.
    */
    var durationRange: ClosedRange<Double>? { duration.durationRange }

    /**
    The playable range of the item.

    Can be `nil` when the `.duration` is not available, for example, when the asset has not yet been fully loaded or if it's a live stream. Or if the user is dragging the trim handle of a video.
    */
    var playbackRange: ClosedRange<Double>? {
        get {
            // These are not available while the user is dragging the video trim handle of `AVPlayerView`.
            guard
                reversePlaybackEndTime.isNumeric,
                forwardPlaybackEndTime.isNumeric
            else {
                return nil
            }

            let startTime = reversePlaybackEndTime.seconds
            let endTime = forwardPlaybackEndTime.seconds
            
            print("Start: \(startTime)")
            print("Start: \(endTime)")

            return .fromGraceful(startTime, endTime)
        }
        set {
            guard let range = newValue else {
                return
            }

            forwardPlaybackEndTime = CMTime(seconds: range.upperBound, preferredTimescale: .video)
            reversePlaybackEndTime = CMTime(seconds: range.lowerBound, preferredTimescale: .video)
        }
    }
}

extension CMTimeScale {
    /**
    Apple-recommended scale for video.

    ```
    CMTime(seconds: (1 / fps), preferredTimescale: .video)
    ```
    */
    static let video: Self = 600
}

extension CMTime {
    /**
    Get the `CMTime` as a duration from zero to the seconds value of `self`.

    Can be `nil` when the `.duration` is not available, for example, when an asset has not yet been fully loaded or if it's a live stream.
    */
    var durationRange: ClosedRange<Double>? {
        guard isNumeric else {
            return nil
        }

        return 0...seconds
    }
}

extension ClosedRange {
    /**
    Create a `ClosedRange` where it does not matter which bound is upper and lower.

    Using a range literal would hard crash if the lower bound is higher than the upper bound.
    */
    static func fromGraceful(_ bound1: Bound, _ bound2: Bound) -> Self {
        bound1 <= bound2 ? bound1...bound2 : bound2...bound1
    }
}
