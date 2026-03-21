import SwiftUI

enum StallyDesign {
    enum Palette {
        static let tint = Color(red: 0.12, green: 0.33, blue: 0.30)
        static let accent = Color(red: 0.93, green: 0.47, blue: 0.18)
        static let accentSoft = Color(red: 0.97, green: 0.78, blue: 0.60)
        static let rose = Color(red: 0.83, green: 0.47, blue: 0.42)
        static let mist = Color(red: 0.95, green: 0.96, blue: 0.95)
        static let surface = Color(red: 0.99, green: 0.98, blue: 0.96)
        static let elevatedSurface = Color(red: 0.96, green: 0.94, blue: 0.91)
        static let quietSurface = Color(red: 0.93, green: 0.91, blue: 0.87)
        static let ink = Color(red: 0.13, green: 0.16, blue: 0.17)
        static let mutedInk = Color(red: 0.39, green: 0.42, blue: 0.41)
        static let border = Color.white.opacity(0.42)
        static let outline = Color.black.opacity(0.08)
        static let shadow = Color(red: 0.23, green: 0.17, blue: 0.10).opacity(0.16)
        static let shadowHeavy = Color(red: 0.18, green: 0.12, blue: 0.08).opacity(0.24)
        static let artworkCool = Color(red: 0.70, green: 0.82, blue: 0.83)
        static let artworkWarm = Color(red: 0.98, green: 0.84, blue: 0.68)
    }

    enum Layout {
        static let screenPadding: CGFloat = 20
        static let sectionSpacing: CGFloat = 30
        static let blockSpacing: CGFloat = 18
        static let compactSpacing: CGFloat = 10
        static let cardPadding: CGFloat = 20
        static let heroHeight: CGFloat = 312
        static let heroCompactHeight: CGFloat = 248
    }

    enum Radius {
        static let panel: CGFloat = 32
        static let card: CGFloat = 26
        static let pill: CGFloat = 20
        static let artwork: CGFloat = 28
    }

    enum Typography {
        static let display = Font.system(.title, design: .serif).weight(.semibold)
        static let hero = Font.system(.largeTitle, design: .serif).weight(.bold)
        static let section = Font.system(.title3, design: .serif).weight(.semibold)
        static let cardTitle = Font.system(.title3, design: .serif).weight(.semibold)
        static let body = Font.system(.body, design: .rounded)
        static let emphasis = Font.system(.headline, design: .rounded).weight(.semibold)
        static let caption = Font.system(.footnote, design: .rounded)
        static let metric = Font.system(.title2, design: .rounded).weight(.semibold)
    }

    enum Motion {
        static let quick = Animation.snappy(duration: 0.28, extraBounce: 0.02)
        static let smooth = Animation.snappy(duration: 0.40, extraBounce: 0.08)
    }

    static let tint = Palette.tint
    static let artworkCool = Palette.artworkCool
    static let artworkWarm = Palette.artworkWarm

    static let backgroundGradient = LinearGradient(
        colors: [
            Palette.mist,
            Palette.surface,
            Palette.accentSoft.opacity(0.24),
            Palette.rose.opacity(0.10)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let panelGradient = LinearGradient(
        colors: [
            Palette.surface.opacity(0.92),
            Palette.elevatedSurface.opacity(0.98),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let quietPanelGradient = LinearGradient(
        colors: [
            Palette.quietSurface.opacity(0.96),
            Palette.surface.opacity(0.92),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let heroGradient = LinearGradient(
        colors: [
            Palette.tint,
            Color(red: 0.17, green: 0.28, blue: 0.33),
            Palette.accent.opacity(0.86),
            Palette.rose.opacity(0.78)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let panelStroke = LinearGradient(
        colors: [
            Color.white.opacity(0.72),
            Color.white.opacity(0.18),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
