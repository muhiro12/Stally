//
//  UndoStallyItemTodayIntent.swift
//  Stally
//
//  Created by Codex on 2026/06/27.
//

import AppIntents
import Foundation
import SwiftData

struct UndoStallyItemTodayIntent: AppIntent {
    static let title: LocalizedStringResource = .init("Undo Today's Mark", table: "AppIntents")
    static let description = IntentDescription("Remove today's mark from an item.")
    static let isDiscoverable = false

    private static var removedDialog: IntentDialog {
        .init(.init("Removed today's mark.", table: "AppIntents"))
    }

    private static var notMarkedDialog: IntentDialog {
        .init(.init("No mark for today.", table: "AppIntents"))
    }

    @Parameter(title: "Item")
    private var item: StallyItemEntity

    @Dependency private var modelContainer: ModelContainer

    @MainActor
    func perform() throws -> some IntentResult & ProvidesDialog {
        let now = Date()
        let timeZone = TimeZone.current
        guard let today = LocalDay(containing: now, in: timeZone) else {
            throw CocoaError(.coderInvalidValue)
        }

        let model = try item.model(in: modelContainer.mainContext)
        let didUndo = try ItemOperations.undoMark(
            model,
            on: today,
            context: modelContainer.mainContext
        )
        let dialog = didUndo ? Self.removedDialog : Self.notMarkedDialog
        return .result(dialog: dialog)
    }
}
