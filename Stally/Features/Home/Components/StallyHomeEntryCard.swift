import MHUI
import SwiftUI

struct StallyHomeEntryCard: View {
    @Environment(\.mhTheme)
    private var theme

    let title: String
    let value: String
    let supporting: String
    let metrics: [StallyMetricGrid.Metric]
    let primaryActionTitle: String
    let routeURL: URL?
    let usesCompactLayout: Bool
    let onOpen: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.control) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .mhRowTitle()

                Spacer(minLength: theme.spacing.control)

                Text(value)
                    .mhRowValue(colorRole: .accent)
            }

            Text(supporting)
                .mhRowSupporting()

            if !metrics.isEmpty {
                StallyMetricGrid(
                    metrics: metrics,
                    usesCompactLayout: usesCompactLayout
                )
            }

            actions
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .mhSurfaceInset()
        .mhSurface(role: .muted)
    }
}

private extension StallyHomeEntryCard {
    @ViewBuilder
    var actions: some View {
        if usesCompactLayout {
            VStack(alignment: .leading, spacing: theme.spacing.control) {
                primaryActionButton
                shareButton
            }
        } else {
            HStack(spacing: theme.spacing.control) {
                primaryActionButton
                shareButton
            }
        }
    }

    var primaryActionButton: some View {
        Button(primaryActionTitle) {
            onOpen()
        }
        .buttonStyle(.mhSecondary)
        .fixedSize(horizontal: true, vertical: false)
    }

    @ViewBuilder
    var shareButton: some View {
        if let routeURL {
            ShareLink(item: routeURL) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.mhSecondary)
            .fixedSize(horizontal: true, vertical: false)
        }
    }
}
