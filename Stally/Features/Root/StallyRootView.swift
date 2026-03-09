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
    @Environment(StallyRootNavigationState.self)
    var navigationState
    @Environment(\.modelContext)
    var context
    @Environment(MHAppRuntime.self)
    var appRuntime
    @Environment(MHObservableDeepLinkInbox.self)
    var deepLinkInbox
    @Environment(MHObservableRouteInbox<StallyRoute>.self)
    var routeInbox

    @Query(
        sort: [
            SortDescriptor(\Item.createdAt, order: .reverse)
        ]
    )
    var items: [Item]

    var body: some View {
        NavigationStack(path: pathBinding) {
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
        .sheet(item: editorRouteBinding) { route in
            editorDestination(for: route)
        }
        .onChange(of: deepLinkInbox.pendingURL) { _, pendingURL in
            guard let pendingURL,
                  deepLinkCodec.parse(pendingURL) == nil
            else {
                return
            }

            navigationState.presentUnsupportedDeepLinkError()
        }
        .onChange(of: routeInbox.pendingRoute) { _, pendingRoute in
            guard pendingRoute != nil,
                  let route = routeInbox.consumeLatest()
            else {
                return
            }

            StallyRootRouteService.apply(
                route: route,
                to: navigationState,
                items: items
            )
        }
        .onChange(of: navigationState.reviewPreferences) { _, newValue in
            newValue.save(in: appRuntime.preferenceStore)
        }
        .onChange(of: navigationState.insightsPreferences) { _, newValue in
            newValue.save(in: appRuntime.preferenceStore)
        }
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

    var pathBinding: Binding<[StallyRootNavigationState.Route]> {
        .init(
            get: {
                navigationState.path
            },
            set: { newValue in
                navigationState.path = newValue
            }
        )
    }

    var editorRouteBinding: Binding<StallyRootNavigationState.EditorRoute?> {
        .init(
            get: {
                navigationState.editorRoute
            },
            set: { newValue in
                navigationState.editorRoute = newValue
            }
        )
    }

    var reviewPreferencesBinding: Binding<StallyReviewPreferences> {
        .init(
            get: {
                navigationState.reviewPreferences
            },
            set: { newValue in
                navigationState.reviewPreferences = newValue
            }
        )
    }

    var insightsPreferencesBinding: Binding<StallyInsightsPreferences> {
        .init(
            get: {
                navigationState.insightsPreferences
            },
            set: { newValue in
                navigationState.insightsPreferences = newValue
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
                onOpenInsights: openInsights,
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
}
