//
//  StallyIntentRoute.swift
//  Stally
//
//  Created by Codex on 2026/06/27.
//

import Foundation

struct StallyIntentRoute: Equatable, Identifiable {
    let id: UUID
    let link: StallyLink

    init(link: StallyLink) {
        id = .init()
        self.link = link
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}
