import SwiftUI

struct ItemStartDateText: View {
    @Environment(\.locale)
    private var locale

    let start: ItemStart

    var body: some View {
        Text(ItemTimeOperations.startText(for: start, locale: locale))
    }
}
