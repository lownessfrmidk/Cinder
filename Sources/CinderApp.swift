import SwiftUI

@main
struct CinderApp: App {
    @StateObject private var model = AppModel.shared
    @Environment(\.scenePhase) private var phase

    init() { BackgroundRefresher.register() }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
                .tint(.orange)
                .task { await ExpiryNotifier.requestAuthorization() }
                .task { await model.refreshExpiring(within: 2) }
        }
        .onChange(of: phase) { _, new in
            if new == .background { BackgroundRefresher.schedule() }
        }
    }
}
