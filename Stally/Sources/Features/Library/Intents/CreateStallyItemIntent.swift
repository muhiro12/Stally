//
//  CreateStallyItemIntent.swift
//  Stally
//
//  Created by Codex on 2026/06/27.
//

import AppIntents
import SwiftData

struct CreateStallyItemIntent: AppIntent {
    static let title: LocalizedStringResource = .init("Create Item", table: "AppIntents")
    static let description = IntentDescription(
        .init("Create a Stally item without opening the app.", table: "AppIntents")
    )

    @Parameter(title: .init("Name", table: "AppIntents"))
    private var name: String

    @Parameter(title: .init("Category", table: "AppIntents"))
    private var category: StallyItemCategoryIntentValue

    @Parameter(title: .init("Note", table: "AppIntents"))
    private var note: String?

    @Dependency private var modelContainer: ModelContainer

    @MainActor
    func perform() throws -> some IntentResult & ProvidesDialog {
        try ItemOperations.create(
            context: modelContainer.mainContext,
            input: .init(
                name: name,
                category: category.itemCategory,
                note: note ?? ""
            )
        )

        return .result(dialog: .init(.init("Created item.", table: "AppIntents")))
    }
}
