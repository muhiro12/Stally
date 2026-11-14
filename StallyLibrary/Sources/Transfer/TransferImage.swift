import Foundation

struct TransferImage: Codable, Equatable, Sendable {
    enum State: String, Codable, Sendable {
        case included
        case omitted
        case unavailable
    }

    private enum CodingKeys: String, CodingKey { case state, path, byteCount, sha256 }

    var state: State
    var path: String?
    var byteCount: Int?
    var sha256: String?

    init(state: State, path: String?, byteCount: Int?, sha256: String?) {
        self.state = state
        self.path = path
        self.byteCount = byteCount
        self.sha256 = sha256
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        state = try container.decode(State.self, forKey: .state)
        if state != .included {
            guard !container.contains(.path), !container.contains(.byteCount), !container.contains(.sha256) else {
                throw TransferError.invalidFile
            }
        }
        path = try container.decodeIfPresent(String.self, forKey: .path)
        byteCount = try container.decodeIfPresent(Int.self, forKey: .byteCount)
        sha256 = try container.decodeIfPresent(String.self, forKey: .sha256)
    }
}
