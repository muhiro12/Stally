import SwiftUI
import UIKit

/// Refreshes date-dependent readings across retained navigation destinations.
struct StallyReadingDateModifier: ViewModifier {
    @Environment(\.scenePhase)
    private var scenePhase
    @Environment(\.timeZone)
    private var timeZone

    private let fixedDate: Date?
    @State private var readingDate = Date.now

    init() {
        fixedDate = nil
    }

    #if DEBUG
    init(previewDate: Date?) {
        fixedDate = previewDate
    }
    #endif

    func body(content: Content) -> some View {
        content
            .environment(\.stallyReadingDate, fixedDate ?? readingDate)
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
        if fixedDate == nil {
            readingDate = .now
        }
    }
}
