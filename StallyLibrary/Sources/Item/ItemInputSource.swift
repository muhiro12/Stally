import Foundation

enum ItemInputSource {
    static func note(_ candidate: String, in source: String) -> String? {
        if candidate.isEmpty || source.contains(candidate) {
            return candidate
        }
        let characters = Array(source)
        let positions = characters.indices.filter { index in
            !characters[index].isWhitespace
        }
        let compactSource = String(positions.map { index in
            characters[index]
        })
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
        let start = compactSource.distance(from: compactSource.startIndex, to: range.lowerBound)
        let end = compactSource.distance(from: compactSource.startIndex, to: range.upperBound) - 1
        // Return source text, not the model's reformatted version or a synthesized replacement.
        return String(characters[positions[start]...positions[end]])
    }
}
