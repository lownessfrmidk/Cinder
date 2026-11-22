import UserNotifications

enum ExpiryNotifier {
    static func requestAuthorization() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }

    /// Reminds the user 2 days before and 3 hours before each app expires.
    static func reschedule(for apps: [InstalledApp]) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        for app in apps {
            for (offset, label) in [(-2 * 86400.0, "in 2 days"), (-3 * 3600.0, "in 3 hours")] {
                let fire = app.expiresAt.addingTimeInterval(offset)
                guard fire > .now else { continue }
                let content = UNMutableNotificationContent()
                content.title = "\(app.name) expires \(label)"
                content.body = "Open Cinder to refresh it."
                content.sound = .default
                let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                center.add(UNNotificationRequest(identifier: "\(app.bundleID)-\(Int(offset))", content: content, trigger: trigger))
            }
        }
    }
}
