//
//  StallyNavigationView.swift
//  Stally
//
//  Created by Codex on 2026/07/16.
//

import MHUI
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

    private struct Detail: View {
        @Binding var path: [DetailRoute]

        let destination: Destination
        let addAction: () -> Void
        let restoreAction: () -> Void
        let settingsAction: () -> Void

        var body: some View {
            NavigationStack(path: $path) {
                destinationContent
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(action: settingsAction) {
                                Label("Settings", systemImage: "gear")
                            }
                            .stallyToolbarActionStyle()
                        }
                    }
                    .navigationDestination(for: DetailRoute.self) { route in
                        detailDestination(for: route)
                    }
            }
        }

        @ViewBuilder private var destinationContent: some View {
            switch destination {
            case .library:
                LibraryView(
                    addAction: addAction,
                    restoreAction: restoreAction
                )
            case .archive:
                ArchiveView()
            case .review:
                ReviewView()
            case .insights:
                InsightsView()
            }
        }

        @ViewBuilder
        private func detailDestination(for route: DetailRoute) -> some View {
            switch route {
            case .item(let itemID):
                StallyItemDestinationView(itemID: itemID)
            }
        }
    }

    @Binding var selectedDestination: Destination
    @Binding var detailPaths: [Destination: [DetailRoute]]

    let addAction: () -> Void
    let restoreAction: () -> Void
    let settingsAction: () -> Void

    var body: some View {
        TabView(selection: $selectedDestination) {
            ForEach(Destination.collectionDestinations + Destination.reflectionDestinations) { destination in
                Tab(value: destination) {
                    Detail(
                        path: path(for: destination),
                        destination: destination,
                        addAction: addAction,
                        restoreAction: restoreAction,
                        settingsAction: settingsAction
                    )
                } label: {
                    Label {
                        Text(destination.linkDestination.title)
                    } icon: {
                        Image(systemName: destination.linkDestination.systemImageName)
                    }
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
    }

    private func path(for destination: Destination) -> Binding<[DetailRoute]> {
        .init {
            detailPaths[destination, default: []]
        } set: { path in
            detailPaths[destination] = path
        }
    }
}
