//
//  LoopApp.swift
//  Loop
//
//  Created by FlowDeck Studio on 21/10/25.
//
import SwiftData
import SwiftUI

@main
struct LoopApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([ClipItem.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Schema migration failed; delete store and recreate
            let storeURL = config.url
            try? FileManager.default.removeItem(at: storeURL)
            let shmURL = storeURL.deletingLastPathComponent().appendingPathComponent(storeURL.deletingPathExtension().lastPathComponent + ".store-shm")
            let walURL = storeURL.deletingLastPathComponent().appendingPathComponent(storeURL.deletingPathExtension().lastPathComponent + ".store-wal")
            try? FileManager.default.removeItem(at: shmURL)
            try? FileManager.default.removeItem(at: walURL)
            return try! ModelContainer(for: schema, configurations: [config])
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(sharedModelContainer)
                .onOpenURL { url in
                    Task { @MainActor in
                        SpotifyService.shared.handleAuthCallback(url: url)
                    }
                }
        }
    }
}
