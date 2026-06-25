//
//  StallyLinkOperations.swift
//  StallyLibrary
//
//  Created by Codex on 2026/06/26.
//

import Foundation

/// Cross-surface shareable link use cases.
public enum StallyLinkOperations {
    /// Product URL scheme.
    public static let scheme = "stally"

    /// Builds a shareable URL for a supported Stally link.
    public static func url(for link: StallyLink) -> URL {
        switch link {
        case .destination(let destination):
            return destinationURL(destination)
        case .item(let itemID):
            return itemURL(itemID)
        }
    }

    /// Parses an incoming URL into a supported Stally link.
    public static func parse(_ url: URL) -> StallyLinkParseResult {
        guard url.scheme == scheme,
              let host = url.host(percentEncoded: false) else {
            return .unsupported
        }

        if host == LinkComponent.item {
            return parseItem(url)
        }

        guard url.pathComponents.isEmpty || url.pathComponents == ["/"],
              let destination = StallyLinkDestination(rawValue: host) else {
            return .unsupported
        }

        return .supported(.destination(destination))
    }
}

private extension StallyLinkOperations {
    enum LinkComponent {
        static let item = "item"
    }

    static func destinationURL(_ destination: StallyLinkDestination) -> URL {
        components(host: destination.rawValue).url ?? fallbackURL(host: destination.rawValue)
    }

    static func itemURL(_ itemID: UUID) -> URL {
        components(host: LinkComponent.item, path: "/\(itemID.uuidString)").url ?? fallbackURL(
            host: LinkComponent.item,
            path: "/\(itemID.uuidString)"
        )
    }

    static func parseItem(_ url: URL) -> StallyLinkParseResult {
        let pathComponents = url.pathComponents.filter { component in
            component != "/"
        }

        guard pathComponents.count == 1,
              let itemID = UUID(uuidString: pathComponents[0]) else {
            return .unsupported
        }

        return .supported(.item(itemID))
    }

    static func components(host: String, path: String = "") -> URLComponents {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.path = path
        return components
    }

    static func fallbackURL(host: String, path: String = "") -> URL {
        URL(string: "\(scheme)://\(host)\(path)") ?? URL(fileURLWithPath: "/")
    }
}
