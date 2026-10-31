import MHUI
import StallyLibrary
import SwiftUI

struct ImportReviewRow: View {
    let review: TransferReview
    let row: TransferReview.Row
    @Binding var selected: Bool
    private let imageHeight = 160.0

    var body: some View {
        Section {
            if row.isUnchanged {
                Label("Already Matches", systemImage: "checkmark")
            } else {
                Toggle(row.current == nil ? "Add Record" : "Use File Value", isOn: $selected)
            }
            DisclosureGroup(row.title) { values }
            if row.kind == .tag, row.affectedItemCount > 0 {
                Text("Renaming affects \(row.affectedItemCount) existing Items, including those outside this file.")
                    .mhRowSupporting()
            }
        } header: {
            Text(title)
        }
    }

    private var values: some View {
        Group {
            if let current = row.current {
                Text("Current Value").font(.headline)
                Text(current).textSelection(.enabled)
                if let data = review.imageData(for: row.id, fromFile: false) {
                    PhotoPreview(data: data).frame(maxHeight: imageHeight)
                }
            }
            Text("File Value").font(.headline)
            Text(row.proposed).textSelection(.enabled)
            if let data = review.imageData(for: row.id, fromFile: true) {
                PhotoPreview(data: data).frame(maxHeight: imageHeight)
            }
            Text(row.id.uuidString).font(.caption).textSelection(.enabled)
        }
    }

    private var title: LocalizedStringKey {
        switch row.kind {
        case .item:
            "Item"
        case .mark:
            "Mark"
        case .period:
            "Period"
        case .photo:
            "Photo"
        case .tag:
            "Tag"
        }
    }
}
