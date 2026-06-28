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
    enum Size {
        case small
        case medium
    }

    @Environment(MHAppRuntime.self)
    private var appRuntime
    @Environment(\.mhDesignMetrics)
    private var designMetrics

    let size: Size

    var body: some View {
        if appRuntime.adsAvailability == .available {
            Section {
                appRuntime.nativeAdView(size: size.runtimeSize)
                    .frame(maxWidth: .infinity)
                    .padding(designMetrics.spacing.inline)
            }
        }
    }
}

private extension StallyAdvertisementSection.Size {
    var runtimeSize: MHNativeAdSize {
        switch self {
        case .small:
            .small
        case .medium:
            .medium
        }
    }
}
