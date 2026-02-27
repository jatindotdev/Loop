//
//  SpotifyConfig.swift
//  Loop
//
//  Add your Spotify Client ID from https://developer.spotify.com/dashboard
//

import Foundation

enum SpotifyConfig {
    static let clientID: String = {
        guard let id = Bundle.main.infoDictionary?["SpotifyClientID"] as? String, !id.isEmpty else {
            fatalError("SPOTIFY_CLIENT_ID build setting is not configured. Set it in the project build settings or via xcodebuild SPOTIFY_CLIENT_ID=<your_id>.")
        }
        return id
    }()
    static let redirectURI = URL(string: "loop://spotify-login-callback")!
    static let tokenSwapURL = URL(string: "https://spotify-token-refresh.vercel.app/swap")!
    static let tokenRefreshURL = URL(string: "https://spotify-token-refresh.vercel.app/refresh")!
}
