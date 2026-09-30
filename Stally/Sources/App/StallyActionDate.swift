import Foundation

/// Reads the instant of an action; only explicit synthetic launches freeze it.
enum StallyActionDate {
    #if DEBUG
    private static let previewDate = StallyPreviewLaunchConfiguration.current.referenceDate
    #endif

    static var current: Date {
        #if DEBUG
        previewDate ?? .now
        #else
        .now
        #endif
    }
}
