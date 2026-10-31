import AppIntents
import Foundation
import StallyLibrary

struct PeriodEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Period")
    static let defaultQuery = PeriodEntityQuery()
    let id: UUID
    @Property(title: "Name")
    var name: String
    @Property(title: "Details")
    var details: String

    var displayRepresentation: DisplayRepresentation { .init(title: "\(name)", subtitle: "\(details)") }

    @MainActor
    init(_ record: ItemPeriod) {
        id = record.uuid
        name = record.item?.name ?? ""
        details = [record.startLocalDate ?? "?", record.isOngoing ? "…" : record.endLocalDate ?? "?"].joined(
            separator: " → "
        )
    }
}
