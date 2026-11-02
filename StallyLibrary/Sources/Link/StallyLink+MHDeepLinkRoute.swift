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
        static let itemPathLength = 2
    }

    public var deepLinkDescriptor: MHDeepLinkDescriptor {
        switch self {
        case .destination(let destination):
            .init(pathComponents: [destination.rawValue])
        case .item(let itemID):
            .init(pathComponents: [Component.item, itemID.uuidString])
        }
    }

    public init?(deepLinkDescriptor: MHDeepLinkDescriptor) {
        let path = deepLinkDescriptor.pathComponents
        if path.count == Component.itemPathLength, path.first == Component.item {
            guard !deepLinkDescriptor.queryItems.contains(where: { $0.name == "id" }),
                  let uuid = UUID(uuidString: path[1]) else {
                return nil
            }
            self = .item(uuid)
        } else if path.count == 1, let route = path.first, let destination = StallyLinkDestination(rawValue: route) {
            self = .destination(destination)
        } else {
            return nil
        }
    }
}
