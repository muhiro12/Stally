#if DEBUG
// Representative timeline offsets and bounded stress counts are fixture values.
// swiftlint:disable no_magic_numbers
import Foundation

extension StallyFixtureOperations {
    static func seeds(for profile: StallyFixtureProfile, locale: Locale, photoData: Data?) -> [SampleDataSeed] {
        let typical = SampleDataOperations.sampleSeeds(locale: locale).enumerated().map { offset, seed in
            SampleDataSeed(
                uuid: identifier(item: UInt16(offset + 1), mark: 0),
                input: .init(
                    name: seed.input.name,
                    category: seed.input.category,
                    note: seed.input.note,
                    photoData: offset == 0 ? photoData : nil
                ),
                createdDaysAgo: seed.createdDaysAgo,
                markedDaysAgo: seed.markedDaysAgo,
                archivedDaysAgo: seed.archivedDaysAgo
            )
        }
        switch profile {
        case .empty:
            return []
        case .typical:
            return typical
        case .dense:
            return typical + denseSeeds(locale: locale, photoData: photoData)
        case .integration:
            return typical + trackingSeeds(locale: locale)
        case .timeTogether:
            return trackingSeeds(locale: locale)
        case .history:
            return historySeeds(locale: locale)
        case .stress:
            return stressSeeds()
        }
    }
}

private extension StallyFixtureOperations {
    static func denseSeeds(locale: Locale, photoData: Data?) -> [SampleDataSeed] {
        [
            longTextSeed(locale: locale, photoData: photoData),
            .init(
                uuid: StallyFixtureItem.smallNotebook.id,
                input: .init(
                    name: text("Small Black Notebook", locale: locale),
                    category: .notebooks,
                    note: text("Lives near the desk for small thoughts.", locale: locale)
                ),
                createdDaysAgo: 37,
                markedDaysAgo: [12, 18, 25],
                archivedDaysAgo: nil
            ),
            .init(
                uuid: StallyFixtureItem.rainShell.id,
                input: .init(
                    name: text("Rain Shell", locale: locale),
                    category: .clothing,
                    note: text("Quietly useful when the weather turns.", locale: locale)
                ),
                createdDaysAgo: 91,
                markedDaysAgo: [2, 31, 58],
                archivedDaysAgo: nil
            ),
            .init(
                uuid: StallyFixtureItem.cardCase.id,
                input: .init(
                    name: text("Leather Card Case", locale: locale),
                    category: .other,
                    note: ""
                ),
                createdDaysAgo: 19,
                markedDaysAgo: [1, 9],
                archivedDaysAgo: nil
            ),
            .init(
                uuid: StallyFixtureItem.winterScarf.id,
                input: .init(
                    name: text("Winter Scarf", locale: locale),
                    category: .clothing,
                    note: text("Preserved for colder days.", locale: locale)
                ),
                createdDaysAgo: 180,
                markedDaysAgo: [80, 104, 132, 151],
                archivedDaysAgo: 28
            )
        ]
    }

    static func longTextSeed(locale: Locale, photoData: Data?) -> SampleDataSeed {
        .init(
            uuid: StallyFixtureItem.longNameSweater.id,
            input: .init(
                name: text("Soft Navy Sweater With A Long Familiar Name", locale: locale),
                category: .clothing,
                note: text(
                    """
                        Kept for slow mornings and the days that need something familiar.
                        The longer note makes dense and Dynamic Type previews easier to inspect.
                        """,
                    locale: locale
                ),
                photoData: photoData
            ),
            createdDaysAgo: 118,
            markedDaysAgo: [39, 52, 68, 81, 97],
            archivedDaysAgo: nil
        )
    }

    static func trackingSeeds(locale: Locale) -> [SampleDataSeed] {
        [
            trackingSeed(.home, name: "Home", start: "2020", archived: false, locale: locale),
            trackingSeed(.windowPlant, name: "Window Plant", start: "2020-09", archived: false, locale: locale),
            trackingSeed(.archivedPlant, name: "Archived Plant", start: "2020-09-13", archived: true, locale: locale)
        ]
    }

    static func trackingSeed(
        _ record: StallyFixtureItem,
        name: String.LocalizationValue,
        start: String,
        archived: Bool,
        locale: Locale
    ) -> SampleDataSeed {
        .init(
            uuid: record.id,
            input: .init(name: text(name, locale: locale), category: .other),
            createdDaysAgo: Int(record.rawValue),
            markedDaysAgo: [],
            archivedDaysAgo: archived ? 1 : nil,
            tracking: .init(recordsMarks: false, start: .init(rawValue: start))
        )
    }

    static func historySeeds(locale: Locale) -> [SampleDataSeed] {
        SampleDataOperations.sampleSeeds(locale: locale).enumerated().map { offset, seed in
            .init(
                uuid: identifier(item: UInt16(offset + 1), mark: 0),
                input: seed.input,
                createdDaysAgo: 365 + offset,
                markedDaysAgo: Array(0..<90),
                archivedDaysAgo: offset.isMultiple(of: 2) ? 1 : nil
            )
        }
    }

    static func stressSeeds() -> [SampleDataSeed] {
        (0..<500).map { offset in
            .init(
                uuid: identifier(item: UInt16(1_000 + offset), mark: 0),
                input: .init(name: "Fixture Item \(offset + 1)", category: .other),
                createdDaysAgo: 365 + offset,
                markedDaysAgo: offset.isMultiple(of: 2) ? Array(0..<25) : [],
                archivedDaysAgo: offset.isMultiple(of: 5) ? 1 : nil,
                tracking: .init(recordsMarks: offset.isMultiple(of: 2), start: .init(rawValue: "2020-09"))
            )
        }
    }

    static func text(_ key: String.LocalizationValue, locale: Locale) -> String {
        String(localized: LocalizedStringResource(key, table: "SampleData", locale: locale, bundle: .module))
    }
}
// swiftlint:enable no_magic_numbers
#endif
