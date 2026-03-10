import MHUI
import SwiftUI
import TipKit

struct StallyHomeEntryCard: View {
    @Environment(\.mhTheme)
    private var theme

    let title: String
    let value: String
    let supporting: String
    let metrics: [StallyMetricGrid.Metric]
    let primaryActionTitle: String
    let routeURL: URL?
    let primaryActionTip: (any Tip)?
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

    init(
        title: String,
        value: String,
        supporting: String,
        metrics: [StallyMetricGrid.Metric],
        primaryActionTitle: String,
        routeURL: URL?,
        usesCompactLayout: Bool,
        onOpen: @escaping () -> Void
    ) {
        self.init(
            title: title,
            value: value,
            supporting: supporting,
            metrics: metrics,
            primaryActionTitle: primaryActionTitle,
            routeURL: routeURL,
            actionTip: nil,
            usesCompactLayout: usesCompactLayout,
            onOpen: onOpen
        )
    }

    init(
        title: String,
        value: String,
        supporting: String,
        metrics: [StallyMetricGrid.Metric],
        primaryActionTitle: String,
        routeURL: URL?,
        actionTip: (any Tip)?,
        usesCompactLayout: Bool,
        onOpen: @escaping () -> Void
    ) {
        self.title = title
        self.value = value
        self.supporting = supporting
        self.metrics = metrics
        self.primaryActionTitle = primaryActionTitle
        self.routeURL = routeURL
        self.primaryActionTip = actionTip
        self.usesCompactLayout = usesCompactLayout
        self.onOpen = onOpen
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
        .popoverTip(primaryActionTip, arrowEdge: .top)
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
