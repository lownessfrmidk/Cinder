import SwiftUI

struct BrowseView: View {
    @EnvironmentObject var model: AppModel
    @State private var search = ""
    @State private var showAddSource = false
    @State private var sourceURL = ""

    var filtered: [SourceApp] {
        search.isEmpty ? model.allApps : model.allApps.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { app in
                HStack(spacing: 12) {
                    AppIcon(name: app.name, url: app.iconURL)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(app.name).font(.headline)
                        Text(app.subtitle ?? app.developerName ?? "").font(.subheadline).foregroundStyle(.secondary)
                        Text("v\(app.version)").font(.caption).foregroundStyle(.tertiary)
                    }
                    Spacer()
                    InstallButton(app: app)
                }
                .padding(.vertical, 4)
            }
            .listStyle(.plain)
            .searchable(text: $search)
            .navigationTitle("Cinder")
            .toolbar {
                Button { showAddSource = true } label: { Image(systemName: "plus") }
            }
            .alert("Add source", isPresented: $showAddSource) {
                TextField("https://…/source.json", text: $sourceURL).textInputAutocapitalization(.never)
                Button("Add") {
                    if let url = URL(string: sourceURL) { Task { await model.addSource(from: url) } }
                    sourceURL = ""
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}

struct InstallButton: View {
    @EnvironmentObject var model: AppModel
    let app: SourceApp

    var body: some View {
        if let p = model.progress[app.bundleID] {
            VStack(spacing: 2) {
                ProgressView(value: p.fraction).frame(width: 70)
                Text(p.stage.rawValue).font(.system(size: 9)).foregroundStyle(.secondary)
            }
        } else if model.isInstalled(app) {
            Text("Installed").font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
        } else {
            Button("Get") { Task { await model.install(app) } }
                .buttonStyle(.borderedProminent).buttonBorderShape(.capsule)
                .disabled(!model.setupComplete)
        }
    }
}
