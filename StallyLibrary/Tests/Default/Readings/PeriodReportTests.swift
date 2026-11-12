import Foundation
import SwiftData
import Testing

@testable import StallyLibrary

@MainActor
struct PeriodReportTests {
    @Test
    func reportIsDatedAndOmitsUnrelatedContentWithoutSaving() throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        var draft = ItemDraft(name: "Camera", note: "Private note")
        draft.representativeURL = "https://example.com/private"
        let item = try ItemOperations.save(draft, context: context)
        try PeriodOperations.add(to: item, input: .init(start: "2026-11-10"), today: "2026-11-12", context: context)
        let text = try PeriodReadingOperations.shareText(for: item, today: "2026-11-12")
        let english = """
        Camera

        Time Together

        As of 2026-11-12

        Current: 2 exact days
        Cumulative: 2 exact days

        Only recorded periods are added. Gaps are excluded.
        """
        let japanese = """
        Camera

        一緒に過ごした時間

        2026-11-12時点

        現在の期間：正確にわかる日数：2日
        記録された期間の合計：正確にわかる日数：2日

        記録された期間だけを足し合わせます。期間の間の空白は含みません。
        """
        #expect(text == english || text == japanese)
        #expect(!context.hasChanges)
        try ItemOperations.update(item, name: "Changed", note: nil, context: context)
        #expect(text.hasPrefix("Camera\n"))
    }

    @Test
    func reportPreservesApproximationExcludedPeriodsAndPossibleOverlap() throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        let item = try ItemOperations.create(context: context, name: "Partial")
        for input in [
            PeriodInput(start: "2020", end: "2021", isOngoing: false),
            PeriodInput(start: "2021", end: "2022", isOngoing: false),
            PeriodInput(start: nil, end: nil, isOngoing: true)
        ] {
            try PeriodOperations.add(to: item, input: input, today: "2026-11-12", context: context)
        }
        let text = try PeriodReadingOperations.shareText(for: item, today: "2026-11-12")
        #expect(text.contains("Current: Not enough recorded dates") || text.contains("現在の期間：計算に必要な日付がありません"))
        #expect(text.contains("about 2 years + 0 months (partial dates)") || text.contains("部分的な日付からの概算：2年 ＋ 0か月"))
        #expect(text.contains("calculable subtotal, excluding 1 period;") || text.contains("1件の期間を除く計算可能な小計"))
        #expect(text.contains("assumes partial-date periods do not overlap") || text.contains("部分的な日付の期間は重複しないと仮定"))
        #expect(!context.hasChanges)
    }

    @Test(arguments: [0, 1, 2], [0, 1, 2])
    func reportUnitsUseIndependentPluralForms(_ count: Int, _ months: Int) {
        let reading = PeriodReading(
            exactDays: count, approximateMonths: months, approximateYears: count,
            includedCount: 1, excludedCount: count, hasApproximation: true, mayOverlap: false
        )
        let text = PeriodReadingText.describe(.init(current: reading, cumulative: reading))
        let days = count == 1 ? "1 exact day;" : "\(count) exact days;"
        let years = count == 1 ? "1 year" : "\(count) years"
        let monthText = months == 1 ? "1 month" : "\(months) months"
        #expect(text.contains(days) || text.contains("正確にわかる日数：\(count)日"))
        #expect(
            text.contains("about \(years) + \(monthText) (partial dates)")
                || text.contains("部分的な日付からの概算：\(count)年 ＋ \(months)か月")
        )
        if count > 0 {
            let periods = count == 1 ? "1 period" : "\(count) periods"
            #expect(text.hasSuffix("excluding \(periods)") || text.hasSuffix("\(count)件の期間を除く計算可能な小計"))
        } else {
            #expect(!text.contains("excluding") && !text.contains("計算可能な小計"))
        }
    }

    @Test
    func emptyHistoryDoesNotBecomeZeroAndInvalidHistoryIsRejected() throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        let item = try ItemOperations.create(context: context, name: "Unknown")
        let text = try PeriodReadingOperations.shareText(for: item, today: "2026-11-12")
        #expect(text.contains("Cumulative: Not enough recorded dates") || text.contains("記録された期間の合計：計算に必要な日付がありません"))
        #expect(!text.contains("0 exact days"))
        let period = ItemPeriod(item: item, startLocalDate: "2026-11-12", endLocalDate: "2020", isOngoing: false)
        context.insert(period)
        #expect(throws: (any Error).self) {
            try PeriodReadingOperations.shareText(for: item, today: "2026-11-12")
        }
    }
}
