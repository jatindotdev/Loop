//
//  LoopDeckView.swift
//  Loop
//
//  Loop Deck playlist list
//

import SwiftData
import SwiftUI

struct LoopDeckView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ClipItem.order) private var clips: [ClipItem]
    
    @StateObject private var playbackController = PlaybackController()
    @State private var showingAddTrack = false
    @State private var clipToEdit: ClipItem?
    @State private var isSelectionMode = false
    @State private var selectedClipIds = Set<UUID>()
    
    var body: some View {
        NavigationStack {
            Group {
                if clips.isEmpty {
                    LoopDeckEmptyView { showingAddTrack = true }
                } else {
                    List {
                        Section {
                            ForEach(Array(clips.enumerated()), id: \.element.id) { index, clip in
                                ClipRowView(
                                    clip: clip,
                                    isCurrentTrack: playbackController.currentClipIndex == index,
                                    isPaused: playbackController.isSpotifyPaused,
                                    isSelectionMode: isSelectionMode,
                                    isSelected: selectedClipIds.contains(clip.id),
                                    onPlay: { playbackController.playFromIndex(index) },
                                    onEdit: { clipToEdit = clip },
                                    onSelect: {
                                        if selectedClipIds.contains(clip.id) {
                                            selectedClipIds.remove(clip.id)
                                        } else {
                                            selectedClipIds.insert(clip.id)
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .listRowSpacing(6)
                    .contentMargins(.top, 16, for: .scrollContent)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(SpotifyDesign.background)
            .navigationTitle("Loop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if isSelectionMode {
                        Button("Done") {
                            isSelectionMode = false
                            selectedClipIds.removeAll()
                        }
                    } else {
                        Button("Select") {
                            isSelectionMode = true
                        }
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    if isSelectionMode {
                        Button("Delete", role: .destructive) {
                            deleteSelectedClips()
                        }
                        .disabled(selectedClipIds.isEmpty)
                    } else {
                        Button {
                            showingAddTrack = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddTrack) {
                AddTrackView()
                    .presentationDetents([.fraction(0.75)])
            }
            .sheet(item: $clipToEdit) { clip in
                TrimEditorView(clip: clip)
                    .presentationDetents([.fraction(0.75)])
            }
            .onAppear {
                playbackController.configure(modelContext: modelContext)
                playbackController.loadClips(clips)
                migrateClipDurations()
            }
            .onChange(of: clips.count) { _, _ in
                Task { @MainActor in
                    playbackController.loadClips(clips)
                }
            }
            .onChange(of: clipToEdit) { _, _ in
                if clipToEdit == nil {
                    Task { @MainActor in
                        playbackController.loadClips(clips)
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if playbackController.currentClip != nil {
                    NowPlayingBar(playbackController: playbackController)
                }
            }
        }
    }
    
    private func deleteSelectedClips() {
        for clip in clips where selectedClipIds.contains(clip.id) {
            modelContext.delete(clip)
        }
        selectedClipIds.removeAll()
        isSelectionMode = false
    }

    private func migrateClipDurations() {
        for clip in clips where clip.durationMs == nil {
            clip.durationMs = clip.stopPositionMs
        }
    }
}

// MARK: - Empty State

struct LoopDeckEmptyView: View {
    let onAdd: () -> Void
    
    var body: some View {
        ContentUnavailableView {
            Label("No Tracks", systemImage: "music.note.list")
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(SpotifyDesign.green)
        } description: {
            Text("Add tracks from Spotify to get started.\nPaste a Spotify URI or link.")
                .foregroundColor(SpotifyDesign.secondaryText)
        } actions: {
            Button("Add Track") {
                onAdd()
            }
            .buttonStyle(.borderedProminent)
            .tint(SpotifyDesign.green)
        }
    }
}

#Preview {
    LoopDeckView()
        .modelContainer(for: ClipItem.self, inMemory: true)
}
