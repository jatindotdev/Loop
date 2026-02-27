import Combine
import Foundation
import SwiftData
import SwiftUI

@MainActor
final class PlaybackController: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    @Published private(set) var currentClipIndex: Int?
    @Published private(set) var isPlaying = false
    
    private let spotifyService = SpotifyService.shared
    private var clips: [ClipItem] = []
    private var modelContext: ModelContext?
    private var hasReachedStop = false
    private let stopBufferMs = 500
    
    init() {
        SpotifyService.shared.$currentPlayerState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.syncPlayingState()
                    self?.checkPositionAndAdvance()
                }
            }
            .store(in: &cancellables)
    }
    
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func loadClips(_ clips: [ClipItem]) {
        self.clips = clips.sorted { $0.order < $1.order }
    }
    
    func playFromIndex(_ index: Int) {
        guard index >= 0, index < clips.count else { return }
        guard spotifyService.isConnected else { return }
        
        let clip = clips[index]
        currentClipIndex = index
        isPlaying = true
        hasReachedStop = false
        
        spotifyService.play(uri: clip.spotifyURI)
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            Task { @MainActor in
                self?.spotifyService.seekToPosition(clip.startPositionMs)
            }
        }
    }
    
    func playNext() {
        guard let index = currentClipIndex else { return }
        let nextIndex = index + 1
        if nextIndex < clips.count {
            playFromIndex(nextIndex)
        } else {
            
            stop()
        }
    }

    func playPrevious() {
        guard let index = currentClipIndex else { return }
        if index > 0 {
            playFromIndex(index - 1)
        } else {
            
            playFromIndex(0)
        }
    }

    var canGoNext: Bool {
        guard let index = currentClipIndex else { return false }
        return index + 1 < clips.count
    }

    var canGoPrevious: Bool {
        currentClipIndex != nil && !clips.isEmpty
    }
    
    func stop() {
        currentClipIndex = nil
        isPlaying = false
        spotifyService.pause()
    }
    
    func togglePlayPause() {
        guard let state = spotifyService.currentPlayerState else { return }
        if state.isPaused {
            spotifyService.resume()
            isPlaying = true
        } else {
            spotifyService.pause()
            isPlaying = false
        }
    }
    
    func syncPlayingState() {
        if let state = spotifyService.currentPlayerState, currentClipIndex != nil {
            isPlaying = !state.isPaused
        }
    }
    
    func checkPositionAndAdvance() {
        guard isPlaying, let index = currentClipIndex, index < clips.count else { return }
        guard let state = spotifyService.currentPlayerState else { return }
        
        let clip = clips[index]
        
        
        if state.playbackPositionMs >= clip.stopPositionMs - stopBufferMs {
            if !hasReachedStop {
                hasReachedStop = true
                spotifyService.pause()
                playNext()
            }
        }
    }
    
    var currentClip: ClipItem? {
        guard let index = currentClipIndex, index < clips.count else { return nil }
        return clips[index]
    }
    
    var isSpotifyPaused: Bool {
        spotifyService.currentPlayerState?.isPaused ?? true
    }
}
