//
//  StallyRootView.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/03/08.
//

import Foundation
import MHPlatform
import SwiftUI

struct StallyRootView: View {
    @Environment(\.scenePhase)
    private var scenePhase
    @Environment(MHAppRuntime.self)
    private var appRuntime
    @Environment(MHObservableDeepLinkInbox.self)
    private var deepLinkInbox

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    headerSection
                    statusSection
                    pendingDeepLinkSection
                    licensesSection
                }
                .padding(20)
            }
            .navigationTitle(StallyAppConfiguration.displayName)
        }
        .task {
            appRuntime.startIfNeeded()
        }
        .onChange(of: scenePhase) {
            guard scenePhase == .active else {
                return
            }

            appRuntime.startIfNeeded()
        }
        .onOpenURL { url in
            Task {
                await deepLinkInbox.ingest(url)
            }
        }
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
            guard let webpageURL = userActivity.webpageURL else {
                return
            }

            Task {
                await deepLinkInbox.ingest(webpageURL)
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(StallyAppConfiguration.displayName)
                .font(.largeTitle.weight(.semibold))

            Text(StallyAppConfiguration.conceptLine)
                .font(.body)
                .foregroundStyle(.primary)

            Text(StallyAppConfiguration.baselineNote)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Runtime")
                .font(.headline)

            VStack(spacing: 12) {
                statusRow(
                    title: "Started",
                    value: appRuntime.hasStarted ? "true" : "false"
                )
                statusRow(
                    title: "Premium",
                    value: appRuntime.premiumStatus.rawValue
                )
                statusRow(
                    title: "Ads",
                    value: appRuntime.adsAvailability.rawValue
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }

    @ViewBuilder
    private var pendingDeepLinkSection: some View {
        if let pendingURL = deepLinkInbox.pendingURL {
            VStack(alignment: .leading, spacing: 12) {
                Text("Pending Deep Link")
                    .font(.headline)

                Text(pendingURL.absoluteString)
                    .font(.footnote.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemBackground))
            )
        }
    }

    @ViewBuilder
    private var licensesSection: some View {
        if appRuntime.configuration.showsLicenses {
            VStack(alignment: .leading, spacing: 12) {
                Text("Support")
                    .font(.headline)

                NavigationLink("Open Licenses") {
                    appRuntime.licensesView()
                        .navigationTitle("Licenses")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemBackground))
            )
        }
    }

    private func statusRow(
        title: String,
        value: String
    ) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.body.monospaced())
        }
    }
}
