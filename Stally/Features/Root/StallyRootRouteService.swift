import Foundation
import MHPlatform
import StallyLibrary

enum StallyRootRouteService {
    enum PendingRouteResolution {
        case none
        case route(StallyRoute)
        case unsupported
    }

    @MainActor
    static func resolvePendingRoute(
        from inbox: MHObservableDeepLinkInbox,
        codec: MHDeepLinkCodec<StallyRoute>
    ) async -> PendingRouteResolution {
        guard let pendingURL = inbox.pendingURL else {
            return .none
        }

        guard let route = codec.parse(pendingURL) else {
            _ = await inbox.consumeLatestURL()
            return .unsupported
        }

        _ = await inbox.consumeLatest(using: codec)
        return .route(route)
    }

    static func apply(
        route: StallyRoute,
        to state: inout StallyRootNavigationState,
        items: [Item]
    ) {
        switch route {
        case .home:
            state.dismissEditor()
            state.path.removeAll()
        case .archive:
            state.dismissEditor()
            state.path = [.archive]
        case .backup:
            state.dismissEditor()
            state.path = [.backup]
        case .review:
            state.dismissEditor()
            state.path = [.review]
        case .settings:
            state.dismissEditor()
            state.path = [.settings]
        case .item(let itemID):
            state.dismissEditor()
            state.path = itemPath(
                for: itemID,
                items: items
            )
        case .createItem:
            state.path.removeAll()
            state.presentCreateEditor()
        }
    }
}

private extension StallyRootRouteService {
    static func itemPath(
        for itemID: UUID,
        items: [Item]
    ) -> [StallyRootNavigationState.Route] {
        guard let item = items.first(where: { $0.id == itemID }) else {
            return [.item(itemID)]
        }

        if item.isArchived {
            return [
                .archive,
                .item(itemID)
            ]
        }

        return [.item(itemID)]
    }
}
