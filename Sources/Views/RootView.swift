import SwiftUI

struct RootView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        TabView {
            BrowseView().tabItem { Label("Browse", systemImage: "square.grid.2x2") }
            MyAppsView().tabItem { Label("My Apps", systemImage: "flame") }
            SetupView().tabItem { Label("Setup", systemImage: "checklist") }
                .badge(model.setupComplete ? 0 : 1)
        }
        .alert("Something went wrong", isPresented: .constant(model.errorMessage != nil)) {
            Button("OK") { model.errorMessage = nil }
        } message: { Text(model.errorMessage ?? "") }
    }
}

struct AppIcon: View {
    let name: String
    let url: URL?
    var size: CGFloat = 54

    var body: some View {
        AsyncImage(url: url) { img in img.resizable().scaledToFill() } placeholder: {
            ZStack {
                LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                Text(String(name.prefix(1))).font(.title2.bold()).foregroundStyle(.white)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.225, style: .continuous))
    }
}
