import SwiftUI
import UIKit

/// Refreshes date-dependent readings across retained navigation destinations.
struct StallyReadingDateModifier: ViewModifier {
    @Environment(\.scenePhase)
    private var scenePhase
    @Environment(\.timeZone)
    private var timeZone

    private let currentDate: () -> Date
    @State private var readingDate: Date

    init() {
        self.init {
            .now
        }
    }

    #if DEBUG
    init(previewDate: Date?) {
        self.init {
            previewDate ?? .now
        }
    }

    init(previewClock: StallyPreviewClock?) {
        self.init {
            previewClock?.date ?? .now
        }
    }
    #endif

    private init(currentDate: @escaping () -> Date) {
        self.currentDate = currentDate
        _readingDate = .init(initialValue: currentDate())
    }

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
        readingDate = currentDate()
    }
}
