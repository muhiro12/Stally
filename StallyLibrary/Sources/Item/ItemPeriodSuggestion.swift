import Foundation

/// Source-backed period knowledge awaiting an explicit choice and review.
public struct ItemPeriodSuggestion: Equatable, Sendable {
    public enum Continuation: String, CaseIterable, Identifiable, Sendable {
        case unspecified
        case ongoing
        case ended

        public var id: Self { self }

        public var title: String {
            switch self {
            case .unspecified:
                String(localized: "Needs Review", bundle: .module)
            case .ongoing:
                String(localized: "Ongoing", bundle: .module)
            case .ended:
                String(localized: "Ended", bundle: .module)
            }
        }
    }

    public enum Basis: String, Sendable {
        case purchase
        case order
        case delivery
        case relationship

        public var title: String {
            switch self {
            case .purchase:
                String(localized: "Purchase", bundle: .module)
            case .order:
                String(localized: "Order", bundle: .module)
            case .delivery:
                String(localized: "Delivery", bundle: .module)
            case .relationship:
                String(localized: "Relationship Period", bundle: .module)
            }
        }
    }

    public let start: String?
    public let end: String?
    public let continuation: Continuation
    public let basis: Basis
    public let evidence: String

    public init(start: String?, end: String?, continuation: Continuation, basis: Basis, evidence: String) {
        self.start = start
        self.end = end
        self.continuation = continuation
        self.basis = basis
        self.evidence = evidence
    }
}
