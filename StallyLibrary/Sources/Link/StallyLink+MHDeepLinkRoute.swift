//
//  StallyLink+MHDeepLinkRoute.swift
//  StallyLibrary
//
//  Created by Codex on 2026/06/27.
//

import Foundation
import MHPlatformCore

extension StallyLink: MHDeepLinkRoute {
    private enum Component {
        static let item = "item"
        static let id = "id"
    }

    public var deepLinkDescriptor: MHDeepLinkDescriptor {
        switch self {
        case .destination(let destination):
            .init(pathComponents: [destination.rawValue])
        case .item(let itemID):
            .init(
                pathComponents: [Component.item],
                queryItems: [.init(name: Component.id, value: itemID.uuidString)]
            )
        }
    }

    public init?(deepLinkDescriptor: MHDeepLinkDescriptor) {
        let path = deepLinkDescriptor.pathComponents
        guard path.count == 1, let route = path.first else {
            return nil
        }
        if route == Component.item {
            let ids = deepLinkDescriptor.queryItems.filter { $0.name == Component.id }
            guard ids.count == 1, let value = ids.first?.value, let uuid = UUID(uuidString: value) else {
                return nil
            }
            self = .item(uuid)
        } else if let destination = StallyLinkDestination(rawValue: route) {
            self = .destination(destination)
        } else {
            return nil
        }
    }
}
