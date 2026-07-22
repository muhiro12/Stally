//
//  SettingsView.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import MHPlatform
import MHUI
import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext)
    private var modelContext
    @Environment(\.stallyPersistenceStatus)
    private var persistenceStatus

    @State private var isConfirmingSampleRemoval = false
    @State private var sampleRemovalErrorMessage: String?

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

    private var sampleDataSummary: SampleDataSummary {
        SampleDataOperations.summary(for: items)
    }

    private var isShowingSampleRemovalError: Binding<Bool> {
        .init(
            get: { sampleRemovalErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    sampleRemovalErrorMessage = nil
                }
            }
        )
    }

    var body: some View {
        NavigationStack {
            settingsList
        }
        .confirmationDialog(
            "Remove Sample Items?",
            isPresented: $isConfirmingSampleRemoval,
            titleVisibility: .visible
        ) {
            Button("Remove Sample Items", role: .destructive) {
                removeSampleItems()
            }

            Button("Cancel", role: .cancel) {
                isConfirmingSampleRemoval = false
            }
        } message: {
            Text(
                // swiftlint:disable:next line_length
                "This removes \(sampleDataSummary.itemCount) sample items and \(sampleDataSummary.markCount) marks, including edits and history you added to them. Other items stay in your Library."
            )
        }
        .alert(
            "Could Not Remove Sample Items",
            isPresented: isShowingSampleRemovalError
        ) {
            Button("OK", role: .cancel) {
                sampleRemovalErrorMessage = nil
            }
        } message: {
            if let sampleRemovalErrorMessage {
                Text(sampleRemovalErrorMessage)
            }
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

        SettingsICloudSection(
            isICloudOn: $isICloudOn,
            persistenceStatus: persistenceStatus
        )

        SettingsReviewSection(
            needsFirstMarkAfterDays: $needsFirstMarkAfterDays,
            dormantAfterDays: $dormantAfterDays,
            showsCompletedSections: $showsCompletedReviewSections
        )

        SettingsInsightsSection(
            defaultRange: $defaultInsightsRange,
            includesArchivedItems: $includesArchivedItemsInInsights
        )

        if !sampleDataSummary.isEmpty {
            SettingsSampleDataSection(
                itemCount: sampleDataSummary.itemCount,
                markCount: sampleDataSummary.markCount,
                removeAction: confirmSampleRemoval
            )
        }

        Section {
            NavigationLink {
                BackupCenterView(items: items)
            } label: {
                Label("Backup Center", systemImage: "externaldrive")
            }
            .mhRow()
        }

        Section {
            ForEach(StallyLinkDestination.allCases) { destination in
                ShareLink(item: StallyLinkOperations.url(for: .destination(destination))) {
                    Label {
                        Text(destination.title)
                    } icon: {
                        Image(systemName: destination.systemImageName)
                    }
                    .mhTextStyle(.body, colorRole: .primaryText)
                }
                .mhRow()
            }
        } header: {
            MHSectionHeader("Shareable Links")
        }

        StallyAboutSection()
    }

    private func confirmSampleRemoval() {
        isConfirmingSampleRemoval = true
    }

    private func removeSampleItems() {
        do {
            try SampleDataOperations.removeSampleItems(in: modelContext)
        } catch {
            sampleRemovalErrorMessage = error.localizedDescription
        }
    }
}
