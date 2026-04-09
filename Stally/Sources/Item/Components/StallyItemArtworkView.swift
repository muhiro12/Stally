import MHUI
import StallyLibrary
import SwiftUI
import UIKit

struct StallyItemArtworkView: View {
    @Environment(\.mhDesignMetrics)
    private var theme

    let photoData: Data?
    let category: ItemCategory
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ZStack {
            artworkBackground

            if let photoData,
               let image = UIImage(data: photoData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholderContent
            }
        }
        .frame(width: width, height: height)
        .clipShape(
            RoundedRectangle(
                cornerRadius: theme.radius.surface,
                style: .continuous
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: theme.radius.surface,
                style: .continuous
            )
            .stroke(Color.white.opacity(0.35), lineWidth: 1)
        )
        .shadow(
            color: StallyDesign.Palette.shadow,
            radius: 18,
            y: 10
        )
        .accessibilityHidden(true)
    }

    init(
        photoData: Data?,
        category: ItemCategory,
        width: CGFloat = 88,
        height: CGFloat = 104
    ) {
        self.photoData = photoData
        self.category = category
        self.width = width
        self.height = height
    }
}

private extension StallyItemArtworkView {
    var artworkBackground: some View {
        RoundedRectangle(
            cornerRadius: theme.radius.surface,
            style: .continuous
        )
        .fill(
            LinearGradient(
                colors: [
                    StallyDesign.artworkCool.opacity(0.9),
                    StallyDesign.artworkWarm.opacity(0.95),
                    StallyDesign.Palette.accentSoft.opacity(0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    var placeholderContent: some View {
        VStack(spacing: theme.spacing.inline) {
            Image(systemName: category.symbolName)
                .font(.system(size: min(width, height) * 0.28, weight: .semibold))
                .foregroundStyle(StallyDesign.Palette.tint)

            Text(category.title)
                .font(.footnote.weight(.medium))
                .foregroundStyle(StallyDesign.Palette.tint.opacity(0.85))
                .multilineTextAlignment(.center)
        }
        .padding(theme.spacing.inline)
    }
}
