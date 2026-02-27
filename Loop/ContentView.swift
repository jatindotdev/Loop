//
//  ContentView.swift
//  Loop
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var spotifyService = SpotifyService.shared
    @StateObject private var toastStore = ToastStore.shared
    
    var body: some View {
        Group {
            if spotifyService.isRestoringSession {
                SplashView()
            } else if spotifyService.isConnected {
                LoopDeckView()
            } else {
                LoginView()
            }
        }
        .preferredColorScheme(.dark)
        .overlay(alignment: .top) {
            ToastOverlay(toastStore: toastStore)
        }
        .onChange(of: spotifyService.connectionError) { _, newValue in
            if let message = newValue {
                toastStore.show(message)
            }
        }
        .onAppear {
            if let message = spotifyService.connectionError {
                toastStore.show(message)
            }
        }
    }
}

#Preview {
    ContentView()
}
