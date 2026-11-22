import SwiftUI

struct MyAppsView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("\(model.installed.count) of \(FreeAccountLimits.maxActiveApps) free slots used")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                ForEach(model.installed) { app in
                    HStack(spacing: 12) {
                        AppIcon(name: app.name, url: app.iconURL, size: 48)
                        VStack(alignment: .leading) {
                            Text(app.name).font(.headline)
                            Text("v\(app.version)").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if model.refreshing.contains(app.bundleID) {
                            ProgressView()
                        } else {
                            ExpiryBadge(app: app)
                        }
                    }
                    .swipeActions {
                        Button("Delete", role: .destructive) { Task { await model.remove(app) } }
                        Button("Refresh") { Task { await model.refresh(app) } }.tint(.orange)
                    }
                }
            }
            .overlay {
                if model.installed.isEmpty {
                    ContentUnavailableView("No apps yet", systemImage: "flame",
                                           description: Text("Install something from Browse."))
                }
            }
            .navigationTitle("My Apps")
            .toolbar {
                Button("Refresh All") { Task { await model.refreshAll() } }
                    .disabled(model.installed.isEmpty || !model.setupComplete)
            }
        }
    }
}

struct ExpiryBadge: View {
    let app: InstalledApp
    var color: Color { app.isExpired ? .red : app.daysLeft <= 2 ? .orange : .green }
    var text: String { app.isExpired ? "Expired" : app.daysLeft == 0 ? "<1 day" : "\(app.daysLeft)d left" }

    var body: some View {
        Text(text).font(.caption.weight(.bold)).foregroundStyle(color)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(color.opacity(0.15), in: Capsule())
    }
}
