import Foundation

@propertyWrapper
struct TransferUUIDs: Codable, Equatable, Sendable {
    var wrappedValue: [UUID]

    init(wrappedValue: [UUID]) { self.wrappedValue = wrappedValue }

    init(from decoder: any Decoder) throws {
        wrappedValue = try decoder.singleValueContainer().decode([UUID].self)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        for uuid in wrappedValue { try container.encode(uuid.uuidString.lowercased()) }
    }
}
