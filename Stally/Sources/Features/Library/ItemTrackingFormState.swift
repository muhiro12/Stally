import Foundation

/// Unsaved form selections. Increasing precision never supplies a missing component.
struct ItemTrackingFormState {
    enum Precision: String, CaseIterable, Identifiable {
        case unknown
        case year
        case month
        case day

        var id: Self {
            self
        }

        var title: LocalizedStringResource {
            switch self {
            case .unknown:
                "Not Set"
            case .year:
                "Year Only"
            case .month:
                "Month"
            case .day:
                "Exact Day"
            }
        }
    }

    private static let maximumDay = 31

    var recordsMarks = true
    var precision: Precision = .unknown
    var year = ""
    var month: Int?
    var day: Int?
    var requiresStartRepair = false

    var maximumDay: Int {
        guard let yearValue = Int(year), let month else {
            return Self.maximumDay
        }
        return ItemStart(year: yearValue, month: month)?.latestDay.day ?? Self.maximumDay
    }

    init() {
        // New items preserve the existing Mark-enabled default.
    }

    init(item: Item) {
        recordsMarks = item.recordsMarks
        do {
            let input = try ItemOperations.trackingInput(for: item)
            if let start = input.start {
                year = String(start.earliestDay.year)
                switch start.precision {
                case .year:
                    precision = .year
                case .month:
                    precision = .month
                    month = start.earliestDay.month
                case .day:
                    precision = .day
                    month = start.earliestDay.month
                    day = start.earliestDay.day
                }
            }
        } catch {
            requiresStartRepair = true
        }
    }

    func input() throws -> ItemTrackingInput {
        guard !requiresStartRepair else {
            throw ItemValidationError.invalidStart
        }
        guard precision != .unknown else {
            return .init(recordsMarks: recordsMarks, start: nil)
        }
        guard let yearValue = Int(year),
              precision == .year || month != nil,
              precision != .day || day != nil,
              let start = ItemStart(
                year: yearValue,
                month: precision == .year ? nil : month,
                day: precision == .day ? day : nil
              ) else {
            throw ItemTrackingFormError.invalidDate
        }
        return .init(recordsMarks: recordsMarks, start: start)
    }

    mutating func changePrecision() {
        if precision != .unknown {
            requiresStartRepair = false
        }
        if precision != .day {
            day = nil
        }
        if precision == .year || precision == .unknown {
            month = nil
        }
    }

    mutating func validateSelectedDay() {
        if let day, day > maximumDay {
            self.day = nil
        }
    }

    mutating func clearInvalidStart() {
        requiresStartRepair = false
        precision = .unknown
        year = ""
        month = nil
        day = nil
    }
}
