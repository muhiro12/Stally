import MHAppRuntimeCore
import StallyLibrary
import SwiftData
import SwiftUI

// swiftlint:disable closure_body_length
struct StallyRootView: View {
    @Environment(StallyAppAssembly.self)
    var assembly
    @Environment(StallyAppModel.self)
    var appModel
    @Environment(MHAppRuntime.self)
    var appRuntime

    @Namespace var navigationNamespace

    @Query(
        sort: [
            SortDescriptor(\Item.createdAt, order: .reverse)
        ]
    )
    var items: [Item]

    var body: some View {
        @Bindable var appModel = appModel

        TabView(selection: $appModel.selectedTab) {
            Tab(
                StallyAppModel.Tab.library.title,
                systemImage: StallyAppModel.Tab.library.symbolName,
                value: .library
            ) {
                stackHost(path: $appModel.libraryPath) {
                    StallyHomeView(
                        snapshot: librarySnapshot,
                        navigationNamespace: navigationNamespace
                    )
                }
            }

            Tab(
                StallyAppModel.Tab.review.title,
                systemImage: StallyAppModel.Tab.review.symbolName,
                value: .review
            ) {
                stackHost(path: $appModel.reviewPath) {
                    StallyReviewView(
                        snapshot: reviewSnapshot
                    )
                }
            }

            Tab(
                StallyAppModel.Tab.insights.title,
                systemImage: StallyAppModel.Tab.insights.symbolName,
                value: .insights
            ) {
                stackHost(path: $appModel.insightsPath) {
                    StallyInsightsView(
                        snapshot: insightsSnapshot
                    )
                }
            }

            Tab(
                StallyAppModel.Tab.archive.title,
                systemImage: StallyAppModel.Tab.archive.symbolName,
                value: .archive
            ) {
                stackHost(path: $appModel.archivePath) {
                    StallyArchiveView(
                        snapshot: archiveSnapshot,
                        navigationNamespace: navigationNamespace
                    )
                }
            }
        }
        .alert(
            "Unable to Complete This Action",
            isPresented: isOperationErrorPresented
        ) {
            Button("OK", role: .cancel) {
                appModel.dismissOperationError()
            }
        } message: {
            Text(appModel.operationErrorMessage ?? "")
        }
        .sheet(item: $appModel.editorRoute) { route in
            editorDestination(for: route)
        }
        .onChange(of: assembly.routePipeline.lastParseFailureURL) { _, failedURL in
            guard failedURL != nil else {
                return
            }

            appModel.presentUnsupportedDeepLinkError()
            assembly.routePipeline.clearLastParseFailure()
        }
        .mhRouteHandler(assembly.routeInbox, apply: applyRoute(_:))
        .onChange(of: appModel.reviewPreferences) { _, newValue in
            newValue.save(in: appRuntime.preferenceStore)
        }
        .onChange(of: appModel.insightsPreferences) { _, newValue in
            newValue.save(in: appRuntime.preferenceStore)
        }
    }
}
// swiftlint:enable closure_body_length
