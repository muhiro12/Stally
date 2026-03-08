import SwiftUI

enum StallyRuntimeLifecycleSupport {
    struct Plan: Sendable {
        struct Task: Sendable {
            let name: String
            let operation: @MainActor @Sendable () async -> Void
        }

        let startupTasks: [Task]
        let activeTasks: [Task]
        let skipFirstActivePhase: Bool
    }

    static func makePlan(
        startRuntimeIfNeeded: @escaping @MainActor @Sendable () -> Void,
        loadReviewPreferencesIfNeeded: @escaping @MainActor @Sendable () -> Void,
        applyPendingDeepLinkIfNeeded: @escaping @MainActor @Sendable () async -> Void
    ) -> Plan {
        .init(
            startupTasks: [
                .init(name: "startRuntime") {
                    startRuntimeIfNeeded()
                },
                .init(name: "loadReviewPreferences") {
                    loadReviewPreferencesIfNeeded()
                },
                .init(name: "applyPendingDeepLink") {
                    await applyPendingDeepLinkIfNeeded()
                }
            ],
            activeTasks: [
                .init(name: "startRuntime") {
                    startRuntimeIfNeeded()
                }
            ],
            skipFirstActivePhase: true
        )
    }
}

private struct StallyRuntimeLifecycleModifier: ViewModifier {
    @Environment(\.scenePhase)
    private var scenePhase

    let plan: StallyRuntimeLifecycleSupport.Plan

    @State private var hasHandledInitialAppearance = false
    @State private var hasEnteredActivePhase = false

    func body(content: Content) -> some View {
        content
            .task {
                guard hasHandledInitialAppearance == false else {
                    return
                }

                hasHandledInitialAppearance = true
                await run(tasks: plan.startupTasks)
            }
            .onChange(of: scenePhase) {
                guard scenePhase == .active else {
                    return
                }

                Task {
                    if hasEnteredActivePhase == false {
                        hasEnteredActivePhase = true

                        if plan.skipFirstActivePhase {
                            return
                        }
                    }

                    await run(tasks: plan.activeTasks)
                }
            }
    }

    @MainActor
    private func run(
        tasks: [StallyRuntimeLifecycleSupport.Plan.Task]
    ) async {
        for task in tasks {
            await task.operation()
        }
    }
}

extension View {
    func stallyRuntimeLifecycle(
        plan: StallyRuntimeLifecycleSupport.Plan
    ) -> some View {
        modifier(
            StallyRuntimeLifecycleModifier(
                plan: plan
            )
        )
    }
}
