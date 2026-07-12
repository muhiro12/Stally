//
//  MarkStallyItemTodayIntent.swift
//  Stally
//
//  Created by Codex on 2026/06/27.
//

import AppIntents
import Foundation
import SwiftData

struct MarkStallyItemTodayIntent: AppIntent {
    static let title: LocalizedStringResource = .init("Mark Today", table: "AppIntents")
    static let description = IntentDescription("Mark that you chose an item today.")

    private static var markedDialog: IntentDialog {
        .init(.init("Marked today.", table: "AppIntents"))
    }

    private static var alreadyMarkedDialog: IntentDialog {
        .init(.init("Already marked today.", table: "AppIntents"))
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
        let didMark = try ItemOperations.mark(
            model,
            on: today,
            today: today,
            context: modelContainer.mainContext
        )
        let dialog = didMark ? Self.markedDialog : Self.alreadyMarkedDialog
        return .result(dialog: dialog)
    }
}
