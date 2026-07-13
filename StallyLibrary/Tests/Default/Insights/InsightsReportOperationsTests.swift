//
//  InsightsReportOperationsTests.swift
//  StallyLibraryTests
//
//  Created by Codex on 2026/07/13.
//

import Foundation
@testable import StallyLibrary
import Testing

struct InsightsReportOperationsTests {
    @Test
    func `report includes scope activity spotlight and next moves`() {
        let item = Item(
            name: "Canvas Tote",
            category: .bags,
            note: "",
            createdAt: .init(timeIntervalSince1970: 1_750_000_000),
            uuid: .init(),
            photoData: nil,
            archivedAt: nil
        )
        let snapshot = InsightsSnapshot(
            options: .init(range: .thirtyDays),
            totalMarks: 3,
            activeDays: 2,
            uniqueMarkedItems: 1,
            uniqueMarkedCategories: 1,
            topItems: [
                .init(item: item, marksInRange: 3, totalMarks: 3, lastMarkedDay: nil)
            ],
            quietItems: [],
            currentStreak: 1,
            bestStreak: 2,
            categoryShares: [
                .init(category: .bags, markCount: 3, fraction: 1)
            ],
            weekdayActivity: [.init(weekday: 6, markCount: 3)],
            monthlyActivity: [.init(year: 2_026, month: 7, markCount: 3)],
            noteCoverage: .init(coveredCount: 0, totalCount: 1),
            photoCoverage: .init(coveredCount: 0, totalCount: 1),
            recommendations: [
                .init(kind: .protectCurrentStreak)
            ]
        )

        let report = InsightsReportOperations.report(
            for: snapshot,
            locale: .init(identifier: "en")
        )

        #expect(report.contains("Stally Insights"))
        #expect(report.contains("Scope: 30 Days · Active items only"))
        #expect(report.contains("Marks: 3"))
        #expect(report.contains("Rhythm"))
        #expect(report.contains("Friday: 3"))
        #expect(report.contains("Top item: Canvas Tote"))
        #expect(report.contains("• Protect the current streak"))
    }

    @Test
    func `report resolves Japanese presentation strings`() {
        let snapshot = InsightsSnapshot(
            options: .init(range: .allTime, includesArchivedItems: true),
            totalMarks: 0,
            activeDays: 0,
            uniqueMarkedItems: 0,
            uniqueMarkedCategories: 0,
            topItems: [],
            quietItems: [],
            currentStreak: 0,
            bestStreak: 0,
            categoryShares: [],
            weekdayActivity: [],
            monthlyActivity: [],
            noteCoverage: .init(coveredCount: 0, totalCount: 0),
            photoCoverage: .init(coveredCount: 0, totalCount: 0),
            recommendations: []
        )

        let report = InsightsReportOperations.report(
            for: snapshot,
            locale: .init(identifier: "ja")
        )

        #expect(report.contains("Stallyインサイト"))
        #expect(report.contains("範囲: すべての期間 · すべてのアイテム"))
        #expect(report.contains("アクティビティ"))
        #expect(report.contains("現在の連続日数: 0"))
    }
}
