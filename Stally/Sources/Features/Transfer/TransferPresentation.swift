import Observation
import StallyLibrary

@MainActor
@Observable
final class TransferPresentation {
    var review: TransferReview?
}
