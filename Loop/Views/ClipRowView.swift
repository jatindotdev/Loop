//
//  ClipRowView.swift
//  Loop
//
//  Track row for list: ArtworkView + track/artist/trim + edit
//

import SwiftUI

struct ClipRowView: View {
    let clip: ClipItem
    let isCurrentTrack: Bool
    let isPaused: Bool
    let isSelectionMode: Bool
    let isSelected: Bool
    let onPlay: () -> Void
    let onEdit: () -> Void
    let onSelect: () -> Void

    var body: some View {
        Button {
            if isSelectionMode {
                onSelect()
            } else {
                onPlay()
            }
        } label: {
            HStack(spacing: 12) {
                if isSelectionMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isSelected ? SpotifyDesign.green : SpotifyDesign.muted)
                } else {
                    ArtworkView(
                        clip: clip,
                        isCurrentTrack: isCurrentTrack,
                        isPaused: isPaused,
                        size: 48
                    )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(clip.trackName)
                        .font(SpotifyDesign.headlineFont())
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(clip.artistName)
                        .font(SpotifyDesign.bodyFont())
                        .foregroundColor(SpotifyDesign.secondaryText)
                        .lineLimit(1)

                    Text(clip.trimRangeDisplay)
                        .font(SpotifyDesign.captionFont())
                        .foregroundColor(SpotifyDesign.muted)
                }

                Spacer()

                if !isSelectionMode {
                    Button {
                        onEdit()
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(SpotifyDesign.muted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(
            RoundedRectangle(cornerRadius: SpotifyDesign.tileCornerRadius, style: .continuous)
                .fill(SpotifyDesign.glassMaterial)
        )
    }
}
