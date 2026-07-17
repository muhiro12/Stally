//
//  View+StallyPresentationChrome.swift
//  Stally
//
//  Created by Codex on 2026/06/27.
//

import SwiftUI
import UIKit

extension View {
    func stallyListChrome() -> some View {
        listStyle(.insetGrouped)
    }

    func stallyFormChrome() -> some View {
        scrollContentBackground(.visible)
    }

    func stallyContentBackground() -> some View {
        background {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
        }
    }
}
