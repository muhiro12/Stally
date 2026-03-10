import Foundation

struct StallyReviewSelectionState {
    struct LaneSelection {
        var isSelectionModeEnabled = false
        var selectedItemIDs: Set<UUID> = []
        var isBulkConfirmationPresented = false

        mutating func toggleSelectionMode() {
            isSelectionModeEnabled.toggle()

            if !isSelectionModeEnabled {
                selectedItemIDs.removeAll()
            }
        }

        mutating func toggleSelection(
            for itemID: UUID
        ) {
            if selectedItemIDs.contains(itemID) {
                selectedItemIDs.remove(itemID)
            } else {
                selectedItemIDs.insert(itemID)
            }
        }

        mutating func requestBulkAction() {
            isBulkConfirmationPresented = true
        }

        mutating func cancelBulkAction() {
            isBulkConfirmationPresented = false
        }

        mutating func completeBulkAction() {
            isBulkConfirmationPresented = false
            isSelectionModeEnabled = false
            selectedItemIDs.removeAll()
        }
    }

    var untouched = LaneSelection()
    var dormant = LaneSelection()
    var recovery = LaneSelection()
}
