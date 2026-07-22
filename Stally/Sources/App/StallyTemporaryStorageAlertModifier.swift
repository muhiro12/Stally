//
//  StallyTemporaryStorageAlertModifier.swift
//  Stally
//
//  Created by Codex on 2026/07/22.
//

import SwiftUI

struct StallyTemporaryStorageAlertModifier: ViewModifier {
    @Environment(\.stallyPersistenceStatus)
    private var persistenceStatus
    @State private var isPresentingAlert = false

    func body(content: Content) -> some View {
        content
            .alert("Storage Is Temporary", isPresented: $isPresentingAlert) {
                Button("OK", role: .cancel) {
                    isPresentingAlert = false
                }
            } message: {
                Text(
                    "Stally could not open persistent storage. Changes made in this launch will not be saved."
                )
            }
            .task(id: persistenceStatus) {
                presentAlertIfNeeded()
            }
    }

    private func presentAlertIfNeeded() {
        guard persistenceStatus == .temporaryLocal else {
            return
        }

        isPresentingAlert = true
    }
}
