//
//  StallyStoreSection.swift
//  Stally
//
//  Created by Codex on 2026/06/28.
//

import MHPlatform
import SwiftUI

struct StallyStoreSection: View {
    @Environment(MHAppRuntime.self)
    private var appRuntime

    var body: some View {
        appRuntime.subscriptionSectionView()
    }
}
