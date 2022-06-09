//
//  VideoStore.swift
//  Ping Pong
//
//  Created by Martin Otyeka on 2022-06-08.
//

import AVKit
import Files
import AVFoundation

@MainActor
final class Theater: ObservableObject {
    
    @Published var player: AVPlayer?
    
    init() {
        Task { await play() }
    }
}

extension Theater {
    
    func play() async {
        guard let resource = Bundle.main.url(forResource: "penalty", withExtension: "mov") else {
            print("🐝 No Resource Found")
            return
        }

        do {
            let originalAsset = AVAsset(url: resource)
            let outputURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                .appendingPathComponent("pingpong2")
                .appendingPathExtension("mov")
            let reversedAsset = try await reverse(originalAsset, outputURL: outputURL)
            VideoManager.shared.merge(arrayVideos: [originalAsset, reversedAsset]) { url, error in
                if let error = error {
                    print("🐝 Merge Error \(error)")
                } else {
                    guard let url = url else {
                        print("🐝 No Merge URL")
                        return
                    }
                    DispatchQueue.main.async {
                        let looper = LoopingPlayer(url: url)
                        looper.loopPlayback = true
                        self.player = looper
                        self.player?.rate = 1.5
                    }
                }
            }

        } catch {
            print("🐝 Reverse Asset Failed")
            print(error)
        }
    }
}

/// Archived Original Article by Andy Hin:
/// `Reversing videos efficiently with AVFoundation`
/// https://web.archive.org/web/20180819140015/http://www.andyhin.com/
private extension Theater {
    
    func reverse(_ original: AVAsset, outputURL: URL) async throws -> AVAsset {
        
        /// Initialize the reader
        ///     - First, we initialize the AVAssetReader object that will be used to read in the video as a series   of samples (frames). We also configure the pixel format for the frame. You can read more about     the different pixel format types here:
        /// -       https://web.archive.org/web/20180819140015/https://developer.apple.com/library/mac/documentation/QuartzCore/Reference/CVPixelFormatDescriptionRef/index.html#//apple_ref/doc/constant_group/Pixel_Format_Types.
        let reader: AVAssetReader
        do {
            reader = try AVAssetReader(asset: original)
        } catch {
            print(error)
            throw error
        }
        
        guard let videoTrack = original.tracks(withMediaType: .video).last else {
            print("No video track")
            throw NSError()
        }
        
        let readerOutputSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
        let readerOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: readerOutputSettings)
        reader.add(readerOutput)
        
        reader.startReading()
        
        
        /// Read in the samples
        ///     - Next, we store the array of samples. Note that because CMSampleBufferRef is a native C type, we cast it to an objective-c type of id using __bridge.
        var samples: [CMSampleBuffer] = []
        while let sample = readerOutput.copyNextSampleBuffer() {
            samples.append(sample)
        }
        
        /// Initialize the writer
        ///     - This part is pretty straightforward, the AVAssetWriter object takes in an output path and the file-type of the output file.
        let writer: AVAssetWriter
        do {
            writer = try AVAssetWriter(outputURL: outputURL, fileType: .mov)
        } catch let error {
            fatalError(error.localizedDescription)
        }

        let videoCompositionProps = [AVVideoAverageBitRateKey: videoTrack.estimatedDataRate]
                let writerOutputSettings = [
                    AVVideoCodecKey: AVVideoCodecType.h264,
                    AVVideoWidthKey: videoTrack.naturalSize.width,
                    AVVideoHeightKey: videoTrack.naturalSize.height,
                    AVVideoCompressionPropertiesKey: videoCompositionProps
                    ] as [String : Any]
                
        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: writerOutputSettings)
        writerInput.expectsMediaDataInRealTime = false
        writerInput.transform = videoTrack.preferredTransform
                
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: nil)
        
        writer.add(writerInput)
        writer.startWriting()
        writer.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(samples.first!))
        
        for (index, sample) in samples.enumerated() {
            let presentationTime = CMSampleBufferGetPresentationTimeStamp(sample)
            let imageBufferRef = CMSampleBufferGetImageBuffer(samples[samples.count - 1 - index])
            while !writerInput.isReadyForMoreMediaData {
                Thread.sleep(forTimeInterval: 0.1)
            }
            pixelBufferAdaptor.append(imageBufferRef!, withPresentationTime: presentationTime)
            
        }
        
        await writer.finishWriting()
        return AVAsset(url: outputURL)
    }
}
