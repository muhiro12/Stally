import Foundation

/// Required nullable keys decode strictly and always encode an explicit null.
@propertyWrapper
struct TransferNullable<Value: Codable & Equatable & Sendable>: Codable, Equatable, Sendable {
    var wrappedValue: Value?

    init(wrappedValue: Value?) { self.wrappedValue = wrappedValue }

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        wrappedValue = container.decodeNil() ? nil : try container.decode(Value.self)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        if let wrappedValue {
            try container.encode(wrappedValue)
        } else {
            try container.encodeNil()
        }
    }
}
