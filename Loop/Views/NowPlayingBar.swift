//
//  NowPlayingBar.swift
//  Loop
//
//  Spotify-style now playing bar
//

import SwiftUI

struct NowPlayingBar: View {
    @ObservedObject var playbackController: PlaybackController
    @ObservedObject var spotifyService = SpotifyService.shared
    
    var body: some View {
        if let clip = playbackController.currentClip {
            let rawPositionMs = spotifyService.currentPlayerState?.playbackPositionMs ?? 0
            let positionMs = max(rawPositionMs, clip.startPositionMs)
            let durationMs = spotifyService.currentPlayerState?.durationMs ?? clip.stopPositionMs
            let isPaused = spotifyService.currentPlayerState?.isPaused ?? true
            
            VStack(spacing: 0) {
                VStack(spacing: 4) {
                    SmoothTrimSeekBar(
                        clip: clip,
                        positionMs: positionMs,
                        durationMs: durationMs,
                        isPaused: isPaused
                    )
                    .frame(height: 4)
                    .padding(.horizontal, 16)
                    
                    HStack {
                        Text(formatTime(positionMs))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(SpotifyDesign.secondaryText)
                        Spacer()
                        Text(formatTime(durationMs))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(SpotifyDesign.secondaryText)
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.top, 8)
                
                HStack(spacing: 12) {
                    ArtworkView(
                        clip: clip,
                        isCurrentTrack: true,
                        isPaused: isPaused,
                        size: 48,
                        cornerRadius: SpotifyDesign.artworkInOverlayCornerRadius,
                        showPlayOverlay: false
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(clip.trackName)
                            .font(SpotifyDesign.headlineFont())
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Text(clip.artistName)
                            .font(SpotifyDesign.captionFont())
                            .foregroundColor(SpotifyDesign.secondaryText)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Button {
                        playbackController.playPrevious()
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }
                    .disabled(!playbackController.canGoPrevious)
                    .opacity(playbackController.canGoPrevious ? 1 : 0.4)

                    Button {
                        playbackController.togglePlayPause()
                    } label: {
                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }

                    Button {
                        playbackController.playNext()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }
                    .disabled(!playbackController.canGoNext)
                    .opacity(playbackController.canGoNext ? 1 : 0.4)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: SpotifyDesign.overlayCornerRadius,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: SpotifyDesign.overlayCornerRadius
                )
            )
            .background(
                UnevenRoundedRectangle(
                    topLeadingRadius: SpotifyDesign.overlayCornerRadius,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: SpotifyDesign.overlayCornerRadius
                )
                .fill(SpotifyDesign.glassMaterialElevated)
                .ignoresSafeArea(edges: .bottom)
            )
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: -2)
            .safeAreaPadding(.bottom)
        }
    }
    
    private func formatTime(_ ms: Int) -> String {
        let totalSeconds = ms / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Smooth Trim Seek Bar

struct SmoothTrimSeekBar: View {
    let clip: ClipItem
    let positionMs: Int
    let durationMs: Int
    let isPaused: Bool
    
    @State private var lastKnownPositionMs: Double = 0
    @State private var lastSyncTime: Date = .now
    /// Only interpolate once playback has progressed past start (avoids stutter when seek completes)
    private let interpolationThresholdMs = 150
    
    private var barHeight: CGFloat { 4 }
    
    private var playbackHasStarted: Bool {
        !isPaused && lastKnownPositionMs >= Double(clip.startPositionMs + interpolationThresholdMs)
    }
    
    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.05)) { context in
            let displayMs: Double = {
                if isPaused || !playbackHasStarted {
                    return lastKnownPositionMs
                }
                let elapsed = context.date.timeIntervalSince(lastSyncTime)
                return min(lastKnownPositionMs + elapsed * 1000, Double(max(durationMs, 1)))
            }()
            
            GeometryReader { geo in
                let width = geo.size.width
                let duration = max(durationMs, 1)
                let position = min(displayMs, Double(duration))
                
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: barHeight)
                    
                    let startX = width * CGFloat(clip.startPositionMs) / CGFloat(duration)
                    let stopX = width * CGFloat(clip.stopPositionMs) / CGFloat(duration)
                    Capsule()
                        .fill(SpotifyDesign.green.opacity(0.6))
                        .frame(width: max(0, stopX - startX), height: barHeight)
                        .offset(x: startX)
                    
                    let positionX = width * CGFloat(position) / CGFloat(duration)
                    Circle()
                        .fill(SpotifyDesign.green)
                        .frame(width: 10, height: 10)
                        .offset(x: positionX - 5)
                }
            }
        }
        .onChange(of: positionMs) { _, newValue in
            Task { @MainActor in
                lastKnownPositionMs = Double(newValue)
                lastSyncTime = .now
            }
        }
        .onChange(of: isPaused) { _, paused in
            if paused {
                Task { @MainActor in
                    lastKnownPositionMs = Double(positionMs)
                }
            }
        }
        .onAppear {
            lastKnownPositionMs = Double(positionMs)
            lastSyncTime = .now
        }
    }
}
