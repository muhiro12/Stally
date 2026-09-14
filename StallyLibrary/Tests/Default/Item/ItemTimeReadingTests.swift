import Foundation
@testable import StallyLibrary
import SwiftData
import Testing

@Suite
struct ItemTimeReadingTests {
    @Test
    func `localized readings keep day month year uncertainty and unavailable states`() throws {
        let today = try #require(LocalDay(year: 2_026, month: 9, day: 14))
        for (rawValue, english, japanese) in [
            ("2026-09-14", "Starts Today", "今日から"),
            ("2026-09-13", "1 day", "1日"),
            ("2026-09-12", "2 days", "2日"),
            ("2026-09", "Less than a month", "1か月未満"),
            ("2026-08", "About 0–1 months", "約0〜1か月"),
            ("2020-09", "About 71–72 months", "約71〜72か月"),
            ("2026", "Less than a year", "1年未満"),
            ("2020", "About 5–6 years", "約5〜6年"),
            ("2027", "Not Started", "開始前")
        ] {
            let start = try #require(ItemStart(rawValue: rawValue))
            let snapshot = ItemTimeOperations.snapshot(start: start, today: today)
            #expect(ItemTimeOperations.elapsedText(for: snapshot, locale: .init(identifier: "en_US")) == english)
            #expect(ItemTimeOperations.elapsedText(for: snapshot, locale: .init(identifier: "ja_JP")) == japanese)
        }
        #expect(ItemTimeOperations.elapsedText(for: .unknown, locale: .init(identifier: "en")) == "Not Set")
        #expect(ItemTimeOperations.elapsedText(for: .invalidStart, locale: .init(identifier: "ja")) == "アイテムの開始日が無効です")
    }

    @Test
    func `start labels do not expose invented date components`() throws {
        for (rawValue, english, japanese) in [
            ("2020", "2020", "2020年"),
            ("2020-09", "September 2020", "2020年9月"),
            ("2020-09-14", "September 14, 2020", "2020年9月14日")
        ] {
            let start = try #require(ItemStart(rawValue: rawValue))
            #expect(ItemTimeOperations.startText(for: start, locale: .init(identifier: "en_US")) == english)
            #expect(ItemTimeOperations.startText(for: start, locale: .init(identifier: "ja_JP")) == japanese)
        }
    }
}

extension SwiftDataOperationsTests {
    @Suite
    struct ItemTimeReportTests {
        @Test
        func `time reports are repeatable read only and omit unrelated private fields`() throws {
            let context = ModelContext(try StallyModelContainerFactory.inMemory())
            let today = try #require(LocalDay(year: 2_026, month: 9, day: 14))
            let item = try ItemOperations.create(
                context: context,
                input: .init(
                    name: "Home",
                    category: .other,
                    note: "Private address",
                    photoData: try TestPhotoFixtures.preparedData()
                ),
                tracking: .init(recordsMarks: false, start: try #require(ItemStart(rawValue: "2020"))),
                today: today
            )
            try ItemOperations.archive(item, on: .now, context: context)
            let createdAt = item.createdAt
            let photo = item.photoData
            let report = ItemTimeOperations.report(for: item, today: today, locale: .init(identifier: "en_US"))
            #expect(report == [
                "Home", "Elapsed Time: About 5–6 years", "Start: 2020",
                "As of: 2026-09-14", "Archived. Elapsed time continues."
            ].joined(separator: "\n"))
            #expect(ItemTimeOperations.report(for: item, today: today, locale: .init(identifier: "en_US")) == report)
            let japanese = ItemTimeOperations.report(for: item, today: today, locale: .init(identifier: "ja_JP"))
            #expect(japanese.contains("経過時間: 約5〜6年"))
            #expect(japanese.contains("開始日: 2020年"))
            #expect(!report.contains(item.note))
            #expect(!report.contains(item.uuid.uuidString))
            #expect(item.createdAt == createdAt)
            #expect(item.photoData == photo)
            #expect(item.marks.isEmpty)
            #expect(!context.hasChanges)
        }
    }
}
