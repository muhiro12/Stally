//
//  View+StallyPresentationChrome.swift
//  Stally
//
//  Created by Codex on 2026/06/27.
//

import MHUI
import SwiftUI

extension View {
    func stallyListChrome() -> some View {
        mhListChrome()
            .labeledContentStyle(.mhKeyValue)
    }

    func stallyFormChrome() -> some View {
        mhFormChrome()
            .labeledContentStyle(.mhKeyValue)
    }

    func stallyToolbarActionStyle() -> some View {
        tint(.primary)
    }
}
