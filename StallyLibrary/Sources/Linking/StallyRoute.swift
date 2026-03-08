import Foundation
import MHDeepLinking

/// Deep-linkable routes supported by Stally.
public enum StallyRoute: Equatable, Hashable, Sendable, MHDeepLinkRoute {
    /// Opens the default Home experience.
    case home

    /// Opens the archived item list.
    case archive

    /// Opens backup export and restore tools.
    case backup

    /// Opens the review workflow.
    case review

    /// Opens the Settings screen.
    case settings

    /// Opens the create-item editor.
    case createItem

    /// Opens one specific item.
    case item(UUID)

    /// Encodes the route as a deep-link descriptor.
    public var deepLinkDescriptor: MHDeepLinkDescriptor {
        switch self {
        case .home:
            .init(pathComponents: ["home"])
        case .archive:
            .init(pathComponents: ["archive"])
        case .backup:
            .init(pathComponents: ["backup"])
        case .review:
            .init(pathComponents: ["review"])
        case .settings:
            .init(pathComponents: ["settings"])
        case .createItem:
            .init(pathComponents: ["create"])
        case .item(let itemID):
            .init(
                pathComponents: ["item"],
                queryItems: [
                    .init(name: "id", value: itemID.uuidString.lowercased())
                ]
            )
        }
    }

    /// Decodes a route from a deep-link descriptor.
    public init?(
        deepLinkDescriptor: MHDeepLinkDescriptor
    ) {
        switch deepLinkDescriptor.pathComponents {
        case [], ["home"]:
            self = .home
        case ["archive"]:
            self = .archive
        case ["backup"]:
            self = .backup
        case ["review"]:
            self = .review
        case ["settings"]:
            self = .settings
        case ["create"]:
            self = .createItem
        case ["item"]:
            guard let itemID = deepLinkDescriptor.queryItems.first(where: { queryItem in
                queryItem.name == "id"
            })?.value,
            let uuid = UUID(uuidString: itemID)
            else {
                return nil
            }

            self = .item(uuid)
        default:
            return nil
        }
    }
}
