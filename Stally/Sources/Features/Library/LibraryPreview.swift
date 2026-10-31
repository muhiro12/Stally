#if DEBUG
import MHUI
import StallyLibrary
import SwiftData
import SwiftUI

#Preview("Development records") {
    LibraryPreview()
}

private struct LibraryPreview: View {
    @State private var result: Result<ModelContainer, Error> = .init {
        try StallyDevelopmentStore.preview()
    }

    var body: some View {
        switch result {
        case .success(let container):
            LibraryView()
                .modelContainer(container)
                .environment(RemoteUpdateOperations())
                .environment(TransferPresentation())
                .mhTheme(.standard)
        case .failure(let error):
            Text(verbatim: error.localizedDescription)
        }
    }
}
#endif
