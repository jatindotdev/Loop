# Loop

Loop is an iOS app that lets you build a **Loop Deck** — a playlist of trimmed Spotify track clips. Each clip plays only its defined segment, then automatically advances to the next. Think of it as a DJ-style setlist where every track starts and ends exactly where you want.

## Features

- **Loop Deck** — curated playlist of Spotify track clips with custom start/stop points
- **Trim Editor** — set precise in/out points per track using a slider UI
- **Auto-advance** — plays through the deck automatically, track by track
- **Now Playing Bar** — live playback controls with track info and artwork
- **Add by URI or Link** — paste a `spotify:track:` URI or any `open.spotify.com/track/` link
- **Artwork** — fetches album art via Spotify SDK or Web API fallback
- **Select & Delete** — bulk-remove clips from the deck

## Requirements

- iOS 17+
- Xcode 16+
- Spotify app installed on the target device
- Spotify Premium account
- A [Spotify Developer](https://developer.spotify.com/dashboard) app with the iOS SDK enabled

## Setup

### 1. Clone the repo

```bash
git clone https://github.com/<your-username>/Loop.git
cd Loop
```

### 2. Add the Spotify iOS SDK

Loop uses the [Spotify iOS SDK](https://github.com/spotify/ios-sdk). Download the latest `SpotifyiOS.xcframework` and add it to the Xcode project under **Frameworks, Libraries, and Embedded Content**.

### 3. Configure your Spotify credentials

`SpotifyConfig.swift` reads the Client ID from the `SPOTIFY_CLIENT_ID` Xcode build setting, which is injected into the app bundle via `Info.plist`. You can supply it in three ways:

**Option A — Xcode build settings (recommended for local dev)**

In Xcode, select the **Loop** project → **Loop** target → **Build Settings**, find `SPOTIFY_CLIENT_ID`, and set it to your Client ID.

**Option B — xcconfig file**

Copy the provided template and fill in your credentials:

```bash
cp Secrets.xcconfig.template Secrets.xcconfig
# then edit Secrets.xcconfig with your Client ID
```

Then assign `Secrets.xcconfig` to the Loop target's Debug/Release build configurations in Xcode under **Project → Info → Configurations**.

**Option C — xcodebuild command line**

```bash
xcodebuild -scheme Loop SPOTIFY_CLIENT_ID=your_client_id_here
```

The token server URLs (`tokenSwapURL` / `tokenRefreshURL`) in `SpotifyConfig.swift` also need to point to your own token exchange server — see the [Spotify auth guide](https://developer.spotify.com/documentation/ios/quick-start).

### 4. Build & Run

Open `Loop.xcodeproj` in Xcode, select your device, and hit **Run**. Simulator is not supported (Spotify SDK requires a real device).

## Architecture

| Layer | Files | Role |
|---|---|---|
| App entry | `LoopApp.swift`, `AppDelegate.swift` | SwiftData container setup, URL callback routing |
| Views | `Loop/Views/` | SwiftUI screens (Loop Deck, Trim Editor, Add Track, Now Playing Bar) |
| Models | `Loop/Models/ClipItem.swift` | SwiftData model for a trimmed clip |
| Services | `Loop/Services/SpotifyService.swift` | Spotify SDK connection, playback, artwork |
| Services | `Loop/Services/PlaybackController.swift` | Trim-aware queue: seeks to start, monitors position, auto-advances |
| Services | `Loop/Services/TokenStorage.swift` | Keychain-backed access token persistence |
| Config | `Loop/Config/SpotifyConfig.swift` | Spotify credentials (not committed) |
| Config | `Loop/Config/SpotifyDesign.swift` | Design tokens (colors, typography, radii) |

## How It Works

1. **Connect** — authorize via the Spotify app using OAuth + SPTSessionManager
2. **Add tracks** — paste a Spotify URI or share link; Loop fetches track metadata via the SDK
3. **Trim** — use the Trim Editor to set a start and stop point per clip (stored in SwiftData)
4. **Play** — tap any clip in the Loop Deck; PlaybackController seeks to the start point and monitors playback position every 500ms, pausing and advancing when the stop point is reached

## License

MIT
