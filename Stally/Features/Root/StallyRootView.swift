//
//  StallyRootView.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/03/08.
//

import MHPlatform
import StallyLibrary
import SwiftData
import SwiftUI

struct StallyRootView: View {
    @Environment(\.modelContext)
    var context
    @Environment(MHAppRuntime.self)
    var appRuntime
    @Environment(MHObservableDeepLinkInbox.self)
    var deepLinkInbox

    @Query(
        sort: [
            SortDescriptor(\Item.createdAt, order: .reverse)
        ]
    )
    var items: [Item]

    // swiftlint:disable:next private_swiftui_state
    @State var navigationState = StallyRootNavigationState()

    var body: some View {
        NavigationStack(path: $navigationState.path) {
            navigationContent
        }
        .alert(
            "Unable to Complete This Action",
            isPresented: isOperationErrorPresented
        ) {
            Button("OK", role: .cancel) {
                navigationState.dismissOperationError()
            }
        } message: {
            Text(navigationState.operationErrorMessage ?? "")
        }
        .sheet(item: $navigationState.editorRoute) { route in
            editorDestination(for: route)
        }
        .onChange(of: deepLinkInbox.pendingURL) {
            Task {
                await synchronizePendingRouteIfNeeded()
            }
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
        .onChange(of: navigationState.reviewPreferences) { _, newValue in
            newValue.save(in: appRuntime.preferenceStore)
        }
        .stallyRuntimeLifecycle(
            plan: runtimeLifecyclePlan
        )
    }
}

@MainActor
extension StallyRootView {
    var deepLinkCodec: MHDeepLinkCodec<StallyRoute> {
        StallyDeepLinking.codec()
    }

    var activeItems: [Item] {
        ItemInsightsCalculator.homeSort(
            items: ItemInsightsCalculator.activeItems(from: items)
        )
    }

    var archivedItems: [Item] {
        ItemInsightsCalculator.archivedItems(from: items)
    }

    var reviewSummary: ItemReviewSummary {
        ItemReviewCalculator.summary(
            from: items,
            policy: navigationState.reviewPreferences.policy
        )
    }

    var isOperationErrorPresented: Binding<Bool> {
        .init(
            get: {
                navigationState.operationErrorMessage != nil
            },
            set: { isPresented in
                if !isPresented {
                    navigationState.dismissOperationError()
                }
            }
        )
    }

    var navigationContent: some View {
        StallyHomeView(
            items: activeItems,
            reviewPreferences: navigationState.reviewPreferences,
            reviewSummary: reviewSummary,
            archiveSummary: ItemInsightsCalculator.archiveSummary(
                from: archivedItems
            ),
            actions: .init(
                onOpenItem: openItem(_:),
                onCreateItem: openCreateItem,
                onSeedSampleData: seedSampleData,
                onOpenArchive: openArchive,
                onOpenBackup: openBackup,
                onOpenReview: openReview,
                onOpenSettings: openSettings,
                onToggleTodayMark: toggleTodayMark(for:)
            )
        )
        .navigationDestination(
            for: StallyRootNavigationState.Route.self
        ) { route in
            rootDestination(for: route)
        }
    }

    var runtimeLifecyclePlan: StallyRuntimeLifecycleSupport.Plan {
        StallyRuntimeLifecycleSupport.makePlan(
            startRuntimeIfNeeded: {
                appRuntime.startIfNeeded()
            },
            loadReviewPreferencesIfNeeded: {
                loadReviewPreferencesIfNeeded()
            },
            applyPendingDeepLinkIfNeeded: {
                await synchronizePendingRouteIfNeeded()
            }
        )
    }
}
