import SwiftUI

enum StallyDesign {
    static let canvas = LinearGradient(
        colors: [
            Color(red: 0.96, green: 0.95, blue: 0.92),
            Color(red: 0.92, green: 0.95, blue: 0.91)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accent = Color(red: 0.21, green: 0.36, blue: 0.30)
    static let accentMuted = Color(red: 0.73, green: 0.81, blue: 0.76)
    static let sand = Color(red: 0.82, green: 0.75, blue: 0.66)
    static let cardFill = Color.white.opacity(0.84)
    static let cardStroke = Color.white.opacity(0.64)
}

extension View {
    func stallyScreenBackground() -> some View {
        background(
            StallyDesign.canvas
                .ignoresSafeArea()
        )
    }

    func stallyCardStyle(
        cornerRadius: CGFloat = 28
    ) -> some View {
        background(
            RoundedRectangle(
                cornerRadius: cornerRadius,
                style: .continuous
            )
            .fill(StallyDesign.cardFill)
            .overlay(
                RoundedRectangle(
                    cornerRadius: cornerRadius,
                    style: .continuous
                )
                .stroke(StallyDesign.cardStroke, lineWidth: 1)
            )
            .shadow(
                color: Color.black.opacity(0.05),
                radius: 24,
                x: 0,
                y: 12
            )
        )
    }
}
