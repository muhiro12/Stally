//
//  MoveStallyItemBackToLibraryIntent.swift
//  Stally
//
//  Created by Codex on 2026/06/27.
//

import AppIntents
import SwiftData

struct MoveStallyItemBackToLibraryIntent: AppIntent {
    static let title: LocalizedStringResource = .init("Move Item Back to Library", table: "AppIntents")
    static let description = IntentDescription(
        .init("Move an archived item back to Library.", table: "AppIntents")
    )
    static let isDiscoverable = false

    private static var movedDialog: IntentDialog {
        .init(.init("Moved item back to Library.", table: "AppIntents"))
    }

    private static var alreadyInLibraryDialog: IntentDialog {
        .init(.init("Item is already in Library.", table: "AppIntents"))
    }

    @Parameter(title: .init("Item", table: "AppIntents"))
    private var item: StallyItemEntity

    @Dependency private var modelContainer: ModelContainer

    @MainActor
    func perform() throws -> some IntentResult & ProvidesDialog {
        let model = try item.model(in: modelContainer.mainContext)
        let didMove = try ItemOperations.moveBackToLibrary(
            model,
            context: modelContainer.mainContext
        )
        let dialog = didMove ? Self.movedDialog : Self.alreadyInLibraryDialog
        return .result(dialog: dialog)
    }
}
