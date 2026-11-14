//
//  StallyLink.swift
//  StallyLibrary
//
//  Created by Codex on 2026/06/26.
//

import Foundation

/// A supported Stally route that can be shared or opened.
public enum StallyLink: Equatable, Sendable {
    case destination(StallyLinkDestination)
    case item(UUID)
}
