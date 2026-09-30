//
//  StallyIntentError.swift
//  Stally
//
//  Created by Codex on 2026/06/27.
//

import Foundation

enum StallyIntentError: LocalizedError, CustomLocalizedStringResourceConvertible {
    case itemNotFound
    case currentDayUnavailable
    case invalidStartInput

    var errorDescription: String? {
        String(localized: localizedStringResource)
    }

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .itemNotFound:
            .init("Item could not be found.", table: "AppIntents")
        case .currentDayUnavailable:
            .init("The current calendar day could not be read.", table: "AppIntents")
        case .invalidStartInput:
            .init("Enter a valid start as YYYY, YYYY-MM, or YYYY-MM-DD.", table: "AppIntents")
        }
    }
}
