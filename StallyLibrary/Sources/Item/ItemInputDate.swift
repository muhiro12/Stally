import Foundation

/// Converts only explicitly supplied civil date components, without a reference date or locale guess.
struct ItemInputDate {
    let text: String
    let value: String
    let range: Range<String.Index>
    let evidenceRange: Range<String.Index>

    static func occurrences(in source: String) throws -> [Self] {
        try ranges(in: source).compactMap { range in
            let sourceText = String(source[range])
            guard let canonicalValue = try? value(sourceText) else {
                return nil
            }
            let before = source[..<range.lowerBound]
            let after = source[range.upperBound...]
            guard !["頃", "ごろ", "くらい"].contains(where: { after.hasPrefix($0) }) else {
                return nil
            }
            let start = before.lastIndex { $0.isNewline || $0 == "。" || $0 == "." }.map { index in
                source.index(after: index)
            } ?? source.startIndex
            let end = after.firstIndex { $0.isNewline || $0 == "。" || $0 == "." }.map { index in
                source.index(after: index)
            } ?? source.endIndex
            return .init(text: sourceText, value: canonicalValue, range: range, evidenceRange: start..<end)
        }
    }

    private static func ranges(in source: String) throws -> [Range<String.Index>] {
        let months = "January|February|March|April|May|June|July|August|September|October|November|December"
        let shortMonths = "Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec"
        let month = "(?:\(months)|\(shortMonths))"
        let pattern = """
            (?<![A-Za-z0-9])(?:\(month) (?:[0-9]{1,2}, )?[0-9]{4}|\
            [0-9]{1,2} \(month) [0-9]{4}|\
            [0-9]{4}年(?:[0-9]{1,2}月(?:[0-9]{1,2}日)?)?|\
            [0-9]{4}(?:-[0-9]{1,2}(?:-[0-9]{1,2})?|/[0-9]{1,2}(?:/[0-9]{1,2})?)?)(?![A-Za-z0-9年月日/-])
            """
        let expression = try NSRegularExpression(pattern: pattern)
        return expression.matches(in: source, range: NSRange(source.startIndex..., in: source)).compactMap { match in
            Range(match.range, in: source)
        }
    }

    static func value(_ text: String) throws -> String? {
        guard !text.isEmpty else {
            return nil
        }
        let formats = [
            ("yyyy年M月d日", "yyyy-MM-dd"), ("yyyy年MM月dd日", "yyyy-MM-dd"),
            ("yyyy年MM月d日", "yyyy-MM-dd"), ("yyyy年M月dd日", "yyyy-MM-dd"),
            ("yyyy年M月", "yyyy-MM"), ("yyyy年MM月", "yyyy-MM"), ("yyyy年", "yyyy"),
            ("yyyy-MM-dd", "yyyy-MM-dd"), ("yyyy-M-d", "yyyy-MM-dd"),
            ("yyyy-MM-d", "yyyy-MM-dd"), ("yyyy-M-dd", "yyyy-MM-dd"),
            ("yyyy-MM", "yyyy-MM"), ("yyyy-M", "yyyy-MM"), ("yyyy", "yyyy"),
            ("yyyy/M/d", "yyyy-MM-dd"), ("yyyy/MM/dd", "yyyy-MM-dd"),
            ("yyyy/MM/d", "yyyy-MM-dd"), ("yyyy/M/dd", "yyyy-MM-dd"),
            ("yyyy/M", "yyyy-MM"), ("yyyy/MM", "yyyy-MM"),
            ("MMMM d, yyyy", "yyyy-MM-dd"), ("MMM d, yyyy", "yyyy-MM-dd"),
            ("d MMMM yyyy", "yyyy-MM-dd"), ("d MMM yyyy", "yyyy-MM-dd"),
            ("MMMM yyyy", "yyyy-MM"), ("MMM yyyy", "yyyy-MM")
        ]
        let formatter = DateFormatter()
        formatter.locale = .init(identifier: "en_US_POSIX")
        formatter.calendar = CivilDate.calendar
        formatter.timeZone = .gmt
        formatter.isLenient = false
        for (sourceFormat, targetFormat) in formats {
            formatter.dateFormat = sourceFormat
            guard let date = formatter.date(from: text), formatter.string(from: date) == text else {
                continue
            }
            formatter.dateFormat = targetFormat
            let result = formatter.string(from: date)
            _ = try CivilDate.range(result)
            return result
        }
        throw ItemInputError.invalidResult
    }
}
