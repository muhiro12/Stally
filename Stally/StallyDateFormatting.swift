//
//  StallyDateFormatting.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/03/07.
//

import Foundation

enum StallyDateFormatting {
    nonisolated static let timestamp = Date.FormatStyle(date: .abbreviated, time: .shortened)

    nonisolated static func timestampText(for date: Date) -> String {
        date.formatted(timestamp)
    }
}
