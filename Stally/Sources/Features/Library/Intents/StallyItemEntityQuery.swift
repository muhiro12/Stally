//
//  StallyItemEntityQuery.swift
//  Stally
//
//  Created by Codex on 2026/06/27.
//

import AppIntents
import SwiftData

struct StallyItemEntityQuery: EntityStringQuery {
    @Dependency private var modelContainer: ModelContainer

    @MainActor
    func entities(for identifiers: [StallyItemEntity.ID]) throws -> [StallyItemEntity] {
        let identifierSet = Set(identifiers)
        let items = try ItemOperations.items(context: modelContainer.mainContext).filter { item in
            identifierSet.contains(item.uuid.uuidString)
        }
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
        let items = try ItemOperations.activeItems(
            from: ItemOperations.items(context: modelContainer.mainContext)
        )
        return StallyItemEntity.make(from: items)
    }
}
