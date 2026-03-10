import Foundation
import StallyLibrary

enum StallyRootRouteService {
    static func apply(
        route: StallyRoute,
        to state: StallyRootNavigationState,
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
        case .insights:
            state.dismissEditor()
            state.path = [.insights]
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
