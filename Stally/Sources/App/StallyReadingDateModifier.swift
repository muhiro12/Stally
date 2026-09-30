import SwiftUI
import UIKit

/// Refreshes date-dependent readings across retained navigation destinations.
struct StallyReadingDateModifier: ViewModifier {
    @Environment(\.scenePhase)
    private var scenePhase
    @Environment(\.timeZone)
    private var timeZone

    @State private var readingDate = Date.now

    func body(content: Content) -> some View {
        content
            .environment(\.stallyReadingDate, readingDate)
            .onAppear(perform: refresh)
            .onChange(of: scenePhase) {
                if scenePhase == .active {
                    refresh()
                }
            }
            .onChange(of: timeZone) {
                refresh()
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: UIApplication.significantTimeChangeNotification
                )
            ) { _ in
                refresh()
            }
    }

    private func refresh() {
        readingDate = .now
    }
}
