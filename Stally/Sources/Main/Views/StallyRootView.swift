//
//  StallyRootView.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/03/08.
//

import MHAppRuntimeCore
import StallyLibrary
import SwiftData
import SwiftUI

struct StallyRootView: View {
    @Environment(StallyAppAssembly.self)
    var assembly
    @Environment(\.modelContext)
    var context
    @Environment(MHAppRuntime.self)
    var appRuntime

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
        .onChange(of: assembly.routePipeline.lastParseFailureURL) { _, failedURL in
            guard failedURL != nil
            else {
                return
            }

            navigationState.presentUnsupportedDeepLinkError()
            assembly.routePipeline.clearLastParseFailure()
        }
        .mhRouteHandler(assembly.routeInbox, apply: applyRoute(_:))
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
    var navigationState: StallyRootNavigationState {
        assembly.navigationState
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

    func applyRoute(
        _ route: StallyRoute
    ) {
        StallyRootRouteService.apply(
            route: route,
            to: navigationState,
            items: items
        )
    }
}
