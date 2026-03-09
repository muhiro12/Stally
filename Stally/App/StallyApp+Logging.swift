//
//  StallyApp+Logging.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/03/08.
//

import MHLogging

extension StallyApp {
    nonisolated static let loggerFactory = MHLoggerFactory.osLogDefault

    nonisolated static func logger(
        category: String,
        source: String = #fileID
    ) -> MHLogger {
        loggerFactory.logger(
            category: category,
            source: source
        )
    }
}
