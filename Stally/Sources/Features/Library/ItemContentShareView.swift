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
        var isTimeTogether = false
        // Share exactly the preview the person opened, even if the underlying Item changes.
        let text: String

        var title: LocalizedStringResource {
            isTimeTogether ? "Time Together" : "Item Content"
        }
    }

    @Environment(\.dismiss)
    private var dismiss
    let content: Content
    @State private var copied = false

    var body: some View {
        NavigationStack {
            Form {
                MHContainerContent {
                    previewSection
                    Section {
                        StallyActionButton(content.isTimeTogether ? .copyReport : .copyItemContent) {
                            copy()
                        }
                        ShareLink(item: content.text) {
                            if content.isTimeTogether {
                                StallyActionLabel.shareTimeTogether
                            } else {
                                StallyActionLabel.shareItemContent
                            }
                        }
                        if copied {
                            Label("Copied", systemImage: "checkmark")
                        }
                    }
                }
            }
            .mhFormChrome(.content)
            .navigationTitle(Text(content.title))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    StallyActionButton(.done) {
                        dismiss()
                    }
                }
            }
        }
    }

    private var previewSection: some View {
        Section {
            Text(verbatim: content.text)
                .textSelection(.enabled)
                .draggable(content.text)
        } footer: {
            if content.isTimeTogether {
                Text(
                    """
                    Includes the Item name, calculation date, and time together. \
                    Notes, links, photos, tags, and Marks are not included.
                    """
                )
            } else {
                Text("Includes name, note, and link. Photos, tags, Marks, and periods are not included.")
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
