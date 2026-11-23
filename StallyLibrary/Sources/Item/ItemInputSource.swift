import Foundation

enum ItemInputSource {
    static func note(_ candidate: String, in source: String) -> String? {
        if candidate.isEmpty || source.contains(candidate) {
            return candidate
        }
        var compactSource = ""
        var sourceIndices: [String.Index] = []
        for index in source.indices where !source[index].isWhitespace {
            let character = source[index]
            compactSource.append(character)
            // Removing whitespace can join graphemes; UTF-16 offsets still map to the original span.
            sourceIndices.append(contentsOf: repeatElement(index, count: character.utf16.count))
        }
        let compactCandidate = String(candidate.filter { character in
            !character.isWhitespace
        })
        guard !compactCandidate.isEmpty,
              let range = compactSource.range(of: compactCandidate) else {
            return nil
        }
        let remaining = compactSource.index(after: range.lowerBound)..<compactSource.endIndex
        guard compactSource.range(of: compactCandidate, range: remaining) == nil else {
            return nil
        }
        let start = range.lowerBound.utf16Offset(in: compactSource)
        let end = range.upperBound.utf16Offset(in: compactSource) - 1
        return String(source[sourceIndices[start]...sourceIndices[end]])
    }
}
