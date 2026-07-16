//
//  StallyNavigationView.swift
//  Stally
//
//  Created by Codex on 2026/07/16.
//

import SwiftUI

struct StallyNavigationView: View {
    enum Destination: Hashable, Identifiable {
        case library
        case archive
        case review
        case insights

        static let collectionDestinations: [Self] = [
            .library,
            .archive
        ]

        static let reflectionDestinations: [Self] = [
            .review,
            .insights
        ]

        var id: Self {
            self
        }

        var linkDestination: StallyLinkDestination {
            switch self {
            case .library:
                .library
            case .archive:
                .archive
            case .review:
                .review
            case .insights:
                .insights
            }
        }
    }

    private struct Sidebar: View {
        @Binding var selection: Destination?

        let settingsAction: () -> Void

        var body: some View {
            List(selection: $selection) {
                Section {
                    ForEach(Destination.collectionDestinations) { destination in
                        DestinationLink(destination: destination)
                    }
                }

                Section {
                    ForEach(Destination.reflectionDestinations) { destination in
                        DestinationLink(destination: destination)
                    }
                }
            }
            .navigationTitle("Stally")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: settingsAction) {
                        Label("Settings", systemImage: "gear")
                    }
                }
            }
        }
    }

    private struct DestinationLink: View {
        let destination: Destination

        var body: some View {
            NavigationLink(value: destination) {
                Label {
                    Text(destination.linkDestination.title)
                } icon: {
                    Image(systemName: destination.linkDestination.systemImageName)
                }
            }
        }
    }

    private struct Detail: View {
        let destination: Destination
        let items: [Item]
        let reviewSnapshot: ReviewSnapshot
        let allowsSampleItems: Bool
        let addAction: () -> Void
        let restoreAction: () -> Void

        private var activeItems: [Item] {
            ItemOperations.activeItems(from: items)
        }

        private var archivedItems: [Item] {
            ItemOperations.archivedItems(from: items)
        }

        var body: some View {
            switch destination {
            case .library:
                LibraryView(
                    items: activeItems,
                    allowsSampleItems: allowsSampleItems,
                    addAction: addAction,
                    restoreAction: restoreAction
                )
            case .archive:
                ArchiveView(items: archivedItems)
            case .review:
                ReviewView(snapshot: reviewSnapshot)
            case .insights:
                InsightsView(items: items)
            }
        }
    }

    @Binding var selectedDestination: Destination?
    @Binding var preferredCompactColumn: NavigationSplitViewColumn

    let items: [Item]
    let reviewSnapshot: ReviewSnapshot
    let allowsSampleItems: Bool
    let addAction: () -> Void
    let restoreAction: () -> Void
    let settingsAction: () -> Void

    var body: some View {
        NavigationSplitView(preferredCompactColumn: $preferredCompactColumn) {
            Sidebar(
                selection: $selectedDestination,
                settingsAction: settingsAction
            )
        } detail: {
            Detail(
                destination: selectedDestination ?? .library,
                items: items,
                reviewSnapshot: reviewSnapshot,
                allowsSampleItems: allowsSampleItems,
                addAction: addAction,
                restoreAction: restoreAction
            )
        }
    }
}
