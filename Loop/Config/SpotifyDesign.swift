import SwiftUI
import UIKit

enum SpotifyDesign {
    
    
    
    static let background = Color(red: 0x19/255, green: 0x14/255, blue: 0x14/255)
    
    
    static let backgroundUIColor = UIColor(red: 25/255, green: 20/255, blue: 20/255, alpha: 1)
    
    
    static let green = Color(red: 0x1D/255, green: 0xB9/255, blue: 0x54/255)
    
    
    static let secondaryText = Color.white.opacity(0.7)
    
    
    static let muted = Color.white.opacity(0.5)
    
    
    
    
    static let glassMaterial: Material = .ultraThinMaterial
    
    
    static let glassMaterialElevated: Material = .thinMaterial
    
    
    
    
    static func innerRadius(outer: CGFloat, gap: CGFloat) -> CGFloat { max(0, outer - gap) }
    
    
    static let tileCornerRadius: CGFloat = 16
    
    
    static let tilePadding: CGFloat = 8
    
    
    static var artworkInTileCornerRadius: CGFloat { innerRadius(outer: tileCornerRadius, gap: tilePadding) }
    
    
    static let buttonCornerRadius: CGFloat = 14
    
    
    static let largeButtonCornerRadius: CGFloat = 28
    
    
    static let overlayCornerRadius: CGFloat = 20
    
    
    static let overlayPadding: CGFloat = 8
    
    
    static var artworkInOverlayCornerRadius: CGFloat { innerRadius(outer: overlayCornerRadius, gap: overlayPadding) }
    
    
    
    static func titleFont() -> Font { .system(size: 17, weight: .semibold) }
    static func headlineFont() -> Font { .system(size: 16, weight: .semibold) }
    static func bodyFont() -> Font { .system(size: 15, weight: .regular) }
    static func captionFont() -> Font { .system(size: 13, weight: .regular) }
}
