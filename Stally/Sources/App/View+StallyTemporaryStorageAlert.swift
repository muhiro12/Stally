//
//  View+StallyTemporaryStorageAlert.swift
//  Stally
//
//  Created by Codex on 2026/07/22.
//

import SwiftUI

extension View {
    func stallyTemporaryStorageAlert() -> some View {
        modifier(StallyTemporaryStorageAlertModifier())
    }
}
