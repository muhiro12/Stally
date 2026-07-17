//
//  SampleDataSeed.swift
//  StallyLibrary
//
//  Created by Codex on 2026/07/17.
//

import Foundation

// The values below intentionally describe representative sample timelines.
// swiftlint:disable no_magic_numbers

struct SampleDataSeed {
    let uuid: UUID
    let input: ItemFormInput
    let createdDaysAgo: Int
    let markedDaysAgo: [Int]
    let archivedDaysAgo: Int?
}

extension SampleDataOperations {
    static let sampleItemIDs: Set<UUID> = [
        SampleItemID.blackWoolCoat,
        SampleItemID.whiteEverydaySneakers,
        SampleItemID.canvasTote,
        SampleItemID.dailyFieldNotes,
        SampleItemID.travelWeekender
    ]

    static func sampleSeeds(locale: Locale) -> [SampleDataSeed] {
        [
            .init(
                uuid: SampleItemID.blackWoolCoat,
                input: blackWoolCoat(locale: locale),
                createdDaysAgo: 84,
                markedDaysAgo: [0, 1, 4, 7, 14, 21, 35, 49, 63],
                archivedDaysAgo: nil
            ),
            .init(
                uuid: SampleItemID.whiteEverydaySneakers,
                input: whiteEverydaySneakers(locale: locale),
                createdDaysAgo: 62,
                markedDaysAgo: [0, 2, 3, 5, 8, 13, 21, 34],
                archivedDaysAgo: nil
            ),
            .init(
                uuid: SampleItemID.canvasTote,
                input: canvasTote(locale: locale),
                createdDaysAgo: 46,
                markedDaysAgo: [6, 17, 29],
                archivedDaysAgo: nil
            ),
            .init(
                uuid: SampleItemID.dailyFieldNotes,
                input: dailyFieldNotes(locale: locale),
                createdDaysAgo: 24,
                markedDaysAgo: [],
                archivedDaysAgo: nil
            ),
            .init(
                uuid: SampleItemID.travelWeekender,
                input: travelWeekender(locale: locale),
                createdDaysAgo: 150,
                markedDaysAgo: [72, 90, 121],
                archivedDaysAgo: 38
            )
        ]
    }
}

private extension SampleDataOperations {
    enum SampleItemID {
        static let blackWoolCoat = UUID(
            uuid: (
                0x53, 0x54, 0x41, 0x4C, 0x4C, 0x59, 0x40, 0x01,
                0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01
            )
        )
        static let whiteEverydaySneakers = UUID(
            uuid: (
                0x53, 0x54, 0x41, 0x4C, 0x4C, 0x59, 0x40, 0x02,
                0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02
            )
        )
        static let canvasTote = UUID(
            uuid: (
                0x53, 0x54, 0x41, 0x4C, 0x4C, 0x59, 0x40, 0x03,
                0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03
            )
        )
        static let dailyFieldNotes = UUID(
            uuid: (
                0x53, 0x54, 0x41, 0x4C, 0x4C, 0x59, 0x40, 0x04,
                0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x04
            )
        )
        static let travelWeekender = UUID(
            uuid: (
                0x53, 0x54, 0x41, 0x4C, 0x4C, 0x59, 0x40, 0x05,
                0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x05
            )
        )
    }

    static func blackWoolCoat(locale: Locale) -> ItemFormInput {
        .init(
            name: String(
                localized: LocalizedStringResource(
                    "Black Wool Coat",
                    table: "SampleData",
                    locale: locale,
                    bundle: .module
                )
            ),
            category: .clothing,
            note: String(
                localized: LocalizedStringResource(
                    "The one I reach for on cold mornings.",
                    table: "SampleData",
                    locale: locale,
                    bundle: .module
                )
            )
        )
    }

    static func whiteEverydaySneakers(locale: Locale) -> ItemFormInput {
        .init(
            name: String(
                localized: LocalizedStringResource(
                    "White Everyday Sneakers",
                    table: "SampleData",
                    locale: locale,
                    bundle: .module
                )
            ),
            category: .shoes,
            note: String(
                localized: LocalizedStringResource(
                    "Easy pair for short walks and errands.",
                    table: "SampleData",
                    locale: locale,
                    bundle: .module
                )
            )
        )
    }

    static func canvasTote(locale: Locale) -> ItemFormInput {
        .init(
            name: String(
                localized: LocalizedStringResource(
                    "Canvas Tote",
                    table: "SampleData",
                    locale: locale,
                    bundle: .module
                )
            ),
            category: .bags,
            note: String(
                localized: LocalizedStringResource(
                    "Usually comes with me when I need one extra layer.",
                    table: "SampleData",
                    locale: locale,
                    bundle: .module
                )
            )
        )
    }

    static func dailyFieldNotes(locale: Locale) -> ItemFormInput {
        .init(
            name: String(
                localized: LocalizedStringResource(
                    "Daily Field Notes",
                    table: "SampleData",
                    locale: locale,
                    bundle: .module
                )
            ),
            category: .notebooks,
            note: String(
                localized: LocalizedStringResource(
                    "Still waiting for its first stretch of regular use.",
                    table: "SampleData",
                    locale: locale,
                    bundle: .module
                )
            )
        )
    }

    static func travelWeekender(locale: Locale) -> ItemFormInput {
        .init(
            name: String(
                localized: LocalizedStringResource(
                    "Travel Weekender",
                    table: "SampleData",
                    locale: locale,
                    bundle: .module
                )
            ),
            category: .bags,
            note: String(
                localized: LocalizedStringResource(
                    "Archived because it only comes out a few times a year.",
                    table: "SampleData",
                    locale: locale,
                    bundle: .module
                )
            )
        )
    }
}

// swiftlint:enable no_magic_numbers
