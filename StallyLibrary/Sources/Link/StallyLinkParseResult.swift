//
//  StallyLinkParseResult.swift
//  StallyLibrary
//
//  Created by Codex on 2026/06/26.
//

/// Result of parsing an incoming Stally URL.
public enum StallyLinkParseResult: Equatable, Sendable {
    case supported(StallyLink)
    case unsupported
}
