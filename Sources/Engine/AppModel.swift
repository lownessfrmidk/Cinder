import Foundation
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published var sources: [Source] = [SampleData.source]
    @Published var installed: [InstalledApp] = []
    @Published var progress: [String: InstallProgress] = [:]
    @Published var refreshing: Set<String> = []
    @Published var errorMessage: String?

    @Published var hasPairing = false
    @Published var vpnOn = false
    @Published var signedIn = false

    static let shared = AppModel(engine: MockInstallEngine()) // swap for RealInstallEngine()

    let engine: InstallEngine
    private let saveURL = URL.documentsDirectory.appending(path: "installed.json")

    init(engine: InstallEngine) {
        self.engine = engine
        load()
    }

    var setupComplete: Bool { hasPairing && vpnOn && signedIn }
    var allApps: [SourceApp] { sources.flatMap(\.apps) }

    // MARK: Setup
    func importPairing(_ url: URL) async { await run { try await self.engine.importPairingFile(url); self.hasPairing = true } }
    func enableVPN() async { await run { try await self.engine.startLoopbackVPN(); self.vpnOn = true } }
    func signIn(_ id: String, _ pw: String) async { await run { try await self.engine.signIn(appleID: id, password: pw); self.signedIn = true; Keychain.save(id, account: "appleID"); Keychain.save(pw, account: "applePassword") } }

    // MARK: Apps
    func isInstalled(_ app: SourceApp) -> Bool { installed.contains { $0.bundleID == app.bundleID } }

    func install(_ app: SourceApp) async {
        guard installed.count < FreeAccountLimits.maxActiveApps else {
            errorMessage = EngineError.limitReached.localizedDescription; return
        }
        await run {
            defer { self.progress[app.bundleID] = nil }
            let result = try await self.engine.install(app) { p in
                Task { @MainActor in self.progress[app.bundleID] = p }
            }
            self.installed.append(result)
            self.save()
        }
    }

    func refresh(_ app: InstalledApp) async {
        refreshing.insert(app.bundleID)
        defer { refreshing.remove(app.bundleID) }
        await run {
            let updated = try await self.engine.refresh(app)
            if let i = self.installed.firstIndex(where: { $0.id == app.id }) { self.installed[i] = updated }
            self.save()
        }
    }

    func refreshAll() async { for app in installed { await refresh(app) } }

    func remove(_ app: InstalledApp) async {
        await run {
            try await self.engine.remove(app)
            self.installed.removeAll { $0.id == app.id }
            self.save()
        }
    }

    /// Used by background refresh: re-sign anything expiring soon.
    func refreshExpiring(within days: Int) async {
        let cutoff = Calendar.current.date(byAdding: .day, value: days, to: .now)!
        for app in installed where app.expiresAt <= cutoff { await refresh(app) }
    }

    // MARK: Sources
    func addSource(from url: URL) async {
        await run {
            let (data, _) = try await URLSession.shared.data(from: url)
            let source = try JSONDecoder().decode(Source.self, from: data)
            self.sources.removeAll { $0.id == source.id }
            self.sources.append(source)
        }
    }

    // MARK: Helpers
    private func run(_ work: @escaping () async throws -> Void) async {
        do { try await work() } catch { errorMessage = error.localizedDescription }
    }

    private func load() {
        guard let data = try? Data(contentsOf: saveURL),
              let apps = try? JSONDecoder().decode([InstalledApp].self, from: data) else { return }
        installed = apps
    }
    private func save() {
        if let data = try? JSONEncoder().encode(installed) { try? data.write(to: saveURL) }
        ExpiryNotifier.reschedule(for: installed)
    }
}

enum SampleData {
    static let source = Source(identifier: "dev.cinder.sample", name: "Sample Source", apps: [
        SourceApp(bundleID: "com.example.notes", name: "Notes+", subtitle: "A tiny notes app", developerName: "Example Dev",
                  version: "1.2.0", size: 8_400_000, iconURL: nil, downloadURL: URL(string: "https://example.com/notes.ipa")!),
        SourceApp(bundleID: "com.example.player", name: "Player", subtitle: "Plays local media", developerName: "Example Dev",
                  version: "3.0.1", size: 21_000_000, iconURL: nil, downloadURL: URL(string: "https://example.com/player.ipa")!),
        SourceApp(bundleID: "com.example.emu", name: "Emu", subtitle: "Retro game launcher", developerName: "Another Dev",
                  version: "0.9.4", size: 45_000_000, iconURL: nil, downloadURL: URL(string: "https://example.com/emu.ipa")!),
        SourceApp(bundleID: "com.example.tools", name: "Toolbox", subtitle: "Handy utilities", developerName: "Another Dev",
                  version: "2.1.0", size: 12_000_000, iconURL: nil, downloadURL: URL(string: "https://example.com/tools.ipa")!)
    ])
}
