import MHUI
import SwiftData
import SwiftUI

struct StallyAdvancedSettingsView: View {
    @Environment(\.modelContext)
    private var context

    var body: some View {
        List {
            NavigationLink {
                DiagnosticsView(container: context.container, startupError: nil)
            } label: {
                Label("Debug", systemImage: "ladybug")
            }
        }
        .mhListChrome(.native)
        .navigationTitle("Advanced")
    }
}
