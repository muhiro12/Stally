import Foundation

/// Reads the instant of an action; only explicit synthetic launches freeze it.
enum StallyActionDate {
    #if DEBUG
    private static let previewClock = StallyPreviewLaunchConfiguration.current.clock
    #endif

    static var current: Date {
        #if DEBUG
        previewClock?.date ?? .now
        #else
        .now
        #endif
    }
}
