import StallyLibrary
import SwiftUI
import UIKit

struct StallyItemArtworkView: View {
    let photoData: Data?
    let category: ItemCategory
    let width: CGFloat
    let height: CGFloat

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

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            StallyDesign.accentMuted.opacity(0.8),
                            StallyDesign.sand.opacity(0.85)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if let photoData,
               let image = UIImage(data: photoData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                VStack(spacing: 10) {
                    Image(systemName: category.symbolName)
                        .font(.system(size: min(width, height) * 0.28, weight: .semibold))
                        .foregroundStyle(StallyDesign.accent)

                    Text(category.title)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(StallyDesign.accent.opacity(0.85))
                }
                .padding(12)
            }
        }
        .frame(width: width, height: height)
        .clipShape(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
    }
}
