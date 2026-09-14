import Foundation

public extension ItemTimeOperations {
    /// Formats an elapsed reading consistently for app UI and system surfaces.
    static func elapsedText(for snapshot: ItemTimeSnapshot, locale: Locale = .current) -> String {
        switch snapshot {
        case .unknown:
            return localized(.init("Not Set", bundle: #bundle), locale: locale)
        case .invalidStart:
            return localized(.init("Invalid Item Start", bundle: #bundle), locale: locale)
        case .notStarted:
            return localized(.init("Not Started", bundle: #bundle), locale: locale)
        case let .elapsed(start, _, units):
            switch start.precision {
            case .day:
                if units.lowerBound == 0 {
                    return localized(.init("Starts Today", bundle: #bundle), locale: locale)
                }
                if units.lowerBound == 1 {
                    return localized(.init("1 day", bundle: #bundle), locale: locale)
                }
                return localized(.init("\(units.lowerBound) days", bundle: #bundle), locale: locale)
            case .month:
                return approximateMonths(units, locale: locale)
            case .year:
                return approximateYears(units, locale: locale)
            }
        }
    }

    /// Formats only the date components actually known, using Gregorian dates.
    static func startText(for start: ItemStart, locale: Locale = .current) -> String {
        let style = Date.FormatStyle(
            date: .omitted,
            time: .omitted,
            locale: locale,
            calendar: .init(identifier: .gregorian),
            timeZone: .gmt
        )
        guard let date = start.earliestDay.date(in: .gmt) else {
            return start.rawValue
        }
        switch start.precision {
        case .year:
            return date.formatted(style.year())
        case .month:
            return date.formatted(style.year().month(.wide))
        case .day:
            return date.formatted(style.year().month(.wide).day())
        }
    }

    /// A copyable time reading, with its reference day and original precision.
    /// Deliberately excludes private notes, photos, identifiers, and Mark history.
    static func report(for item: Item, today: LocalDay, locale: Locale = .current) -> String {
        let snapshot = snapshot(for: item, today: today)
        var lines = [item.name]
        let elapsedLabel = localized(.init("Elapsed Time", bundle: #bundle), locale: locale)
        lines.append("\(elapsedLabel): \(elapsedText(for: snapshot, locale: locale))")
        if let tracking = try? ItemOperations.trackingInput(for: item), let start = tracking.start {
            let label = localized(.init("Start", bundle: #bundle), locale: locale)
            lines.append("\(label): \(startText(for: start, locale: locale))")
        }
        let reference = localized(.init("As of", bundle: #bundle), locale: locale)
        lines.append("\(reference): \(today.iso8601Date)")
        if item.isArchived {
            lines.append(localized(.init("Archived. Elapsed time continues.", bundle: #bundle), locale: locale))
        }
        return lines.joined(separator: "\n")
    }
}

private extension ItemTimeOperations {
    static func localized(_ resource: LocalizedStringResource, locale: Locale) -> String {
        var value = resource
        value.locale = locale
        return String(localized: value)
    }

    static func approximateMonths(_ units: ClosedRange<Int>, locale: Locale) -> String {
        if units.upperBound == 0 {
            return localized(.init("Less than a month", bundle: #bundle), locale: locale)
        }
        if units.lowerBound != units.upperBound {
            return localized(
                .init("About \(units.lowerBound)–\(units.upperBound) months", bundle: #bundle),
                locale: locale
            )
        }
        if units.lowerBound == 1 {
            return localized(.init("About a month", bundle: #bundle), locale: locale)
        }
        return localized(.init("About \(units.lowerBound) months", bundle: #bundle), locale: locale)
    }

    static func approximateYears(_ units: ClosedRange<Int>, locale: Locale) -> String {
        if units.upperBound == 0 {
            return localized(.init("Less than a year", bundle: #bundle), locale: locale)
        }
        if units.lowerBound != units.upperBound {
            return localized(
                .init("About \(units.lowerBound)–\(units.upperBound) years", bundle: #bundle),
                locale: locale
            )
        }
        if units.lowerBound == 1 {
            return localized(.init("About a year", bundle: #bundle), locale: locale)
        }
        return localized(.init("About \(units.lowerBound) years", bundle: #bundle), locale: locale)
    }
}
