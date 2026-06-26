//
//  StallyPreviewContainer.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

#if DEBUG
import MHUI
import SwiftData
import SwiftUI

@MainActor
struct StallyPreviewContainer<Content: View>: View {
    private let container: ModelContainer
    private let content: ([Item]) -> Content

    var body: some View {
        content(StallyPreviewData.items(in: container))
            .modelContainer(container)
            .environment(\.calendar, StallyPreviewData.calendar)
            .mhTheme(.standard)
            .mhGlassPolicy(.automatic)
    }

    init(
        @ViewBuilder content: @escaping ([Item]) -> Content
    ) {
        container = StallyPreviewData.makeContainer(for: .typical)
        self.content = content
    }

    init(
        _ scenario: StallyPreviewScenario,
        @ViewBuilder content: @escaping ([Item]) -> Content
    ) {
        container = StallyPreviewData.makeContainer(for: scenario)
        self.content = content
    }
}
#endif
