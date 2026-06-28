//
//  StallyLogging.swift
//  Stally
//
//  Created by Codex on 2026/06/27.
//

import Foundation
import MHPlatform

enum StallyLogging {
    enum Category {
        nonisolated static let appStartup = "AppStartup"
        nonisolated static let routeExecution = "RouteExecution"
    }

    static var policy: MHLogPolicy {
        #if DEBUG
        .debugDefault
        #else
        .init(
            minimumLevel: .warning,
            maximumInMemoryEvents: MHLogPolicy.releaseDefault.maximumInMemoryEvents
        )
        #endif
    }

    @MainActor
    static func makeBootstrap() -> MHLoggingBootstrap {
        .init(
            policy: policy,
            subsystem: Bundle.main.bundleIdentifier
        )
    }

    @MainActor
    static func logger(
        logging: MHLoggingBootstrap,
        category: String,
        source: String
    ) -> MHLogger {
        logging.logger(
            category: category,
            source: source
        )
    }

    nonisolated static func metadata(
        _ pairs: (String, String?)...
    ) -> [String: String] {
        MHLogMetadata.metadata(pairs)
    }

    nonisolated static func bool(_ value: Bool) -> String {
        value ? "true" : "false"
    }

    nonisolated static func errorMetadata(
        _ error: any Error
    ) -> [String: String] {
        let errorValue = error as NSError
        return metadata(
            ("error_type", String(describing: type(of: error))),
            ("error_domain", errorValue.domain),
            ("error_code", String(errorValue.code))
        )
    }
}
