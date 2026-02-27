//
//  AddTrackView.swift
//  Loop
//
//  Add track by Spotify URI
//

import SwiftData
import SpotifyiOS
import SwiftUI

struct AddTrackView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var toastStore = ToastStore.shared
    
    @State private var uriInput = ""
    @State private var isAdding = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("Paste Spotify URI or link", text: $uriInput)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: SpotifyDesign.buttonCornerRadius, style: .continuous)
                            .fill(SpotifyDesign.glassMaterial)
                    )
                    .foregroundColor(.white)
                
                Spacer(minLength: 0)
            }
            .overlay(alignment: .top) {
                ToastOverlay(toastStore: toastStore)
            }
            .padding()
            .background(SpotifyDesign.background)
            .navigationTitle("Add Track")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(SpotifyDesign.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addTrack()
                    }
                    .disabled(uriInput.trimmingCharacters(in: .whitespaces).isEmpty || isAdding)
                    .fontWeight(.semibold)
                }
            }
            .interactiveDismissDisabled(isAdding)
        }
    }
    
    private func addTrack() {
        isAdding = true
        
        let uri = parseSpotifyURI(uriInput.trimmingCharacters(in: .whitespaces))
        
        guard !uri.isEmpty else {
            let msg = "Invalid Spotify URI or link"
            print("[Loop] Add track error: \(msg)")
            toastStore.show(msg)
            isAdding = false
            return
        }
        
        Task {
            let success = await fetchAndAddTrack(uri: uri)
            await MainActor.run {
                isAdding = false
                if success {
                    dismiss()
                }
            }
        }
    }
    
    private func parseSpotifyURI(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        
        // Already a URI
        if trimmed.hasPrefix("spotify:track:") {
            return trimmed
        }
        
        // URL format: https://open.spotify.com/track/... or https://open.spotify.com/intl-de/track/...
        if let url = URL(string: trimmed),
           url.host?.contains("open.spotify.com") == true {
            let path = url.path
            if path.contains("/track/") {
                let parts = path.split(separator: "/")
                if let trackIndex = parts.firstIndex(of: "track"), trackIndex + 1 < parts.count {
                    let trackId = String(parts[trackIndex + 1])
                    if let queryIndex = trackId.firstIndex(of: "?") {
                        return "spotify:track:\(trackId[..<queryIndex])"
                    }
                    return "spotify:track:\(trackId)"
                }
            }
        }
        
        return ""
    }
    
    private func fetchAndAddTrack(uri: String) async -> Bool {
        guard SpotifyService.shared.isConnected else {
            let msg = "Connect to Spotify first"
            print("[Loop] Add track error: \(msg)")
            await MainActor.run { toastStore.show(msg) }
            return false
        }

        guard let contentItem = await SpotifyService.shared.fetchContentItem(uri: uri) else {
            let msg = "Could not fetch track. Check the URI."
            print("[Loop] Add track error: \(msg)")
            await MainActor.run { toastStore.show(msg) }
            return false
        }
        
        let trackName: String
        let artistName: String
        let durationMs: Int
        
        if let track = contentItem as? SPTAppRemoteTrack {
            trackName = track.name
            artistName = track.artist.name
            durationMs = Int(track.duration)
        } else {
            trackName = contentItem.title ?? "Unknown"
            artistName = contentItem.subtitle ?? "Unknown"
            durationMs = 300_000 // 5 min default if no duration
        }
        
        let clip = ClipItem(
            spotifyURI: uri,
            trackName: trackName,
            artistName: artistName,
            startPositionMs: 0,
            stopPositionMs: durationMs,
            durationMs: durationMs,
            order: (try? modelContext.fetch(FetchDescriptor<ClipItem>()).count) ?? 0
        )
        
        await MainActor.run {
            modelContext.insert(clip)
        }
        
        return true
    }
}

#Preview {
    AddTrackView()
        .modelContainer(for: ClipItem.self, inMemory: true)
}
