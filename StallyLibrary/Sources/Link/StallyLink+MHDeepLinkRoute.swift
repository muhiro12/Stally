//
//  StallyLink+MHDeepLinkRoute.swift
//  StallyLibrary
//
//  Created by Codex on 2026/06/27.
//

import Foundation
import MHPlatformCore

extension StallyLink: MHDeepLinkRoute {
    private enum LinkComponent {
        static let item = "item"
    }

    private enum LinkPathComponentCount {
        static let destination = 1
        static let item = 2
    }

    public var deepLinkDescriptor: MHDeepLinkDescriptor {
        switch self {
        case .destination(let destination):
            .init(pathComponents: [destination.rawValue])
        case .item(let itemID):
            .init(
                pathComponents: [
                    LinkComponent.item,
                    itemID.uuidString
                ]
            )
        }
    }

    public init?(deepLinkDescriptor: MHDeepLinkDescriptor) {
        let pathComponents = deepLinkDescriptor.pathComponents

        if pathComponents.count == LinkPathComponentCount.item,
           pathComponents[0] == LinkComponent.item {
            let itemIDValue = pathComponents[1]
            guard let itemID = UUID(uuidString: itemIDValue) else {
                return nil
            }
            self = .item(itemID)
            return
        }

        if pathComponents.count == LinkPathComponentCount.destination {
            let destinationValue = pathComponents[0]
            guard let destination = StallyLinkDestination(rawValue: destinationValue) else {
                return nil
            }
            self = .destination(destination)
            return
        }

        return nil
    }
}
