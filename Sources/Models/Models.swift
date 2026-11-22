import Foundation

struct SourceApp: Codable, Identifiable, Hashable {
    var id: String { bundleID }
    let bundleID: String
    let name: String
    let subtitle: String?
    let developerName: String?
    let version: String
    let size: Int64?
    let iconURL: URL?
    let downloadURL: URL
}

struct Source: Codable, Identifiable, Hashable {
    var id: String { identifier }
    let identifier: String
    let name: String
    let apps: [SourceApp]
}

enum AppStatus: String, Codable { case installed, refreshing, expired }

struct InstalledApp: Codable, Identifiable, Hashable {
    var id: String { bundleID }
    let bundleID: String
    let name: String
    var version: String
    var iconURL: URL?
    var installedAt: Date
    var expiresAt: Date
    var status: AppStatus = .installed

    var daysLeft: Int {
        max(0, Calendar.current.dateComponents([.day], from: .now, to: expiresAt).day ?? 0)
    }
    var isExpired: Bool { expiresAt <= .now }
}

enum InstallStage: String {
    case downloading = "Downloading IPA"
    case signing = "Signing"
    case installing = "Installing"
    case done = "Done"
}

struct InstallProgress { var stage: InstallStage; var fraction: Double }

/// Free Apple ID limits.
enum FreeAccountLimits {
    static let maxActiveApps = 3
    static let maxAppIDsPerWeek = 10
    static let validityDays = 7
}
