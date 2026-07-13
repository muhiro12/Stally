//
//  InsightsReportOperations.swift
//  StallyLibrary
//
//  Created by Codex on 2026/07/13.
//

import Foundation

/// Cross-surface use cases for presenting an Insights snapshot as a report.
public enum InsightsReportOperations {
    /// Builds a localized, shareable plain-text report from an Insights snapshot.
    public static func report(
        for snapshot: InsightsSnapshot,
        locale: Locale = .current
    ) -> String {
        var lines = [
            localized(.init("Stally Insights", bundle: #bundle), locale: locale),
            "\(localized(.init("Scope", bundle: #bundle), locale: locale)): \(scope(for: snapshot, locale: locale))",
            "",
            localized(.init("Activity", bundle: #bundle), locale: locale),
            metric(.init("Marks", bundle: #bundle), value: snapshot.totalMarks, locale: locale),
            metric(.init("Active Days", bundle: #bundle), value: snapshot.activeDays, locale: locale),
            metric(.init("Unique Items", bundle: #bundle), value: snapshot.uniqueMarkedItems, locale: locale),
            metric(
                .init("Unique Categories", bundle: #bundle),
                value: snapshot.uniqueMarkedCategories,
                locale: locale
            ),
            "",
            localized(.init("Consistency", bundle: #bundle), locale: locale),
            metric(
                .init("Current Streak", bundle: #bundle),
                value: snapshot.currentStreak,
                locale: locale
            ),
            metric(
                .init("Best Streak", bundle: #bundle),
                value: snapshot.bestStreak,
                locale: locale
            )
        ]

        appendRhythm(snapshot, to: &lines, locale: locale)
        appendCategories(snapshot.categoryShares, to: &lines, locale: locale)
        appendSpotlight(snapshot, to: &lines, locale: locale)
        appendRecommendations(snapshot.recommendations, to: &lines, locale: locale)

        return lines.joined(separator: "\n")
    }
}

private extension InsightsReportOperations {
    static func localized(
        _ value: LocalizedStringResource,
        locale: Locale
    ) -> String {
        var resource = value
        resource.locale = locale
        return String(localized: resource)
    }

    static func metric(
        _ label: LocalizedStringResource,
        value: Int,
        locale: Locale
    ) -> String {
        "\(localized(label, locale: locale)): \(value.formatted(.number.locale(locale)))"
    }

    static func scope(
        for snapshot: InsightsSnapshot,
        locale: Locale
    ) -> String {
        let range = localized(snapshot.options.range.title, locale: locale)
        let itemScope = snapshot.options.includesArchivedItems
            ? localized(.init("All items", bundle: #bundle), locale: locale)
            : localized(.init("Active items only", bundle: #bundle), locale: locale)
        return "\(range) · \(itemScope)"
    }

    static func appendCategories(
        _ categoryShares: [CategoryShare],
        to lines: inout [String],
        locale: Locale
    ) {
        guard !categoryShares.isEmpty else {
            return
        }

        lines.append("")
        lines.append(localized(.init("Categories", bundle: #bundle), locale: locale))

        for categoryShare in categoryShares {
            lines.append(
                metric(
                    categoryShare.category.title,
                    value: categoryShare.markCount,
                    locale: locale
                )
            )
        }
    }

    static func appendRhythm(
        _ snapshot: InsightsSnapshot,
        to lines: inout [String],
        locale: Locale
    ) {
        guard !snapshot.weekdayActivity.isEmpty || !snapshot.monthlyActivity.isEmpty else {
            return
        }

        lines.append("")
        lines.append(localized(.init("Rhythm", bundle: #bundle), locale: locale))

        if !snapshot.weekdayActivity.isEmpty {
            lines.append(localized(.init("Weekdays", bundle: #bundle), locale: locale))

            for activity in snapshot.weekdayActivity {
                lines.append(
                    metric(
                        weekdayName(activity.weekday, locale: locale),
                        value: activity.markCount,
                        locale: locale
                    )
                )
            }
        }

        if !snapshot.monthlyActivity.isEmpty {
            lines.append(localized(.init("Months", bundle: #bundle), locale: locale))

            for activity in snapshot.monthlyActivity {
                lines.append(
                    metric(
                        monthName(activity, locale: locale),
                        value: activity.markCount,
                        locale: locale
                    )
                )
            }
        }
    }

    static func appendSpotlight(
        _ snapshot: InsightsSnapshot,
        to lines: inout [String],
        locale: Locale
    ) {
        guard let spotlightItem = snapshot.topItems.first ?? snapshot.quietItems.first else {
            return
        }

        lines.append("")
        lines.append(localized(.init("Spotlight", bundle: #bundle), locale: locale))

        if let topItem = snapshot.topItems.first {
            let topItemLabel = localized(
                .init("Top item", bundle: #bundle),
                locale: locale
            )
            lines.append(
                "\(topItemLabel): \(topItem.item.name)"
            )
            lines.append(
                metric(
                    .init("Marks", bundle: #bundle),
                    value: topItem.marksInRange,
                    locale: locale
                )
            )
        }

        if let quietItem = snapshot.quietItems.first,
           quietItem.item.uuid != spotlightItem.item.uuid {
            let quietItemLabel = localized(
                .init("Quiet item", bundle: #bundle),
                locale: locale
            )
            lines.append(
                "\(quietItemLabel): \(quietItem.item.name)"
            )
        }
    }

    static func appendRecommendations(
        _ recommendations: [InsightRecommendation],
        to lines: inout [String],
        locale: Locale
    ) {
        guard !recommendations.isEmpty else {
            return
        }

        lines.append("")
        lines.append(localized(.init("Next Moves", bundle: #bundle), locale: locale))

        for recommendation in recommendations {
            lines.append("• \(localized(recommendation.title, locale: locale))")
        }
    }

    static func metric(
        _ label: String,
        value: Int,
        locale: Locale
    ) -> String {
        "\(label): \(value.formatted(.number.locale(locale)))"
    }

    static func weekdayName(
        _ weekday: Int,
        locale: Locale
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        let symbols = formatter.weekdaySymbols ?? []
        let index = weekday - 1

        guard symbols.indices.contains(index) else {
            return String(weekday)
        }

        return symbols[index]
    }

    static func monthName(
        _ activity: MonthlyActivity,
        locale: Locale
    ) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale

        guard let date = calendar.date(
            from: .init(year: activity.year, month: activity.month)
        ) else {
            return String(format: "%04d-%02d", activity.year, activity.month)
        }

        return date.formatted(.dateTime.year().month(.wide).locale(locale))
    }
}
