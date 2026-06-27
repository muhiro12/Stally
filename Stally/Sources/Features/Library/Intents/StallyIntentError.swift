//
//  StallyIntentError.swift
//  Stally
//
//  Created by Codex on 2026/06/27.
//

import Foundation

enum StallyIntentError: LocalizedError {
    case itemNotFound

    var errorDescription: String? {
        switch self {
        case .itemNotFound:
            String(localized: "Item could not be found.", table: "AppIntents")
        }
    }
}
