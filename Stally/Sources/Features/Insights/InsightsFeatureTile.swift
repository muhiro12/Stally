//
//  InsightsFeatureTile.swift
//  Stally
//
//  Created by Codex on 2026/07/23.
//

import MHUI
import SwiftUI

struct InsightsFeatureTile<Details: View>: View {
    @Environment(\.mhTheme)
    private var theme

    let metadata: LocalizedStringResource
    let value: Text
    let title: LocalizedStringResource
    let surfaceRole: MHSurfaceRole
    let details: Details

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.control) {
            VStack(alignment: .leading, spacing: theme.spacing.inline) {
                Text(metadata)
                    .mhTextStyle(.metadata, colorRole: .tertiaryText)

                value
                    .mhTextStyle(.summaryTitle)

                Text(title)
                    .mhTextStyle(.bodyStrong)
            }

            Divider()
                .accessibilityHidden(true)

            details
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .mhSurfaceInset()
        .mhSurface(role: surfaceRole)
    }

    init(
        metadata: LocalizedStringResource,
        value: Text,
        title: LocalizedStringResource,
        surfaceRole: MHSurfaceRole,
        @ViewBuilder details: () -> Details
    ) {
        self.metadata = metadata
        self.value = value
        self.title = title
        self.surfaceRole = surfaceRole
        self.details = details()
    }
}
