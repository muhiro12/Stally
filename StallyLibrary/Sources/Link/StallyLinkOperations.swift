//
//  StallyLinkOperations.swift
//  StallyLibrary
//
//  Created by Codex on 2026/06/26.
//

import Foundation
import MHPlatformCore

/// Cross-surface shareable link use cases.
public enum StallyLinkOperations {
    /// Product URL scheme.
    public static let scheme = "stally"

    /// Builds a shareable URL for a supported Stally link.
    public static func url(for link: StallyLink) -> URL {
        codec.url(for: link, transport: .customScheme) ?? fallbackURL(for: link)
    }

    /// Parses an incoming URL into a supported Stally link.
    public static func parse(_ url: URL) -> StallyLinkParseResult {
        guard let link = codec.parse(url) else {
            return .unsupported
        }
        return .supported(link)
    }
}

private extension StallyLinkOperations {
    static let codec = MHDeepLinkCodec<StallyLink>(
        configuration: .init(
            customScheme: scheme,
            preferredUniversalLinkHost: "",
            allowedUniversalLinkHosts: [],
            universalLinkPathPrefix: "",
            preferredTransport: .customScheme
        )
    )

    static func fallbackURL(for link: StallyLink) -> URL {
        switch link {
        case .destination(let destination):
            URL(string: "\(scheme)://\(destination.rawValue)") ?? URL(fileURLWithPath: "/")
        case .item(let itemID):
            URL(string: "\(scheme)://item/\(itemID.uuidString)") ?? URL(fileURLWithPath: "/")
        }
    }
}
