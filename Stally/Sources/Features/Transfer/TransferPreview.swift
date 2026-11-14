#if DEBUG
import MHUI
import StallyLibrary
import SwiftData
import SwiftUI

#Preview("Import and export") {
    TransferPreview()
}

private struct TransferPreview: View {
    @State private var result: Result<ModelContainer, Error> = .init {
        try StallyDevelopmentStore.preview()
    }

    var body: some View {
        switch result {
        case .success(let container):
            TransferView(initialURL: nil)
                .modelContainer(container)
                .environment(RemoteUpdateOperations())
                .environment(StallyLibrarySession(updates: .init(), observesAccount: false))
                .mhTheme(.standard)
        case .failure(let error):
            Text(verbatim: error.localizedDescription)
        }
    }
}
#endif
