import Foundation
import SwiftData
@testable import StallyLibrary
import XCTest

@MainActor
func testContext() -> ModelContext {
    do {
        return .init(
            try .init(
                for: Item.self,
                Mark.self,
                configurations: .init(
                    isStoredInMemoryOnly: true
                )
            )
        )
    } catch {
        preconditionFailure("Failed to create test context: \(error)")
    }
}

func localDate(
    year: Int,
    month: Int,
    day: Int,
    hour: Int = 12
) -> Date {
    var components: DateComponents = .init()
    components.calendar = .current
    components.year = year
    components.month = month
    components.day = day
    components.hour = hour

    guard let date = components.date else {
        preconditionFailure("Failed to build a local date from \(components).")
    }

    return date
}
