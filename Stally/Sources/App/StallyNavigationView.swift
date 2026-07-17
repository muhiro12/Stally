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

    enum DetailRoute: Hashable {
        case item(UUID)
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
            .stallyListChrome()
            .navigationTitle("Stally")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: settingsAction) {
                        Label("Settings", systemImage: "gear")
                    }
                    .stallyToolbarActionStyle()
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
        @Binding var path: [DetailRoute]

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
            NavigationStack(path: $path) {
                destinationContent
                    .navigationDestination(for: DetailRoute.self) { route in
                        detailDestination(for: route)
                    }
            }
        }

        @ViewBuilder private var destinationContent: some View {
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

        @ViewBuilder
        private func detailDestination(for route: DetailRoute) -> some View {
            switch route {
            case .item(let itemID):
                if let item = items.first(where: { $0.uuid == itemID }) {
                    ItemDetailView(item: item)
                } else {
                    ContentUnavailableView(
                        "Unsupported Link",
                        systemImage: "link.badge.plus",
                        description: Text(
                            "This link is not supported by this version of Stally."
                        )
                    )
                }
            }
        }
    }

    @Binding var selectedDestination: Destination?
    @Binding var preferredCompactColumn: NavigationSplitViewColumn
    @Binding var detailPath: [DetailRoute]

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
                path: $detailPath,
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
