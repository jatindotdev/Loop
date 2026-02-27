//
//  SceneDelegate.swift
//  Loop
//
//  Handles scene lifecycle and Spotify auth URL callback
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    func scene(
        _ scene: UIScene,
        openURLContexts URLContexts: Set<UIOpenURLContext>
    ) {
        guard let url = URLContexts.first?.url else { return }
        Task { @MainActor in
            SpotifyService.shared.handleAuthCallback(url: url)
        }
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        Task { @MainActor in
            SpotifyService.shared.disconnect()
        }
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        Task { @MainActor in
            SpotifyService.shared.reconnectIfNeeded()
        }
    }
}
