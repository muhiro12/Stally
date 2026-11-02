import CloudKit
import Combine
import Observation
import StallyLibrary

@MainActor
@Observable
final class StallyLibrarySession {
    var importReview: TransferReview?
    private(set) var writer: RecordWriteSession
    private let updates: RemoteUpdateOperations
    @ObservationIgnored private var accountChanges: AnyCancellable?

    init(updates: RemoteUpdateOperations, observesAccount: Bool) {
        self.updates = updates
        writer = .init(updates: updates)
        if observesAccount {
            accountChanges = NotificationCenter.default.publisher(for: .CKAccountChanged)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in self?.accountChanged() }
        }
    }

    private func accountChanged() {
        writer.invalidate()
        importReview = nil
        writer = .init(updates: updates)
    }
}
