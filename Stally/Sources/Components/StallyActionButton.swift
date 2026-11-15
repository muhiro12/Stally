import SwiftUI

struct StallyActionButton: View {
    let label: StallyActionLabel
    let role: ButtonRole?
    let action: () -> Void

    var body: some View {
        Button(role: role, action: action) {
            label
        }
    }

    init(_ label: StallyActionLabel, action: @escaping () -> Void) {
        self.init(label, role: nil, action: action)
    }

    init(_ label: StallyActionLabel, role: ButtonRole?, action: @escaping () -> Void) {
        self.label = label
        self.role = role
        self.action = action
    }
}
