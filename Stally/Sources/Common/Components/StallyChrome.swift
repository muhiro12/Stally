import SwiftUI

// swiftlint:disable file_types_order one_declaration_per_file
enum StallyChrome {}

enum StallySurfaceTone {
    case base
    case elevated
    case quiet
    case accent

    var background: AnyShapeStyle {
        switch self {
        case .base:
            AnyShapeStyle(StallyDesign.panelGradient)
        case .elevated:
            AnyShapeStyle(.thinMaterial)
        case .quiet:
            AnyShapeStyle(StallyDesign.quietPanelGradient)
        case .accent:
            AnyShapeStyle(StallyDesign.heroGradient)
        }
    }

    var foregroundColor: Color {
        switch self {
        case .accent:
            .white
        case .base, .elevated, .quiet:
            StallyDesign.Palette.ink
        }
    }
}

enum StallyValueTone {
    case primary
    case accent
    case secondary

    var foregroundColor: Color {
        switch self {
        case .primary:
            StallyDesign.Palette.ink
        case .accent:
            StallyDesign.Palette.accent
        case .secondary:
            StallyDesign.Palette.mutedInk
        }
    }
}

struct StallySectionHeader: View {
    let eyebrow: String?
    let title: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let eyebrow, !eyebrow.isEmpty {
                Text(eyebrow.uppercased())
                    .font(.caption.weight(.bold))
                    .tracking(1.6)
                    .foregroundStyle(StallyDesign.Palette.accent)
            }

            Text(title)
                .font(StallyDesign.Typography.section)
                .foregroundStyle(StallyDesign.Palette.ink)

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(StallyDesign.Typography.caption)
                    .foregroundStyle(StallyDesign.Palette.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension Text {
    func stallyCardTitle() -> some View {
        self
            .font(StallyDesign.Typography.cardTitle)
            .foregroundStyle(StallyDesign.Palette.ink)
    }

    func stallySupportingText() -> some View {
        self
            .font(StallyDesign.Typography.caption)
            .foregroundStyle(StallyDesign.Palette.mutedInk)
            .fixedSize(horizontal: false, vertical: true)
    }

    func stallyValueText(
        tone: StallyValueTone = .primary
    ) -> some View {
        self
            .font(StallyDesign.Typography.emphasis)
            .foregroundStyle(tone.foregroundColor)
            .fixedSize(horizontal: false, vertical: true)
    }

    func stallyOverlineText() -> some View {
        self
            .font(.caption.weight(.bold))
            .tracking(1.2)
            .foregroundStyle(StallyDesign.Palette.mutedInk)
    }
}

struct StallyTag: View {
    let title: String
    let tone: StallySurfaceTone

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tone.foregroundColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule(style: .continuous)
                    .fill(tone.background)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(StallyDesign.Palette.outline, lineWidth: 1)
            )
    }
}

struct StallyPrimaryButtonStyle: ButtonStyle {
    func makeBody(
        configuration: Configuration
    ) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 18)
            .padding(.vertical, 15)
            .background(
                Capsule(style: .continuous)
                    .fill(StallyDesign.heroGradient)
            )
            .shadow(
                color: StallyDesign.Palette.shadowHeavy,
                radius: 18,
                y: 10
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(StallyDesign.Motion.quick, value: configuration.isPressed)
    }
}

struct StallySecondaryButtonStyle: ButtonStyle {
    func makeBody(
        configuration: Configuration
    ) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(StallyDesign.Palette.ink)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                Capsule(style: .continuous)
                    .fill(.thinMaterial)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(StallyDesign.Palette.outline, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(StallyDesign.Motion.quick, value: configuration.isPressed)
    }
}

struct StallyChipButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(
        configuration: Configuration
    ) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(
                isSelected ? Color.white : StallyDesign.Palette.ink
            )
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule(style: .continuous)
                    .fill(
                        isSelected
                            ? AnyShapeStyle(StallyDesign.heroGradient)
                            : AnyShapeStyle(.thinMaterial)
                    )
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(
                        isSelected
                            ? Color.clear
                            : StallyDesign.Palette.outline,
                        lineWidth: 1
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(StallyDesign.Motion.quick, value: configuration.isPressed)
    }
}

extension View {
    func stallyPanel(
        _ tone: StallySurfaceTone = .base,
        padding: CGFloat = StallyDesign.Layout.cardPadding
    ) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(
                    cornerRadius: StallyDesign.Radius.panel,
                    style: .continuous
                )
                .fill(tone.background)
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: StallyDesign.Radius.panel,
                    style: .continuous
                )
                .stroke(StallyDesign.panelStroke, lineWidth: 1)
            )
            .shadow(
                color: StallyDesign.Palette.shadow,
                radius: 30,
                y: 16
            )
    }

    func stallyScreenBackground() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background {
                StallyDesign.backgroundGradient
                    .ignoresSafeArea()

                RadialGradient(
                    colors: [
                        StallyDesign.Palette.accentSoft.opacity(0.24),
                        .clear,
                    ],
                    center: .topTrailing,
                    startRadius: 0,
                    endRadius: 420
                )
                .ignoresSafeArea()
            }
    }
}
// swiftlint:enable file_types_order one_declaration_per_file
