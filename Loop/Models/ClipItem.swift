import Foundation
import SwiftData

@Model
final class ClipItem: Identifiable {
    var id: UUID
    var spotifyURI: String
    var trackName: String
    var artistName: String
    var startPositionMs: Int
    var stopPositionMs: Int
    
    var durationMs: Int?
    var order: Int
    
    init(
        id: UUID = UUID(),
        spotifyURI: String,
        trackName: String,
        artistName: String,
        startPositionMs: Int = 0,
        stopPositionMs: Int,
        durationMs: Int? = nil,
        order: Int
    ) {
        self.id = id
        self.spotifyURI = spotifyURI
        self.trackName = trackName
        self.artistName = artistName
        self.startPositionMs = startPositionMs
        self.stopPositionMs = stopPositionMs
        self.durationMs = durationMs
        self.order = order
    }
    
    var startPositionSeconds: Int {
        get { startPositionMs / 1000 }
        set { startPositionMs = newValue * 1000 }
    }
    
    var stopPositionSeconds: Int {
        get { stopPositionMs / 1000 }
        set { stopPositionMs = newValue * 1000 }
    }
    
    var trimRangeDisplay: String {
        let start = formatTime(startPositionMs)
        let stop = formatTime(stopPositionMs)
        return "\(start) – \(stop)"
    }
    
    private func formatTime(_ ms: Int) -> String {
        let totalSeconds = ms / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
