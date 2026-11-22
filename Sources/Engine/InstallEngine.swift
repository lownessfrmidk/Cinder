import Foundation

/// The seam between Cinder's UI and the real signing/install stack.
/// Swap `MockInstallEngine` for a real implementation backed by
/// minimuxer / em_proxy / AltSign (see README).
protocol InstallEngine {
    var isReady: Bool { get async }
    func importPairingFile(_ url: URL) async throws
    func startLoopbackVPN() async throws
    func signIn(appleID: String, password: String) async throws
    func install(_ app: SourceApp, progress: @escaping @Sendable (InstallProgress) -> Void) async throws -> InstalledApp
    func refresh(_ app: InstalledApp) async throws -> InstalledApp
    func remove(_ app: InstalledApp) async throws
}

enum EngineError: LocalizedError {
    case notReady, limitReached
    var errorDescription: String? {
        switch self {
        case .notReady: return "Finish setup first (pairing file, VPN and Apple ID)."
        case .limitReached: return "Free accounts can have \(FreeAccountLimits.maxActiveApps) active apps."
        }
    }
}

/// Simulates every step so the UI can be built and tested without the real engine.
actor MockInstallEngine: InstallEngine {
    private var paired = false, vpn = false, signedIn = false

    var isReady: Bool { paired && vpn && signedIn }

    func importPairingFile(_ url: URL) async throws { try await Task.sleep(for: .seconds(0.6)); paired = true }
    func startLoopbackVPN() async throws { try await Task.sleep(for: .seconds(0.6)); vpn = true }
    func signIn(appleID: String, password: String) async throws { try await Task.sleep(for: .seconds(1)); signedIn = true }

    func install(_ app: SourceApp, progress: @escaping @Sendable (InstallProgress) -> Void) async throws -> InstalledApp {
        guard isReady else { throw EngineError.notReady }
        for stage in [InstallStage.downloading, .signing, .installing] {
            for step in 0...4 {
                progress(.init(stage: stage, fraction: Double(step) / 4))
                try await Task.sleep(for: .seconds(0.2))
            }
        }
        progress(.init(stage: .done, fraction: 1))
        let now = Date()
        return InstalledApp(bundleID: app.bundleID, name: app.name, version: app.version, iconURL: app.iconURL,
                            installedAt: now,
                            expiresAt: Calendar.current.date(byAdding: .day, value: FreeAccountLimits.validityDays, to: now)!)
    }

    func refresh(_ app: InstalledApp) async throws -> InstalledApp {
        guard isReady else { throw EngineError.notReady }
        try await Task.sleep(for: .seconds(1))
        var a = app
        a.expiresAt = Calendar.current.date(byAdding: .day, value: FreeAccountLimits.validityDays, to: .now)!
        a.status = .installed
        return a
    }

    func remove(_ app: InstalledApp) async throws { try await Task.sleep(for: .seconds(0.3)) }
}
