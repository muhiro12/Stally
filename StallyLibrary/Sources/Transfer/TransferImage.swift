import Foundation

struct TransferImage: Codable, Equatable, Sendable {
    enum State: String, Codable, Sendable {
        case included
        case omitted
        case unavailable
    }

    var state: State
    var path: String?
    var byteCount: Int?
    var sha256: String?
}
