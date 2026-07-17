//
//  StallySectionHeader.swift
//  Stally
//
//  Created by Codex on 2026/07/17.
//

import MHUI
import SwiftUI

struct StallySectionHeader: View {
    @Environment(\.mhTheme)
    private var theme

    private let title: Text

    var body: some View {
        MHSectionHeader(title: title)
            .padding(.leading, -theme.spacing.inline)
    }

    init(_ title: LocalizedStringKey) {
        self.title = Text(title)
    }

    init(title: Text) {
        self.title = title
    }
}
