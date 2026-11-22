import Foundation

/// Real engine: compiles, but every method is an integration point.
/// Fill these in with the SideStore stack (AGPL-3.0, check licensing):
///   - minimuxer (Rust) + em_proxy: lockdown / AFC / installation_proxy over loopback
///   - AltSign: Apple developer API + IPA re-signing
///   - an anisette server for Apple ID login
actor RealInstallEngine: InstallEngine {
    enum NotImplemented: LocalizedError {
        case step(String)
        var errorDescription: String? { if case .step(let s) = self { return "Not implemented yet: \(s)" }; return nil }
    }

    var isReady: Bool { false }

    func importPairingFile(_ url: URL) async throws {
        // 1. Read the pairing plist (security-scoped URL) and store it in app support.
        // 2. Hand it to minimuxer so it can open a lockdown session.
        throw NotImplemented.step("pairing file import")
    }

    func startLoopbackVPN() async throws {
        // A loopback VPN needs the Network Extension entitlement, which free accounts
        // can't get. Plan: detect/ask the user to enable an existing loopback VPN app
        // and verify reachability of 10.7.0.1 (em_proxy / minimuxer).
        throw NotImplemented.step("loopback VPN")
    }

    func signIn(appleID: String, password: String) async throws {
        // Fetch anisette -> GrandSlam auth (2FA) -> create team/cert via AltSign.
        throw NotImplemented.step("Apple ID sign-in")
    }

    func install(_ app: SourceApp, progress: @escaping @Sendable (InstallProgress) -> Void) async throws -> InstalledApp {
        // download IPA -> register App ID (bundle ID suffixed w/ team) -> provisioning profile
        // -> AltSign re-sign -> minimuxer installation_proxy install.
        throw NotImplemented.step("install")
    }

    func refresh(_ app: InstalledApp) async throws -> InstalledApp {
        // Fetch new profile for the same App ID, install profile only (no re-download needed).
        throw NotImplemented.step("refresh")
    }

    func remove(_ app: InstalledApp) async throws { throw NotImplemented.step("remove") }
}
