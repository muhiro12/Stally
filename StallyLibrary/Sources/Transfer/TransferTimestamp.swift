import Foundation

/// Portable registration precision is milliseconds, not conflict precedence.
enum TransferTimestamp {
    private static let millisecondsPerSecond = 1_000.0
    private static let length = 24

    static func string(_ date: Date) throws -> String {
        let seconds = date.timeIntervalSince1970
        let minimumSeconds = -62_135_596_800.0
        let maximumSeconds = 253_402_300_800.0
        guard seconds.isFinite, seconds >= minimumSeconds, seconds < maximumSeconds else {
            throw TransferError.invalidFile
        }
        let quantized = Date(timeIntervalSince1970: (seconds * millisecondsPerSecond).rounded() / millisecondsPerSecond)
        let year = CivilDate.calendar.component(.year, from: quantized)
        let maximumYear = 9_999
        guard (1...maximumYear).contains(year) else { throw TransferError.invalidFile }
        return formatter().string(from: quantized)
    }

    static func date(_ text: String) throws -> Date {
        guard text.utf8.count == length, let date = formatter().date(from: text),
              try string(date) == text
        else { throw TransferError.invalidFile }
        return date
    }

    private static func formatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = .init(identifier: "en_US_POSIX")
        formatter.calendar = CivilDate.calendar
        formatter.timeZone = .gmt
        formatter.isLenient = false
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        return formatter
    }
}
