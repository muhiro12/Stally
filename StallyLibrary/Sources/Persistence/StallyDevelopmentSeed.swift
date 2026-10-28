#if DEBUG
import Foundation
import SwiftData

/// Synthetic English record content, not user-facing sample creation or historical fixtures.
@MainActor
enum StallyDevelopmentSeed {
    private static let referenceTimestamp: TimeInterval = 1_793_145_600
    private static let referenceDate = Date(timeIntervalSince1970: referenceTimestamp)

    static func insert(in context: ModelContext) throws {
        let everyday = Tag(name: "Everyday")
        let places = Tag(name: "Places")
        let separateEveryday = Tag(name: "Everyday")
        for tag in [everyday, places, separateEveryday] {
            context.insert(tag)
        }
        let bag = item("Everyday backpack", note: "A light bag for walks and small journeys.", in: context)
        bag.isFavorite = true
        bag.tags = [everyday]
        mark("2026-10-27", for: bag, in: context)
        mark("2026-10-27T09:30", for: bag, in: context)
        period(start: "2024", for: bag, in: context, end: "2025-10", ongoing: false)
        period(start: "2026-02-01", for: bag, in: context)

        let cafe = item("Riverside café", note: "A window seat and time to read.", in: context)
        cafe.tags = [places, everyday]
        mark("2026-10-26T14:15", for: cafe, in: context)
        mark("2026-10-27", for: cafe, in: context)
        period(start: "2025-05", for: cafe, in: context)

        let studio = item("Old studio", note: "A place worth remembering after moving on.", in: context)
        studio.isArchived = true
        studio.isFavorite = true
        studio.isMarkRecordingEnabled = false
        studio.tags = [places]
        mark("2025-12-20", for: studio, in: context)
        period(start: nil, for: studio, in: context, end: "2025", ongoing: false)

        let glasses = item("Reading glasses", note: "No exact start date remembered.", in: context)
        glasses.isMarkRecordingEnabled = false
        glasses.tags = [separateEveryday]
        period(start: nil, for: glasses, in: context)
        _ = item("Travel journal", note: "", in: context)
        try RecordMutation.save(context)
    }
}

private extension StallyDevelopmentSeed {
    static func item(_ name: String, note: String, in context: ModelContext) -> Item {
        let item = Item(name: name, note: note)
        item.createdAt = referenceDate
        context.insert(item)
        return item
    }

    static func mark(_ date: String, for item: Item, in context: ModelContext) {
        let mark = ItemMark(item: item, localDateTime: date)
        mark.createdAt = referenceDate
        context.insert(mark)
    }

    static func period(
        start: String?,
        for item: Item,
        in context: ModelContext,
        end: String? = nil,
        ongoing: Bool = true
    ) {
        let period = ItemPeriod(item: item, startLocalDate: start, endLocalDate: end, isOngoing: ongoing)
        period.createdAt = referenceDate
        context.insert(period)
    }
}
#endif
