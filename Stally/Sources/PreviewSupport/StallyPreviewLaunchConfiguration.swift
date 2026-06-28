//
//  StallyPreviewLaunchConfiguration.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

#if DEBUG
import SwiftData

struct StallyPreviewLaunchConfiguration {
    static var current: Self {
        .init(arguments: CommandLine.arguments)
    }

    let scenario: StallyPreviewScenario?
    let route: StallyPreviewRoute?

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

        guard route != nil else {
            return nil
        }

        return .typical
    }

    init(arguments: [String]) {
        scenario = Self.scenario(from: arguments)
        route = Self.route(from: arguments)
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
