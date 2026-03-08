//
//  StallyAdMobConfiguration.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/03/08.
//

enum StallyAdMobConfiguration {
    // Matches Incomes' debug native ad unit so local startup can exercise the same path.
    static let nativeAdUnitIDDev = "ca-app-pub-3940256099942544/3986624511"

    static var nativeAdUnitID: String? {
        #if DEBUG
        nativeAdUnitIDDev
        #else
        nil
        #endif
    }
}
