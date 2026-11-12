import MHUI
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct ItemContentShareView: View {
    struct Content: Identifiable {
        let id = UUID()
        // Share exactly the preview the person opened, even if the underlying Item changes.
        let text: String
    }

    @Environment(\.dismiss)
    private var dismiss
    let content: Content
    @State private var copied = false

    var body: some View {
        NavigationStack {
            Form {
                MHContainerContent {
                    Section {
                        Text(verbatim: content.text)
                            .textSelection(.enabled)
                    } footer: {
                        Text("Includes name, note, and link. Photos, tags, Marks, and periods are not included.")
                    }
                    Section {
                        StallyActionButton(.copyItemContent) {
                            copy()
                        }
                        ShareLink(item: content.text) {
                            StallyActionLabel.shareItemContent
                        }
                        if copied {
                            Label("Copied", systemImage: "checkmark")
                        }
                    }
                }
            }
            .mhFormChrome(.content)
            .navigationTitle("Item Content")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    StallyActionButton(.done) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func copy() {
        #if canImport(UIKit)
        UIPasteboard.general.string = content.text
        UIAccessibility.post(notification: .announcement, argument: String(localized: "Copied"))
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(content.text, forType: .string)
        #endif
        copied = true
    }
}
