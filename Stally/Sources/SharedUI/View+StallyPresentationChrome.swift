//
//  View+StallyPresentationChrome.swift
//  Stally
//
//  Created by Codex on 2026/06/27.
//

import MHUI
import SwiftUI

extension View {
    /// Applies the screen's explicit MHUI container route with Stally's key-value rows.
    func stallyListChrome(_ style: MHContainerStyle) -> some View {
        mhListChrome(style)
            .labeledContentStyle(.mhKeyValue)
    }

    /// Applies the form's explicit MHUI container route with Stally's key-value rows.
    func stallyFormChrome(_ style: MHContainerStyle) -> some View {
        mhFormChrome(style)
            .labeledContentStyle(.mhKeyValue)
    }

    func stallyToolbarActionStyle() -> some View {
        mhTint(.primaryText)
    }
}
