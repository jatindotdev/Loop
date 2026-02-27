import SwiftData
import SwiftUI

struct TrimEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var clip: ClipItem
    
    @State private var startSeconds: Double
    @State private var stopSeconds: Double
    @State private var maxSeconds: Double
    
    init(clip: ClipItem) {
        self.clip = clip
        let fullDurationMs = (clip.durationMs ?? 0) > 0 ? (clip.durationMs ?? 0) : clip.stopPositionMs
        let maxSec = max(Double(fullDurationMs) / 1000, 60)
        _startSeconds = State(initialValue: Double(clip.startPositionMs) / 1000)
        _stopSeconds = State(initialValue: Double(clip.stopPositionMs) / 1000)
        _maxSeconds = State(initialValue: maxSec)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        ArtworkView(
                            clip: clip,
                            isCurrentTrack: false,
                            isPaused: true,
                            size: 56,
                            cornerRadius: SpotifyDesign.artworkInOverlayCornerRadius
                        )
                        VStack(alignment: .leading, spacing: 4) {
                            Text(clip.trackName)
                                .font(SpotifyDesign.headlineFont())
                                .foregroundColor(.white)
                            Text(clip.artistName)
                                .font(SpotifyDesign.bodyFont())
                                .foregroundColor(SpotifyDesign.secondaryText)
                        }
                        Spacer()
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: SpotifyDesign.tileCornerRadius, style: .continuous)
                            .fill(SpotifyDesign.glassMaterial)
                    )
                } header: {
                    Text("Track")
                        .foregroundColor(SpotifyDesign.secondaryText)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Start")
                                .frame(width: 50, alignment: .leading)
                            Slider(value: $startSeconds, in: 0...maxSeconds, step: 1)
                            Text(formatTime(Int(startSeconds)))
                                .frame(width: 45, alignment: .trailing)
                                .font(.caption.monospacedDigit())
                        }
                        
                        HStack {
                            Text("Stop")
                                .frame(width: 50, alignment: .leading)
                            Slider(value: $stopSeconds, in: 0...maxSeconds, step: 1)
                            Text(formatTime(Int(stopSeconds)))
                                .frame(width: 45, alignment: .trailing)
                                .font(.caption.monospacedDigit())
                        }
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: SpotifyDesign.tileCornerRadius, style: .continuous)
                            .fill(SpotifyDesign.glassMaterial)
                    )
                } header: {
                    Text("Trim Range")
                        .foregroundColor(SpotifyDesign.secondaryText)
                } footer: {
                    Text("Preview by playing the track from the Loop Deck.")
                        .foregroundColor(SpotifyDesign.muted)
                }
            }
            .scrollContentBackground(.hidden)
            .background(SpotifyDesign.background)
            .tint(SpotifyDesign.green)
            .navigationTitle("Edit Trim")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(SpotifyDesign.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveAndDismiss()
                    }
                }
            }
            .onChange(of: startSeconds) { _, newValue in
                if newValue >= stopSeconds {
                    stopSeconds = min(newValue + 1, maxSeconds)
                }
            }
            .onChange(of: stopSeconds) { _, newValue in
                if newValue <= startSeconds {
                    startSeconds = max(newValue - 1, 0)
                }
            }
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
    
    private func saveAndDismiss() {
        clip.startPositionMs = Int(startSeconds * 1000)
        clip.stopPositionMs = Int(stopSeconds * 1000)
        dismiss()
    }
}
