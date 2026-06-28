//
//  StallySubscriptionStateSyncModifier.swift
//  Stally
//
//  Created by Codex on 2026/06/28.
//

import MHPlatform
import SwiftUI

private struct StallySubscriptionStateSyncModifier: ViewModifier {
    @Environment(MHAppRuntime.self)
    private var appRuntime
    @AppStorage(\.isSubscribeOn)
    private var isSubscribeOn
    @AppStorage(\.isICloudOn)
    private var isICloudOn

    func body(content: Content) -> some View {
        content
            .task {
                syncSubscriptionStateIfNeeded()
            }
            .onChange(of: appRuntime.premiumStatus) {
                syncSubscriptionStateIfNeeded()
            }
    }

    @MainActor
    private func syncSubscriptionStateIfNeeded() {
        let purchasedProductIDs: Set<String>

        switch appRuntime.premiumStatus {
        case .unknown:
            return
        case .inactive:
            purchasedProductIDs = []
        case .active:
            purchasedProductIDs = [
                StallyMonetizationConfiguration.subscriptionProductID
            ]
        }

        let state = SubscriptionStateOperations.calculate(
            purchasedProductIDs: purchasedProductIDs,
            productID: StallyMonetizationConfiguration.subscriptionProductID,
            isICloudOn: isICloudOn
        )
        isSubscribeOn = state.isSubscribeOn
        isICloudOn = state.isICloudOn
    }
}

extension View {
    func stallySubscriptionStateSync() -> some View {
        modifier(StallySubscriptionStateSyncModifier())
    }
}
