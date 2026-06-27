//
//  ArchiveStallyItemIntent.swift
//  Stally
//
//  Created by Codex on 2026/06/27.
//

import AppIntents
import SwiftData

struct ArchiveStallyItemIntent: AppIntent {
    static let title: LocalizedStringResource = .init("Archive Item", table: "AppIntents")
    static let description = IntentDescription("Move an item into Archive while preserving its history.")
    static let isDiscoverable = false

    private static var archivedDialog: IntentDialog {
        .init(.init("Archived item.", table: "AppIntents"))
    }

    private static var alreadyArchivedDialog: IntentDialog {
        .init(.init("Item is already archived.", table: "AppIntents"))
    }

    @Parameter(title: "Item")
    private var item: StallyItemEntity

    @Dependency private var modelContainer: ModelContainer

    @MainActor
    func perform() throws -> some IntentResult & ProvidesDialog {
        let model = try item.model(in: modelContainer.mainContext)
        let didArchive = try ItemOperations.archive(
            model,
            on: .now,
            context: modelContainer.mainContext
        )
        let dialog = didArchive ? Self.archivedDialog : Self.alreadyArchivedDialog
        return .result(dialog: dialog)
    }
}
