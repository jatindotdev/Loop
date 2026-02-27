//
//  SpotifyDesign.swift
//  Loop
//
//  Design tokens per Spotify Design Guidelines + iOS glass UI
//  https://developer.spotify.com/documentation/design
//

import SwiftUI
import UIKit

enum SpotifyDesign {
    // MARK: - Colors (per Spotify guidelines)
    
    /// Spotify dark background (#191414) - use when artwork color extraction not possible
    static let background = Color(red: 0x19/255, green: 0x14/255, blue: 0x14/255)
    
    /// UIKit variant for AppDelegate / UINavigationBar
    static let backgroundUIColor = UIColor(red: 25/255, green: 20/255, blue: 20/255, alpha: 1)
    
    /// Spotify Green (#1DB954) - primary accent, play buttons, active states
    static let green = Color(red: 0x1D/255, green: 0xB9/255, blue: 0x54/255)
    
    /// Secondary text on dark backgrounds
    static let secondaryText = Color.white.opacity(0.7)
    
    /// Tertiary/muted elements
    static let muted = Color.white.opacity(0.5)
    
    // MARK: - Glass UI (iOS 18+ style)
    
    /// Material for glass cards and tiles
    static let glassMaterial: Material = .ultraThinMaterial
    
    /// Material for elevated overlays (now playing bar, sheets)
    static let glassMaterialElevated: Material = .thinMaterial
    
    // MARK: - Corner Radii (outer / inner rule)
    
    /// Gap between outer and inner radii = padding from outer edge to inner element
    static func innerRadius(outer: CGFloat, gap: CGFloat) -> CGFloat { max(0, outer - gap) }
    
    /// List tiles, cards (outer)
    static let tileCornerRadius: CGFloat = 16
    
    /// Padding from tile edge to content (gap for inner radius)
    static let tilePadding: CGFloat = 8
    
    /// Artwork inside tiles: inner = outer - tilePadding
    static var artworkInTileCornerRadius: CGFloat { innerRadius(outer: tileCornerRadius, gap: tilePadding) }
    
    /// Buttons, inputs
    static let buttonCornerRadius: CGFloat = 14
    
    /// Large buttons (e.g. Connect)
    static let largeButtonCornerRadius: CGFloat = 28
    
    /// Toast, modals, Now Playing bar (outer)
    static let overlayCornerRadius: CGFloat = 20
    
    /// Gap for overlay content (e.g. NP bar)
    static let overlayPadding: CGFloat = 8
    
    /// Artwork inside overlay: inner = outer - overlayPadding
    static var artworkInOverlayCornerRadius: CGFloat { innerRadius(outer: overlayCornerRadius, gap: overlayPadding) }
    
    // MARK: - Typography (Helvetica Neue / system default per guidelines)
    
    static func titleFont() -> Font { .system(size: 17, weight: .semibold) }
    static func headlineFont() -> Font { .system(size: 16, weight: .semibold) }
    static func bodyFont() -> Font { .system(size: 15, weight: .regular) }
    static func captionFont() -> Font { .system(size: 13, weight: .regular) }
}
