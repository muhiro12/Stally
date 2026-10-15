import Foundation

/// Search identity and reconciliation policy, independent of the indexing framework.
public enum ItemSearchIndexOperations {
    /// Captures every supplied Item, including Archive, in stable identity order.
    public static func entries(for items: [Item]) -> [ItemSearchIndexEntry] {
        items.map { item in
            .init(
                uuid: item.uuid,
                name: item.name,
                categoryRawValue: item.categoryRawValue,
                isArchived: item.isArchived
            )
        }
        .sorted { first, second in
            first.uuid.uuidString < second.uuid.uuidString
        }
    }

    /// Returns domain identities independently of names and collection order.
    public static func identifiers(for entries: [ItemSearchIndexEntry]) -> Set<UUID> {
        Set(entries.map(\.uuid))
    }

    /// Finds tracked identities no longer present in the saved source snapshot.
    public static func removedIdentifiers(previous: Set<UUID>, current: [ItemSearchIndexEntry]) -> [UUID] {
        previous.subtracting(identifiers(for: current)).sorted { first, second in
            first.uuidString < second.uuidString
        }
    }

    /// Builds a searchable-item identifier scoped to one app-owned namespace.
    public static func activityIdentifier(itemID: UUID, namespace: String) -> String {
        "\(namespace)/\(itemID.uuidString)"
    }

    /// Rejects foreign namespaces and malformed identities without a name fallback.
    public static func itemID(activityIdentifier: String, namespace: String) -> UUID? {
        let prefix = "\(namespace)/"
        guard activityIdentifier.hasPrefix(prefix) else {
            return nil
        }
        return UUID(uuidString: String(activityIdentifier.dropFirst(prefix.count)))
    }
}
