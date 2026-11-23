import SwiftUI

struct MarkDayClock: ViewModifier {
    @Environment(\.scenePhase)
    private var scenePhase
    @State private var today = RecordDateDraft.today

    func body(content: Content) -> some View {
        content
            .environment(\.markToday, today)
            .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
                today = RecordDateDraft.today
            }
            .onReceive(NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)) { _ in
                today = RecordDateDraft.today
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    today = RecordDateDraft.today
                }
            }
    }
}

extension EnvironmentValues {
    @Entry var markToday = RecordDateDraft.today
}
