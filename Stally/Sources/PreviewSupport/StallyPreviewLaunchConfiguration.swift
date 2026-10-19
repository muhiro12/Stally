//
//  StallyPreviewLaunchConfiguration.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

#if DEBUG
import Foundation
import SwiftData
import SwiftUI

struct StallyPreviewLaunchConfiguration {
    static let current: Self = .init(arguments: CommandLine.arguments)

    let scenario: StallyPreviewScenario?
    let route: StallyPreviewRoute?
    let trackingScreen: StallyTrackingPreviewScreen?

    var usesPreviewData: Bool {
        resolvedScenario != nil
    }

    var textSize: DynamicTypeSize? {
        guard resolvedScenario != nil else {
            return nil
        }
        return requestedTextSize
    }

    var referenceDate: Date? {
        clock?.date
    }

    var clock: StallyPreviewClock? {
        resolvedScenario == nil ? nil : requestedClock
    }

    private let requestedTextSize: DynamicTypeSize?
    private let requestedClock: StallyPreviewClock

    var modelContainer: ModelContainer? {
        guard let resolvedScenario else {
            return nil
        }

        return StallyPreviewData.makeContainer(for: resolvedScenario)
    }

    private var resolvedScenario: StallyPreviewScenario? {
        if let scenario {
            return scenario
        }

        if trackingScreen != nil {
            return .integration
        }

        guard route != nil else {
            return nil
        }

        return .typical
    }

    init(arguments: [String]) {
        requestedClock = .init(
            advanceAfter: Self.value(after: "--stally-preview-advance-day-after", in: arguments)
                .flatMap(TimeInterval.init),
            sendsTimeChange: arguments.contains("--stally-preview-send-time-change")
        )
        switch Self.value(after: "--stally-preview-text-size", in: arguments) {
        case "accessibility5":
            requestedTextSize = .accessibility5
        case "accessibility3":
            requestedTextSize = .accessibility3
        case "xxxLarge":
            requestedTextSize = .xxxLarge
        default:
            requestedTextSize = nil
        }
        scenario = Self.scenario(from: arguments)
        route = Self.route(from: arguments)
        trackingScreen = Self.value(after: "--stally-preview-tracking-screen", in: arguments)
            .flatMap(StallyTrackingPreviewScreen.init(rawValue:))
    }

    private static func scenario(from arguments: [String]) -> StallyPreviewScenario? {
        value(after: "--stally-preview-scenario", in: arguments)
            .flatMap(StallyPreviewScenario.init(rawValue:))
    }

    private static func route(from arguments: [String]) -> StallyPreviewRoute? {
        value(after: "--stally-preview-route", in: arguments)
            .flatMap(StallyPreviewRoute.init(rawValue:))
    }

    private static func value(
        after option: String,
        in arguments: [String]
    ) -> String? {
        guard let optionIndex = arguments.firstIndex(of: option) else {
            return nil
        }

        let valueIndex = arguments.index(after: optionIndex)

        guard arguments.indices.contains(valueIndex) else {
            return nil
        }

        return arguments[valueIndex]
    }
}
#endif
