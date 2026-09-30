//
//  StallyItemEntityQuery.swift
//  Stally
//
//  Created by Codex on 2026/06/27.
//

import AppIntents
import SwiftData

struct StallyItemEntityQuery: EntityStringQuery {
    private static let suggestionLimit = 40

    @Dependency private var modelContainer: ModelContainer

    @MainActor
    func entities(for identifiers: [StallyItemEntity.ID]) throws -> [StallyItemEntity] {
        let items = try ItemOperations.items(
            context: modelContainer.mainContext,
            uuids: identifiers.compactMap(UUID.init(uuidString:))
        )
        return StallyItemEntity.make(from: items)
    }

    @MainActor
    func entities(matching string: String) throws -> [StallyItemEntity] {
        let items = try ItemOperations.items(
            context: modelContainer.mainContext,
            matchingName: string
        )
        return StallyItemEntity.make(from: items)
    }

    @MainActor
    func suggestedEntities() throws -> [StallyItemEntity] {
        let items = try ItemOperations.suggestedItems(
            context: modelContainer.mainContext,
            limit: Self.suggestionLimit
        )
        return StallyItemEntity.make(from: items)
    }
}
