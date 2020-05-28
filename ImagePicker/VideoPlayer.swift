//
//  ActivityIndicator.swift
//  ImagePickerMacOSDemo
//
//  Created by Jerry Wong on 2020/5/1.
//  Copyright © 2020 com.jerry. All rights reserved.
//

import SwiftUI
import AVKit

public struct VideoPlayer {

    var playerItem: AVPlayerItem

    var showsPlaybackControls: Bool = true

    var allowsPictureInPicturePlayback:Bool = true

    var isMuted: Binding<Bool>

    var videoGravity: AVLayerVideoGravity = .resizeAspect

    var loop: Binding<Bool> = .constant(false)

    var isPlaying: Binding<Bool>

    public init(item: AVPlayerItem, playing: Binding<Bool> = .constant(true), muted: Binding<Bool> = .constant(false)) {
        playerItem = item
        isPlaying = playing
        isMuted = muted
    }
}

#if os(iOS)
extension VideoPlayer: SwiftUIViewControllerRepresentable {
    
    public func makeUIViewController(context: Context) -> AVPlayerViewController {
        let videoViewController = AVPlayerViewController()
        videoViewController.player = AVPlayer(playerItem: playerItem)

        let videoCoordinator = context.coordinator
        videoCoordinator.player = videoViewController.player
        videoCoordinator.item = playerItem

        return videoViewController
    }

    public func updateUIViewController(_ videoViewController: AVPlayerViewController, context: Context) {
        if playerItem != context.coordinator.item {
            videoViewController.player = AVPlayer(playerItem: playerItem)
            context.coordinator.player = videoViewController.player
            context.coordinator.item = playerItem
        }
        videoViewController.showsPlaybackControls = showsPlaybackControls
        videoViewController.allowsPictureInPicturePlayback = allowsPictureInPicturePlayback
        videoViewController.player?.isMuted = isMuted.wrappedValue
        videoViewController.videoGravity = videoGravity
        context.coordinator.togglePlay(isPlaying: isPlaying.wrappedValue)
    }

    public func makeCoordinator() -> VideoCoordinator {
        return VideoCoordinator(videoPlayer: self)
    }
}
#elseif os(macOS)
extension VideoPlayer: SwiftUIViewRepresentable {

    public func makeNSView(context: Context) -> AVPlayerView {
        let videoView = AVPlayerView()
        videoView.player = AVPlayer(playerItem: playerItem)

        let videoCoordinator = context.coordinator
        videoCoordinator.player = videoView.player
        videoCoordinator.item = playerItem

        return videoView
    }

    public func updateNSView(_ videoView: AVPlayerView, context: Context) {
        if playerItem != context.coordinator.item {
            videoView.player = AVPlayer(playerItem: playerItem)
            context.coordinator.player = videoView.player
            context.coordinator.item = playerItem
        }
        if showsPlaybackControls {
            videoView.controlsStyle = .inline
        } else {
            videoView.controlsStyle = .none
        }
        if #available(OSX 10.15, *) {
            videoView.allowsPictureInPicturePlayback = allowsPictureInPicturePlayback
        } else {
            // Fallback on earlier versions
        }
        videoView.player?.isMuted = isMuted.wrappedValue
        videoView.player?.volume = isMuted.wrappedValue ? 0 : 1
        videoView.videoGravity = videoGravity
        context.coordinator.togglePlay(isPlaying: isPlaying.wrappedValue)
    }

    public func makeCoordinator() -> VideoCoordinator {
        return VideoCoordinator(videoPlayer: self)
    }
}
#endif

extension VideoPlayer {
    
    public class VideoCoordinator: NSObject {

        var playerContext = "playerContext"

        let videoPlayer: VideoPlayer

        var timeObserver: Any?

        var player: AVPlayer? {
            didSet {
                removeTimeObserver(from: oldValue)
                removeKVOObservers(from: oldValue)

                addTimeObserver(to: player)
                addKVOObservers(to: player)

                NotificationCenter.default.addObserver(self,
                                                       selector:#selector(VideoPlayer.VideoCoordinator.playerItemDidReachEnd),
                                                       name:.AVPlayerItemDidPlayToEndTime,
                                                       object:player?.currentItem)


            }
        }

        private func addTimeObserver(to player: AVPlayer?) {
            timeObserver = player?.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 4), queue: nil, using: { [weak self](time) in
                self?.updateStatus()
            })
        }

        private func removeTimeObserver(from player: AVPlayer?) {
            if let timeObserver = timeObserver {
                player?.removeTimeObserver(timeObserver)
            }
        }

        private func removeKVOObservers(from player: AVPlayer?) {
            player?.removeObserver(self, forKeyPath: "muted")
            player?.removeObserver(self, forKeyPath: "volume")
        }

        private func addKVOObservers(to player: AVPlayer?) {
            player?.addObserver(self, forKeyPath: "muted",
                                   options: [.new, .old],
                                   context:&playerContext)

            player?.addObserver(self, forKeyPath: "volume",
            options: [.new, .old],
            context:&playerContext)
        }
        
        var item: AVPlayerItem?

        init(videoPlayer: VideoPlayer){
            self.videoPlayer = videoPlayer
            super.init()
        }

        deinit {
            player?.pause()
            removeTimeObserver(from: player)
            removeKVOObservers(from: player)
        }

        @objc public func playerItemDidReachEnd(notification: NSNotification) {
            if videoPlayer.loop.wrappedValue {
                player?.seek(to: .zero)
                player?.play()
            } else {
                videoPlayer.isPlaying.wrappedValue = false
            }
        }

        @objc public func updateStatus() {
            if let player = player {
                videoPlayer.isPlaying.wrappedValue = player.rate > 0
            } else {
                videoPlayer.isPlaying.wrappedValue = false
            }
        }

        func togglePlay(isPlaying: Bool) {
            if isPlaying {
                if player?.currentItem?.duration == player?.currentTime() {
                    player?.seek(to: .zero)
                    player?.play()
                }
                player?.play()
            } else {
                player?.pause()
            }
        }

        override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {

            // Only handle observations for the playerContext
            guard context == &(playerContext), keyPath == "muted" || keyPath == "volume" else {
                super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
                return
            }
            if let player = player {
                #if os(macOS)
                videoPlayer.isMuted.wrappedValue = player.volume == 0
                #else
                videoPlayer.isMuted.wrappedValue = player.isMuted
                #endif
            }
        }
    }
}
// MARK: - Modifiers
extension VideoPlayer {

    public func pictureInPicturePlayback(_ value:Bool) -> VideoPlayer {
        var new = self
        new.allowsPictureInPicturePlayback = value
        return new
    }

    public func playbackControls(_ value: Bool) ->VideoPlayer {
        var new = self
        new.showsPlaybackControls = value
        return new
    }

    public func isMuted(_ value: Bool) -> VideoPlayer {
        return isMuted(.constant(value))
    }

    public func isMuted(_ value: Binding<Bool>) -> VideoPlayer {
        var new = self
        new.isMuted = value
        return new
    }

    public func isPlaying(_ value: Bool) -> VideoPlayer {
        let new = self
        new.isPlaying.wrappedValue = value
        return new
    }

    public func isPlaying(_ value: Binding<Bool>) -> VideoPlayer {
        var new = self
        new.isPlaying = value
        return new
    }

    public func videoGravity(_ value: AVLayerVideoGravity) -> VideoPlayer {
        var new = self
        new.videoGravity = value
        return new
    }

    public func loop(_ value: Bool) -> VideoPlayer {
        self.loop.wrappedValue = value
        return self
    }

    public func loop(_ value: Binding<Bool>) -> VideoPlayer {
        var new = self
        new.loop = value
        return new
    }
}
