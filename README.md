# Loop

Your music, your moments. **Loop** lets you build a personal deck of trimmed Spotify clips — each track starts and ends exactly where you want, then seamlessly flows into the next. Whether it's the perfect chorus, a hype drop, or a chill intro, Loop keeps only what matters.

## Features

- **Loop Deck** — a curated sequence of Spotify clips, each with its own start and stop point
- **Trim Editor** — dial in your in/out points with precision sliders
- **Seamless Auto-advance** — clips chain together automatically, no tapping required
- **Now Playing Bar** — glanceable playback controls with live artwork
- **Add by URI or Link** — paste a `spotify:track:` URI or any `open.spotify.com/track/` URL
- **Bulk Management** — select and remove clips in one go

## Demo

[Check out the demo](https://github.com/user-attachments/assets/e09ee202-c5c9-499c-9317-87b2a73b07f3)

## Requirements

- iOS 17+
- Xcode 16+
- Spotify app installed on device
- Spotify Premium account
- A [Spotify Developer](https://developer.spotify.com/dashboard) app with the iOS SDK enabled

## Setup

### 1. Clone the repo

```bash
git clone https://github.com/jatindotdev/Loop.git
cd Loop
```

### 2. Add the Spotify iOS SDK

Loop uses the [Spotify iOS SDK](https://github.com/spotify/ios-sdk). Download the latest `SpotifyiOS.xcframework` and add it to the Xcode project under **Frameworks, Libraries, and Embedded Content**.

### 3. Configure your Spotify credentials

`SpotifyConfig.swift` reads the Client ID from the `SPOTIFY_CLIENT_ID` Xcode build setting, injected into the app bundle via `Info.plist`. You can supply it in three ways:

**Option A — Xcode build settings (recommended)**

In Xcode, go to the **Loop** target → **Build Settings**, find `SPOTIFY_CLIENT_ID`, and paste your Client ID.

**Option B — xcconfig file**

```bash
cp Secrets.xcconfig.template Secrets.xcconfig
# fill in SPOTIFY_CLIENT_ID inside Secrets.xcconfig
```

Then assign `Secrets.xcconfig` to the Loop target's Debug/Release configurations under **Project → Info → Configurations**.

**Option C — xcodebuild**

```bash
xcodebuild -scheme Loop SPOTIFY_CLIENT_ID=your_client_id_here
```

> The `tokenSwapURL` and `tokenRefreshURL` in `SpotifyConfig.swift` must point to your own token exchange server — see the [Spotify auth guide](https://developer.spotify.com/documentation/ios/quick-start).

### 4. Build & Run

Open `Loop.xcodeproj`, select a physical device, and hit **Run**. The Spotify SDK requires a real device — simulator is not supported.

## Architecture

| Layer | Files | Role |
|---|---|---|
| App entry | `LoopApp.swift`, `AppDelegate.swift` | SwiftData container, URL callback routing |
| Views | `Loop/Views/` | SwiftUI screens — Loop Deck, Trim Editor, Add Track, Now Playing Bar |
| Model | `Loop/Models/ClipItem.swift` | SwiftData model for a trimmed clip |
| Services | `Loop/Services/SpotifyService.swift` | SDK connection, playback, artwork fetching |
| Services | `Loop/Services/PlaybackController.swift` | Trim-aware queue — seeks to start, polls position, auto-advances |
| Services | `Loop/Services/TokenStorage.swift` | Keychain-backed token persistence |
| Config | `Loop/Config/SpotifyConfig.swift` | Credentials via build setting (never hardcoded) |
| Config | `Loop/Config/SpotifyDesign.swift` | Design tokens — Spotify colours, typography, radii |

## How It Works

1. **Connect** — authorize via the Spotify app using OAuth + `SPTSessionManager`
2. **Add** — paste a Spotify URI or share link; Loop resolves track name, artist, and duration via the SDK
3. **Trim** — set a start and stop point per clip; saved to SwiftData on device
4. **Play** — `PlaybackController` seeks to the clip's start, polls playback position every 500 ms, then pauses and advances when the stop point is reached

## License

MIT
