import Combine
import Foundation
import SpotifyiOS
import SwiftUI
import UIKit

@MainActor
final class SpotifyService: NSObject, ObservableObject {
    static let shared = SpotifyService()
    
    
    
    @Published private(set) var isConnected = false
    @Published private(set) var isRestoringSession = false
    @Published private(set) var connectionError: String?
    @Published private(set) var currentPlayerState: PlayerState?
    
    
    
    private var appRemote: SPTAppRemote?
    private var sessionManager: SPTSessionManager?
    private var accessToken: String?
    private var reconnectWorkItem: DispatchWorkItem?
    private var reconnectAttemptCount = 0
    private let maxReconnectAttempts = 3
    private var positionPollTimer: Timer?
    
    private var configuration: SPTConfiguration {
        let config = SPTConfiguration(
            clientID: SpotifyConfig.clientID,
            redirectURL: SpotifyConfig.redirectURI
        )
        config.tokenSwapURL = SpotifyConfig.tokenSwapURL
        config.tokenRefreshURL = SpotifyConfig.tokenRefreshURL
        return config
    }
    
    
    
    private override init() {
        super.init()
        if let token = TokenStorage.load() {
            accessToken = token
            setupAppRemoteAndConnect()
        }
    }
    
    
    
    private func setupAppRemoteAndConnect() {
        guard accessToken != nil else { return }
        isRestoringSession = true
        let appRemote = SPTAppRemote(configuration: configuration, logLevel: .debug)
        appRemote.delegate = self
        appRemote.connectionParameters.accessToken = accessToken
        self.appRemote = appRemote
        appRemote.connect()
    }
    
    func authorize() {
        connectionError = nil
        reconnectAttemptCount = 0
        let sessionManager = SPTSessionManager(configuration: configuration, delegate: self)
        self.sessionManager = sessionManager
        
        guard sessionManager.isSpotifyAppInstalled else {
            let msg = "Spotify app is not installed. Please install from the App Store."
            print("[Loop] Auth error: \(msg)")
            connectionError = msg
            return
        }
        
        isRestoringSession = true
        sessionManager.initiateSession(with: [.appRemoteControl], options: .default, campaign: nil)
    }
    
    func handleAuthCallback(url: URL) -> Bool {
        if let sessionManager = sessionManager,
           sessionManager.application(UIApplication.shared, open: url, options: [:]) {
            return true
        }
        return false
    }
    
    func connect() {
        guard let token = accessToken, let appRemote = appRemote else { return }
        appRemote.connectionParameters.accessToken = token
        appRemote.connect()
    }
    
    func disconnect() {
        appRemote?.disconnect()
    }
    
    func reconnectIfNeeded() {
        guard let token = accessToken else { return }
        if let appRemote = appRemote, !appRemote.isConnected {
            isRestoringSession = true
            appRemote.connect()
        } else if appRemote == nil {
            accessToken = token
            setupAppRemoteAndConnect()
        }
    }
    
    
    
    func play(uri: String) {
        appRemote?.playerAPI?.play(uri) { [weak self] _, error in
            Task { @MainActor in
                if let error = error {
                    self?.handlePlaybackError(error.localizedDescription)
                }
            }
        }
    }

    func seekToPosition(_ positionMs: Int) {
        appRemote?.playerAPI?.seek(toPosition: positionMs) { [weak self] _, error in
            Task { @MainActor in
                if let error = error {
                    self?.handlePlaybackError(error.localizedDescription)
                }
            }
        }
    }

    func pause() {
        appRemote?.playerAPI?.pause { [weak self] _, error in
            Task { @MainActor in
                if let error = error {
                    self?.handlePauseError(error.localizedDescription)
                }
            }
        }
    }

    func resume() {
        appRemote?.playerAPI?.resume { [weak self] _, error in
            Task { @MainActor in
                if let error = error {
                    self?.handlePlaybackError(error.localizedDescription)
                }
            }
        }
    }

    private func handlePlaybackError(_ message: String) {
        print("[Loop] Playback error: \(message)")
        if isTokenError(message) {
            handleConnectionError(message)
        } else {
            connectionError = message
        }
    }

    private func handlePauseError(_ message: String) {
        print("[Loop] Pause error: \(message)")
        if isTokenError(message) {
            handleConnectionError(message)
        }
        
    }
    
    func skipToNext() {
        appRemote?.playerAPI?.skip(toNext: nil)
    }
    
    func getPlayerState(callback: @escaping (PlayerState?) -> Void) {
        appRemote?.playerAPI?.getPlayerState { result, error in
            Task { @MainActor in
                if let state = result as? SPTAppRemotePlayerState {
                    callback(PlayerState(from: state))
                } else {
                    callback(nil)
                }
            }
        }
    }
    
    func fetchContentItem(uri: String) async -> SPTAppRemoteContentItem? {
        await withCheckedContinuation { continuation in
            appRemote?.contentAPI?.fetchContentItem(forURI: uri) { result, error in
                if let error {
                    print("[Loop] Fetch content failed for \(uri): \(error.localizedDescription)")
                }
                continuation.resume(returning: (result as? SPTAppRemoteContentItem))
            }
        }
    }

    private var artworkCache: [String: UIImage] = [:]
    private let artworkSize = CGSize(width: 120, height: 120)

    func fetchArtwork(for uri: String) async -> UIImage? {
        if let cached = artworkCache[uri] {
            return cached
        }
        if let image = await fetchArtworkFromSDK(uri: uri) {
            return image
        }
        if let image = await fetchArtworkFromWebAPI(uri: uri) {
            artworkCache[uri] = image
            return image
        }
        return nil
    }

    private func fetchArtworkFromSDK(uri: String) async -> UIImage? {
        guard isConnected,
              let contentItem = await fetchContentItem(uri: uri),
              let track = contentItem as? SPTAppRemoteTrack,
              let imageAPI = appRemote?.imageAPI else {
            return nil
        }
        return await withCheckedContinuation { continuation in
            imageAPI.fetchImage(forItem: track, with: artworkSize) { [weak self] result, error in
                if let error {
                    print("[Loop] SDK artwork failed for \(uri): \(error.localizedDescription)")
                }
                if let image = result as? UIImage {
                    self?.artworkCache[uri] = image
                }
                continuation.resume(returning: result as? UIImage)
            }
        }
    }

    private func fetchArtworkFromWebAPI(uri: String) async -> UIImage? {
        guard let trackId = uri.split(separator: ":").last.map(String.init),
              let token = accessToken else {
            return nil
        }
        guard let url = URL(string: "https://api.spotify.com/v1/tracks/\(trackId)") else {
            return nil
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let album = json["album"] as? [String: Any],
                  let images = album["images"] as? [[String: Any]],
                  let first = images.first,
                  let urlString = first["url"] as? String,
                  let imageURL = URL(string: urlString) else {
                print("[Loop] Web API: no image in track response for \(uri)")
                return nil
            }
            let (imageData, _) = try await URLSession.shared.data(from: imageURL)
            return UIImage(data: imageData)
        } catch {
            print("[Loop] Web API artwork failed for \(uri): \(error.localizedDescription)")
            return nil
        }
    }
}

extension SpotifyService: SPTSessionManagerDelegate {
    nonisolated func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        Task { @MainActor in
            accessToken = session.accessToken
            TokenStorage.save(session.accessToken)
            sessionManager = nil
            setupAppRemoteAndConnect()
        }
    }
    
    nonisolated func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        Task { @MainActor in
            isRestoringSession = false
            handleConnectionError(error.localizedDescription)
            sessionManager = nil
        }
    }
}

extension SpotifyService: SPTAppRemoteDelegate {
    nonisolated func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        Task { @MainActor in
            isConnected = true
            isRestoringSession = false
            connectionError = nil
            reconnectAttemptCount = 0
            appRemote.playerAPI?.delegate = self
            appRemote.playerAPI?.subscribe(toPlayerState: { _, _ in })
            startPositionPolling()
        }
    }
    
    nonisolated func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        if let err = error {
            print("[Loop] Connection failed: \(err.localizedDescription)")
        }
        Task { @MainActor in
            isConnected = false
            stopPositionPolling()
            handleConnectionError(error?.localizedDescription ?? "Connection failed")
            scheduleReconnectAttempt()
        }
    }

    nonisolated func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        if let err = error {
            print("[Loop] Disconnected: \(err.localizedDescription)")
        }
        Task { @MainActor in
            isConnected = false
            stopPositionPolling()
            if let msg = error?.localizedDescription, isTokenError(msg) {
                handleConnectionError(msg)
            }
            if accessToken != nil {
                isRestoringSession = true
                scheduleReconnectAttempt()
            }
        }
    }

    private func isTokenError(_ message: String) -> Bool {
        let lower = message.lowercased()
        return lower.contains("invalid") && lower.contains("grant") || lower.contains("token") && lower.contains("expired")
    }

    private func handleConnectionError(_ message: String) {
        print("[Loop] Connection error: \(message)")
        if isTokenError(message) {
            accessToken = nil
            TokenStorage.delete()
            reconnectWorkItem?.cancel()
            reconnectAttemptCount = 0
            isRestoringSession = false
            appRemote?.disconnect()
            connectionError = "Session expired. Please connect again."
        } else {
            connectionError = message
        }
    }
    
    private func startPositionPolling() {
        stopPositionPolling()
        positionPollTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.appRemote?.playerAPI?.getPlayerState { result, _ in
                    if let state = result as? SPTAppRemotePlayerState {
                        Task { @MainActor in
                            self?.currentPlayerState = PlayerState(from: state)
                        }
                    }
                }
            }
        }
        positionPollTimer?.tolerance = 0.1
        RunLoop.main.add(positionPollTimer!, forMode: .common)
    }
    
    private func stopPositionPolling() {
        positionPollTimer?.invalidate()
        positionPollTimer = nil
    }
    
    private func scheduleReconnectAttempt() {
        reconnectWorkItem?.cancel()
        guard accessToken != nil else {
            isRestoringSession = false
            return
        }
        reconnectAttemptCount += 1
        if reconnectAttemptCount > maxReconnectAttempts {
            isRestoringSession = false
            reconnectAttemptCount = 0
            return
        }
        isRestoringSession = true
        let workItem = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                self?.reconnectIfNeeded()
                self?.reconnectWorkItem = nil
            }
        }
        reconnectWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: workItem)
    }
}

extension SpotifyService: SPTAppRemotePlayerStateDelegate {
    nonisolated func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        Task { @MainActor in
            currentPlayerState = PlayerState(from: playerState)
        }
    }
}

struct PlayerState {
    let trackURI: String?
    let trackName: String
    let artistName: String
    let playbackPositionMs: Int
    let durationMs: Int
    let isPaused: Bool
    
    init(from state: SPTAppRemotePlayerState) {
        trackURI = state.track.uri
        trackName = state.track.name
        artistName = state.track.artist.name
        playbackPositionMs = Int(state.playbackPosition)
        durationMs = Int(state.track.duration)
        isPaused = state.isPaused
    }
}
