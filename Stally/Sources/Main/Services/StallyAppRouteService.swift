import Foundation
import StallyLibrary

enum StallyAppRouteService {
    static func apply(
        route: StallyRoute,
        to appModel: StallyAppModel,
        items: [Item]
    ) {
        appModel.dismissEditor()

        switch route {
        case .home:
            appModel.show(
                tab: .library,
                path: []
            )
        case .archive:
            appModel.show(
                tab: .archive,
                path: []
            )
        case .backup:
            appModel.show(
                tab: .library,
                path: [
                    .settings,
                    .backup
                ]
            )
        case .insights:
            appModel.show(
                tab: .insights,
                path: []
            )
        case .review:
            appModel.show(
                tab: .review,
                path: []
            )
        case .settings:
            appModel.show(
                tab: .library,
                path: [
                    .settings
                ]
            )
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
        }
    }
}

private extension StallyAppRouteService {
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
