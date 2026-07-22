//
//  EnvironmentValues+StallyPersistenceStatus.swift
//  Stally
//
//  Created by Codex on 2026/07/22.
//

import SwiftUI

extension EnvironmentValues {
    private struct StallyPersistenceStatusKey: EnvironmentKey {
        static let defaultValue: StallyPlatformEnvironment.PersistenceStatus = .local
    }

    var stallyPersistenceStatus: StallyPlatformEnvironment.PersistenceStatus {
        get {
            self[StallyPersistenceStatusKey.self]
        }
        set {
            self[StallyPersistenceStatusKey.self] = newValue
        }
    }
}
