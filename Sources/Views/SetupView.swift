import SwiftUI

struct SetupView: View {
    @EnvironmentObject var model: AppModel
    @State private var showImporter = false
    @State private var showSignIn = false
    @State private var appleID = ""
    @State private var password = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    step(1, "Pairing file", "Lets your phone act as its own trusted computer.",
                         done: model.hasPairing, action: "Import") { showImporter = true }
                    step(2, "Loopback VPN", "Routes install traffic back to this device.",
                         done: model.vpnOn, action: "Enable") { Task { await model.enableVPN() } }
                    step(3, "Apple ID", "Used only to request a free signing certificate.",
                         done: model.signedIn, action: "Sign in") { showSignIn = true }
                } footer: {
                    Text("Free accounts: apps last 7 days, max 3 active apps, 10 App IDs per week.")
                }
                if model.setupComplete {
                    Label("Ready to install", systemImage: "checkmark.seal.fill").foregroundStyle(.green)
                }
            }
            .navigationTitle("Setup")
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [.data, .propertyList]) { result in
                if case .success(let url) = result { Task { await model.importPairing(url) } }
            }
            .alert("Apple ID", isPresented: $showSignIn) {
                TextField("Email", text: $appleID).textInputAutocapitalization(.never)
                SecureField("Password", text: $password)
                Button("Sign in") { Task { await model.signIn(appleID, password); password = "" } }
                Button("Cancel", role: .cancel) {}
            } message: { Text("Consider using a secondary Apple ID.") }
        }
    }

    @ViewBuilder
    private func step(_ n: Int, _ title: String, _ detail: String, done: Bool,
                      action: String, perform: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Image(systemName: done ? "checkmark.circle.fill" : "\(n).circle")
                .font(.title2).foregroundStyle(done ? .green : .orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if !done { Button(action, action: perform).buttonStyle(.bordered) }
        }
    }
}
