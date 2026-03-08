import Foundation
import MHDeepLinking

public enum StallyRoute: Equatable, Sendable, MHDeepLinkRoute {
    case home
    case archive
    case backup
    case review
    case settings
    case createItem
    case item(UUID)

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

    public init?(
        deepLinkDescriptor: MHDeepLinkDescriptor
    ) {
        switch deepLinkDescriptor.pathComponents {
        case []:
            self = .home
        case ["home"]:
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
                let uuid = UUID(uuidString: itemID) else {
                return nil
            }

            self = .item(uuid)
        default:
            return nil
        }
    }
}

public enum StallyDeepLinking {
    public static let configuration = MHDeepLinkConfiguration(
        customScheme: "stally",
        preferredUniversalLinkHost: "stally.muhiro12.com",
        allowedUniversalLinkHosts: ["stally.muhiro12.com"],
        universalLinkPathPrefix: "app",
        preferredTransport: .customScheme
    )

    public static func codec() -> MHDeepLinkCodec<StallyRoute> {
        .init(configuration: configuration)
    }
}
