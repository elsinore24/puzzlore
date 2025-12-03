//
//  VideoBackgroundView.swift
//  Puzzlore
//
//  Created by Daniel Merryman on 11/29/25.
//

import SwiftUI
import AVKit

/// A looping video background view with optional crossfade transition
struct VideoBackgroundView: UIViewRepresentable {
    let videoName: String
    let videoExtension: String
    let crossfadeDuration: Double

    init(videoName: String, videoExtension: String = "mp4", crossfadeDuration: Double = 1.0) {
        self.videoName = videoName
        self.videoExtension = videoExtension
        self.crossfadeDuration = crossfadeDuration
    }

    func makeUIView(context: Context) -> CrossfadeVideoPlayerView {
        CrossfadeVideoPlayerView(videoName: videoName, videoExtension: videoExtension, crossfadeDuration: crossfadeDuration)
    }

    func updateUIView(_ uiView: CrossfadeVideoPlayerView, context: Context) {
        // No updates needed
    }
}

/// A view that plays video with crossfade looping using two alternating players
/// The bottom layer always stays at full opacity; only the top layer fades in/out
/// This prevents color skewing during the crossfade
class CrossfadeVideoPlayerView: UIView {
    private var playerA: AVPlayer?
    private var playerB: AVPlayer?
    private var layerA: AVPlayerLayer?
    private var layerB: AVPlayerLayer?
    private var isPlayerAOnTop = true  // Track which layer is on top
    private var videoURL: URL?
    private var videoDuration: Double = 0
    private var crossfadeDuration: Double = 1.0
    private var timeObserver: Any?
    private var timeObserverPlayer: AVPlayer?  // Track which player owns the time observer
    private var endObserverA: NSObjectProtocol?
    private var endObserverB: NSObjectProtocol?
    private var isInCrossfade = false

    init(videoName: String, videoExtension: String, crossfadeDuration: Double) {
        super.init(frame: .zero)
        self.crossfadeDuration = crossfadeDuration
        backgroundColor = .clear
        setupPlayers(videoName: videoName, videoExtension: videoExtension)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupPlayers(videoName: String, videoExtension: String) {
        guard let url = Bundle.main.url(forResource: videoName, withExtension: videoExtension) else {
            print("⚠️ Video not found: \(videoName).\(videoExtension)")
            return
        }

        self.videoURL = url
        print("✅ Video found at: \(url)")

        // Create player A
        let itemA = AVPlayerItem(url: url)
        playerA = AVPlayer(playerItem: itemA)
        playerA?.isMuted = true

        layerA = AVPlayerLayer(player: playerA)
        layerA?.videoGravity = .resizeAspectFill
        layerA?.frame = bounds
        layerA?.opacity = 1  // Bottom layer, always visible
        layer.addSublayer(layerA!)

        // Create player B
        let itemB = AVPlayerItem(url: url)
        playerB = AVPlayer(playerItem: itemB)
        playerB?.isMuted = true

        layerB = AVPlayerLayer(player: playerB)
        layerB?.videoGravity = .resizeAspectFill
        layerB?.frame = bounds
        layerB?.opacity = 0  // Top layer, starts hidden
        layer.addSublayer(layerB!)

        // A is on bottom (playing), B is on top (hidden)
        isPlayerAOnTop = false

        // Get video duration
        let asset = AVAsset(url: url)
        Task {
            do {
                let duration = try await asset.load(.duration)
                let durationSeconds = CMTimeGetSeconds(duration)
                await MainActor.run {
                    self.videoDuration = durationSeconds
                    self.startPlayback()
                }
            } catch {
                print("⚠️ Could not load duration: \(error)")
                await MainActor.run {
                    self.playerA?.play()
                }
            }
        }
    }

    private func startPlayback() {
        guard videoDuration > 0, let playerA = playerA else { return }

        // Set up time observer on player A
        let interval = CMTime(seconds: 0.03, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = playerA.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.handleTimeUpdateA(time)
        }
        timeObserverPlayer = playerA

        // Set up end observer for player A
        endObserverA = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerA.currentItem,
            queue: .main
        ) { [weak self] _ in
            self?.handlePlayerAEnded()
        }

        // Set up end observer for player B
        if let playerB = playerB {
            endObserverB = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: playerB.currentItem,
                queue: .main
            ) { [weak self] _ in
                self?.handlePlayerBEnded()
            }
        }

        playerA.play()
        print("✅ Video playback started with crossfade looping")
    }

    private func handleTimeUpdateA(_ time: CMTime) {
        let currentTime = CMTimeGetSeconds(time)
        let crossfadeStart = videoDuration - crossfadeDuration

        guard crossfadeStart > 0 else { return }

        // A is playing on bottom, B will fade in on top
        if currentTime >= crossfadeStart && !isInCrossfade {
            isInCrossfade = true
            // Start B at beginning and begin fading it in
            playerB?.seek(to: .zero)
            playerB?.play()
        }

        if currentTime >= crossfadeStart {
            let progress = (currentTime - crossfadeStart) / crossfadeDuration
            let clampedProgress = Float(min(1.0, max(0.0, progress)))

            // Fade in B on top (A stays at full opacity underneath)
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            layerB?.opacity = clampedProgress
            CATransaction.commit()
        }
    }

    private func handleTimeUpdateB(_ time: CMTime) {
        let currentTime = CMTimeGetSeconds(time)
        let crossfadeStart = videoDuration - crossfadeDuration

        guard crossfadeStart > 0 else { return }

        // B is playing on bottom, A will fade in on top
        if currentTime >= crossfadeStart && !isInCrossfade {
            isInCrossfade = true
            // Start A at beginning and begin fading it in
            playerA?.seek(to: .zero)
            playerA?.play()
        }

        if currentTime >= crossfadeStart {
            let progress = (currentTime - crossfadeStart) / crossfadeDuration
            let clampedProgress = Float(min(1.0, max(0.0, progress)))

            // Fade in A on top (B stays at full opacity underneath)
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            layerA?.opacity = clampedProgress
            CATransaction.commit()
        }
    }

    private func handlePlayerAEnded() {
        // A finished, B should now be fully visible on top
        // Move A to top (hidden), B to bottom (visible)
        isInCrossfade = false

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layerA?.opacity = 0
        layerB?.opacity = 1
        CATransaction.commit()

        // Reorder layers: A on top, B on bottom
        layerA?.removeFromSuperlayer()
        layer.addSublayer(layerA!)
        isPlayerAOnTop = true

        // Switch time observer to B
        if let observer = timeObserver, let ownerPlayer = timeObserverPlayer {
            ownerPlayer.removeTimeObserver(observer)
        }
        let interval = CMTime(seconds: 0.03, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = playerB?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.handleTimeUpdateB(time)
        }
        timeObserverPlayer = playerB
    }

    private func handlePlayerBEnded() {
        // B finished, A should now be fully visible on top
        // Move B to top (hidden), A to bottom (visible)
        isInCrossfade = false

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layerB?.opacity = 0
        layerA?.opacity = 1
        CATransaction.commit()

        // Reorder layers: B on top, A on bottom
        layerB?.removeFromSuperlayer()
        layer.addSublayer(layerB!)
        isPlayerAOnTop = false

        // Switch time observer to A
        if let observer = timeObserver, let ownerPlayer = timeObserverPlayer {
            ownerPlayer.removeTimeObserver(observer)
        }
        let interval = CMTime(seconds: 0.03, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = playerA?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.handleTimeUpdateA(time)
        }
        timeObserverPlayer = playerA
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layerA?.frame = bounds
        layerB?.frame = bounds
    }

    deinit {
        // Remove time observer from the correct player
        if let observer = timeObserver, let ownerPlayer = timeObserverPlayer {
            ownerPlayer.removeTimeObserver(observer)
        }
        timeObserver = nil
        timeObserverPlayer = nil

        if let observer = endObserverA {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = endObserverB {
            NotificationCenter.default.removeObserver(observer)
        }
        playerA?.pause()
        playerB?.pause()
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        VideoBackgroundView(videoName: "agon_bg_video", crossfadeDuration: 1.5)
            .ignoresSafeArea()

        Text("Video Background")
            .font(.largeTitle)
            .foregroundColor(.white)
    }
}
