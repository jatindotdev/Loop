import SwiftUI

struct LoginView: View {
    @ObservedObject var spotifyService = SpotifyService.shared
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("Loop")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(SpotifyDesign.green)
            
            Text("Trimmed Spotify Playlist")
                .font(SpotifyDesign.bodyFont())
                .foregroundColor(SpotifyDesign.secondaryText)
            
            Spacer()
            
            Button {
                spotifyService.authorize()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.circle.fill")
                    Text("Connect to Spotify")
                }
                .font(SpotifyDesign.headlineFont())
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: SpotifyDesign.largeButtonCornerRadius, style: .continuous)
                        .fill(SpotifyDesign.green)
                )
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SpotifyDesign.background)
    }
}

#Preview {
    LoginView()
}
