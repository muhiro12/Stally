//
//  SettingsView.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import MHPlatform
import MHUI
import SwiftUI

struct SettingsView: View {
    let items: [Item]

    @AppStorage(\.isSubscribeOn)
    private var isSubscribeOn
    @AppStorage(\.isICloudOn)
    private var isICloudOn
    @AppStorage(\.needsFirstMarkAfterDays)
    private var needsFirstMarkAfterDays
    @AppStorage(\.dormantAfterDays)
    private var dormantAfterDays
    @AppStorage(\.showsCompletedReviewSections)
    private var showsCompletedReviewSections
    @AppStorage(\.defaultInsightsRange, default: .thirtyDays)
    private var defaultInsightsRange: InsightsRange
    @AppStorage(\.includesArchivedItemsInInsights)
    private var includesArchivedItemsInInsights

    var body: some View {
        NavigationStack {
            settingsList
        }
    }

    private var settingsList: some View {
        List {
            settingsContent()
        }
        .stallyListChrome()
        .navigationTitle("Settings")
    }

    @ViewBuilder
    private func settingsContent() -> some View {
        SettingsSubscriptionSection(
            isSubscribeOn: isSubscribeOn
        )

        StallyStoreSection()

        SettingsICloudSection(isICloudOn: $isICloudOn)

        SettingsReviewSection(
            needsFirstMarkAfterDays: $needsFirstMarkAfterDays,
            dormantAfterDays: $dormantAfterDays,
            showsCompletedSections: $showsCompletedReviewSections
        )

        SettingsInsightsSection(
            defaultRange: $defaultInsightsRange,
            includesArchivedItems: $includesArchivedItemsInInsights
        )

        Section {
            NavigationLink {
                BackupCenterView(items: items)
            } label: {
                Label("Backup Center", systemImage: "externaldrive")
            }
            .mhRow()
        }

        Section("Shareable Links") {
            ForEach(StallyLinkDestination.allCases) { destination in
                ShareLink(item: StallyLinkOperations.url(for: .destination(destination))) {
                    Label {
                        Text(destination.title)
                    } icon: {
                        Image(systemName: destination.systemImageName)
                    }
                }
                .mhRow()
            }
        }

        StallyAboutSection()
    }
}
