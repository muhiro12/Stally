import AppIntents
import SwiftData

/// A system value snapshot; actions resolve its UUID against the current store.
struct StallyItemEntity: AppEntity {
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

    var categoryName: String {
        String(localized: category.itemCategory.title)
    }

    let id: String
    let uuid: UUID

    @Property(title: .init("Name", table: "AppIntents"))
    var name: String
    @Property(title: .init("Category", table: "AppIntents"))
    var category: StallyItemCategoryIntentValue
    @Property(title: .init("Archived", table: "AppIntents"))
    var isArchived: Bool
    @Property(title: .init("Record Marks", table: "AppIntents"))
    var recordsMarks: Bool
    @Property(title: .init("Start", table: "AppIntents"))
    var start: String?

    @MainActor
    init(_ model: Item) {
        id = model.uuid.uuidString
        uuid = model.uuid
        name = model.name
        category = .init(model.category)
        isArchived = model.isArchived
        recordsMarks = model.recordsMarks
        start = model.startRawValue
    }

    @MainActor
    static func make(from models: [Item]) -> [Self] {
        models.map(Self.init)
    }

    @MainActor
    func model(in context: ModelContext) throws -> Item {
        guard let model = try ItemOperations.item(context: context, uuid: uuid) else {
            throw StallyIntentError.itemNotFound
        }
        return model
    }
}
