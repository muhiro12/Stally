#if DEBUG
import Foundation
import SwiftData

/// Synthetic records localized at creation, shared by development setup and Previews.
@MainActor
enum StallyDevelopmentSeed {
    private static let referenceTimestamp: TimeInterval = 1_793_145_600
    private static let referenceDate = Date(timeIntervalSince1970: referenceTimestamp)

    static func insert(in context: ModelContext) throws {
        try insert(in: context, locale: .current)
    }

    static func insert(in context: ModelContext, locale: Locale) throws {
        let everyday = Tag(name: localized("Everyday", locale: locale))
        let places = Tag(name: localized("Places", locale: locale))
        let separateEveryday = Tag(name: localized("Everyday", locale: locale))
        for tag in [everyday, places, separateEveryday] {
            context.insert(tag)
        }
        let bag = item(
            localized("Everyday backpack", locale: locale),
            note: localized("A light bag for walks and small journeys.", locale: locale),
            in: context
        )
        bag.isFavorite = true
        bag.tags = [everyday]
        mark("2026-10-27", for: bag, in: context)
        mark("2026-10-27T09:30", for: bag, in: context)
        period(start: "2024", for: bag, in: context, end: "2025-10", ongoing: false)
        period(start: "2026-02-01", for: bag, in: context)

        let cafe = item(
            localized("Riverside café", locale: locale),
            note: localized("A window seat and time to read.", locale: locale),
            in: context
        )
        cafe.tags = [places, everyday]
        mark("2026-10-26T14:15", for: cafe, in: context)
        mark("2026-10-27", for: cafe, in: context)
        period(start: "2025-05", for: cafe, in: context)

        let studio = item(
            localized("Old studio", locale: locale),
            note: localized("A place worth remembering after moving on.", locale: locale),
            in: context
        )
        studio.isArchived = true
        studio.isFavorite = true
        studio.isMarkRecordingEnabled = false
        studio.tags = [places]
        mark("2025-12-20", for: studio, in: context)
        period(start: nil, for: studio, in: context, end: "2025", ongoing: false)

        let glasses = item(
            localized("Reading glasses", locale: locale),
            note: localized("No exact start date remembered.", locale: locale),
            in: context
        )
        glasses.isMarkRecordingEnabled = false
        glasses.tags = [separateEveryday]
        period(start: nil, for: glasses, in: context)
        _ = item(localized("Travel journal", locale: locale), note: "", in: context)
        try RecordMutation.save(context)
    }
}

private extension StallyDevelopmentSeed {
    static func localized(_ value: String.LocalizationValue, locale: Locale) -> String {
        String(localized: LocalizedStringResource(
            value,
            table: "DevelopmentSamples",
            locale: locale,
            bundle: .atURL(Bundle.module.bundleURL)
        ))
    }

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
