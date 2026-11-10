import AppIntents
import Foundation
import StallyLibrary

struct PeriodEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Period")
    static let defaultQuery = PeriodEntityQuery()
    let id: UUID
    @Property(title: "Item")
    var item: ItemEntity?
    @Property(title: "Start (YYYY, YYYY-MM, or YYYY-MM-DD)")
    var startLocalDate: String?
    @Property(title: "End (YYYY, YYYY-MM, or YYYY-MM-DD)")
    var endLocalDate: String?
    @Property(title: "Ongoing")
    var isOngoing: Bool

    var summary: String {
        [startLocalDate ?? "?", isOngoing ? "…" : endLocalDate ?? "?"].joined(separator: " → ")
    }

    var displayRepresentation: DisplayRepresentation {
        .init(title: "\(item?.name ?? "")", subtitle: "\(summary)")
    }

    @MainActor
    init(_ record: ItemPeriod) {
        id = record.uuid
        item = record.item.map(ItemEntity.init)
        startLocalDate = record.startLocalDate
        endLocalDate = record.endLocalDate
        isOngoing = record.isOngoing
    }
}
