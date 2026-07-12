//
//  StallyItemEntity.swift
//  Stally
//
//  Created by Codex on 2026/06/27.
//

import AppIntents
import SwiftData

@Observable
final class StallyItemEntity: AppEntity {
    static let defaultQuery = StallyItemEntityQuery()

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        .init(
            name: .init("Item", table: "AppIntents"),
            numericFormat: LocalizedStringResource("\(placeholder: .int) Items", table: "AppIntents")
        )
    }

    var displayRepresentation: DisplayRepresentation {
        .init(
            title: .init("\(name)", table: "AppIntents"),
            subtitle: .init("\(categoryName)", table: "AppIntents"),
            image: .init(systemName: isArchived ? "archivebox" : "tray")
        )
    }

    let id: String
    let uuid: UUID
    let name: String
    let categoryName: String
    let isArchived: Bool

    private init(
        uuid: UUID,
        name: String,
        categoryName: String,
        isArchived: Bool
    ) {
        id = uuid.uuidString
        self.uuid = uuid
        self.name = name
        self.categoryName = categoryName
        self.isArchived = isArchived
    }
    convenience init(_ model: Item) {
        self.init(
            uuid: model.uuid,
            name: model.name,
            categoryName: String(localized: model.category.title),
            isArchived: model.isArchived
        )
    }

    static func make(from model: Item) -> StallyItemEntity {
        .init(model)
    }

    static func make(from models: [Item]) -> [StallyItemEntity] {
        models.map { item in
            .init(item)
        }
    }

    func model(in context: ModelContext) throws -> Item {
        guard let model = try ItemOperations.item(context: context, uuid: uuid) else {
            throw StallyIntentError.itemNotFound
        }

        return model
    }
}
