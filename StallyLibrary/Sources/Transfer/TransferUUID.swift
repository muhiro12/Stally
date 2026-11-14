import Foundation

@propertyWrapper
struct TransferUUID: Codable, Equatable, Sendable {
    var wrappedValue: UUID

    init(wrappedValue: UUID) { self.wrappedValue = wrappedValue }

    init(from decoder: any Decoder) throws {
        wrappedValue = try decoder.singleValueContainer().decode(UUID.self)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue.uuidString.lowercased())
    }
}
