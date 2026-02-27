import SwiftUI

struct ArtworkView: View {
    let clip: ClipItem
    let isCurrentTrack: Bool
    let isPaused: Bool
    var size: CGFloat = 48
    
    var cornerRadius: CGFloat = SpotifyDesign.artworkInTileCornerRadius
    
    var showPlayOverlay: Bool = true

    @State private var image: UIImage?

    private var shouldShowOverlay: Bool { showPlayOverlay && isCurrentTrack }
    private var overlayIcon: String { isPaused ? "play.fill" : "pause.fill" }

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .opacity(shouldShowOverlay ? 0.5 : 1)
            } else {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(SpotifyDesign.green.opacity(0.3))
                    .overlay {
                        Image(systemName: "music.note")
                            .font(.title3)
                            .foregroundColor(SpotifyDesign.green)
                    }
                    .opacity(shouldShowOverlay ? 0.5 : 1)
            }

            if shouldShowOverlay {
                Image(systemName: overlayIcon)
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .task {
            image = await SpotifyService.shared.fetchArtwork(for: clip.spotifyURI)
        }
    }
}
