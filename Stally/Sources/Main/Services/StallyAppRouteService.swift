import Foundation
import StallyLibrary

enum StallyAppRouteService {
    static func apply(
        route: StallyRoute,
        to appModel: StallyAppModel,
        items: [Item]
    ) {
        appModel.dismissEditor()

        if let destination = staticDestination(for: route) {
            appModel.show(
                tab: destination.tab,
                path: destination.path
            )
            return
        }

        switch route {
        case .item(let itemID):
            appModel.show(
                tab: hostTab(
                    for: itemID,
                    items: items
                ),
                path: [
                    .item(itemID)
                ]
            )
        case .createItem:
            appModel.resetNavigation(selecting: .library)
            appModel.presentCreateEditor()
        case .home, .archive, .backup, .insights, .review, .settings:
            break
        }
    }
}

private extension StallyAppRouteService {
    static func staticDestination(
        for route: StallyRoute
    ) -> (
        tab: StallyAppModel.Tab,
        path: [StallyAppModel.StackDestination]
    )? {
        switch route {
        case .home:
            (.library, [])
        case .archive:
            (.archive, [])
        case .backup:
            (
                .library,
                [
                    .settings,
                    .backup
                ]
            )
        case .insights:
            (.insights, [])
        case .review:
            (.review, [])
        case .settings:
            (
                .library,
                [
                    .settings
                ]
            )
        case .item, .createItem:
            nil
        }
    }

    static func hostTab(
        for itemID: UUID,
        items: [Item]
    ) -> StallyAppModel.Tab {
        guard let item = items.first(where: { $0.id == itemID }) else {
            return .library
        }

        return item.isArchived ? .archive : .library
    }
}
