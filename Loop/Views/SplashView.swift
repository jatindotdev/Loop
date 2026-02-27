//
//  SplashView.swift
//  Loop
//
//  Loading splash while restoring Spotify session
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            SpotifyDesign.background
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Loop")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(SpotifyDesign.green)

                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(SpotifyDesign.green)
                    .scaleEffect(1.2)
            }
        }
    }
}

#Preview {
    SplashView()
}
