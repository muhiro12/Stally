//
//  StallyAdvertisementSection.swift
//  Stally
//
//  Created by Codex on 2026/06/28.
//

import MHPlatform
import MHUI
import SwiftUI

struct StallyAdvertisementSection: View {
    @Environment(MHAppRuntime.self)
    private var appRuntime
    @Environment(\.mhDesignMetrics)
    private var designMetrics

    let size: MHNativeAdSize

    var body: some View {
        if appRuntime.adsAvailability == .available {
            Section {
                appRuntime.nativeAdView(size: size)
                    .frame(maxWidth: .infinity)
                    .padding(designMetrics.spacing.inline)
            }
        }
    }
}
