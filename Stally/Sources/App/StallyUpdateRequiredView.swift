import MHPlatform
import MHUI
import SwiftUI

struct StallyUpdateRequiredView: View {
    @Environment(RemoteUpdateOperations.self)
    private var remoteUpdates
    @Environment(MHLoggingBootstrap.self)
    private var logging

    @State private var isChecking = false

    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("Update Required", systemImage: "arrow.down.app")
            } description: {
                Text("Install the latest version of Stally to continue.")
            } actions: {
                if let url = StallyRemoteUpdateConfiguration.appStoreURL {
                    Link("Update Stally", destination: url)
                        .buttonStyle(.mhPrimary)
                }
                Button("Check Again", action: checkAgain)
                    .buttonStyle(.mhSecondary)
                    .disabled(isChecking)
            }
            .mhScreen()
        }
    }

    private func checkAgain() {
        Task {
            isChecking = true
            defer {
                isChecking = false
            }
            await StallyRemoteUpdateConfiguration.prepare(remoteUpdates, logging: logging)
        }
    }
}
