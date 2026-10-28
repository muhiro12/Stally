import StallyLibrary
import SwiftUI

struct TagNameView: View {
    let tag: Tag
    let tags: [Tag]

    private var hasDuplicateName: Bool {
        tags.count { candidate in
            candidate.name == tag.name
        } > 1
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(tag.name)
            if hasDuplicateName {
                Text(tag.uuid.uuidString)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
    }
}
