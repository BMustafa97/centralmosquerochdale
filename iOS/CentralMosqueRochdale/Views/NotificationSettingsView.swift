import SwiftUI
import UserNotifications
import Combine

// MARK: - Notification Models
struct PrayerNotificationSettings: Codable {
    var fajrEnabled: Bool = true
    var dhuhrEnabled: Bool = true
    var asrEnabled: Bool = true
    var maghribEnabled: Bool = true
    var ishaEnabled: Bool = true
    var reminderMinutes: Int = 10 // 5, 10, or 15 minutes before
    
    func isEnabledFor(prayer: String) -> Bool {
        switch prayer.lowercased() {
        case "fajr": return fajrEnabled
        case "dhuhr": return dhuhrEnabled
        case "asr": return asrEnabled
        case "maghrib": return maghribEnabled
        case "isha": return ishaEnabled
        default: return false
        }
    }
    
    mutating func setEnabled(for prayer: String, enabled: Bool) {
        switch prayer.lowercased() {
        case "fajr": fajrEnabled = enabled
        case "dhuhr": dhuhrEnabled = enabled
        case "asr": asrEnabled = enabled
        case "maghrib": maghribEnabled = enabled
        case "isha": ishaEnabled = enabled
        default: break
        }
    }
}

// MARK: - Notification Manager
class PrayerNotificationManager: ObservableObject {
    @Published var settings = PrayerNotificationSettings()
    @Published var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?
    
    private let userDefaults = UserDefaults.standard
    private let settingsKey = "PrayerNotificationSettings"
    
    init() {
        loadSettings()
        checkNotificationPermission()
    }
    
    // MARK: - Permission Management
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Failed to request notification permission: \(error.localizedDescription)"
                } else {
                    self.checkNotificationPermission()
                    if granted {
                        self.scheduleAllNotifications()
                    }
                }
            }
        }
    }
    
    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationPermissionStatus = settings.authorizationStatus
            }
        }
    }
    
    // MARK: - Settings Management
    func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            userDefaults.set(encoded, forKey: settingsKey)
        }
        
        // Reschedule notifications when settings change
        if notificationPermissionStatus == .authorized {
            scheduleAllNotifications()
        }
    }
    
    private func loadSettings() {
        if let data = userDefaults.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(PrayerNotificationSettings.self, from: data) {
            settings = decoded
        }
    }
    
    // MARK: - Notification Scheduling
    func scheduleAllNotifications() {
        // Clear existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Get today's prayer times (you'll need to integrate with your prayer times service)
        let prayers = [
            Prayer(name: "Fajr", startTime: "05:30", jamaaahTime: "05:45"),
            Prayer(name: "Dhuhr", startTime: "12:45", jamaaahTime: "13:00"),
            Prayer(name: "Asr", startTime: "16:15", jamaaahTime: "16:30"),
            Prayer(name: "Maghrib", startTime: "18:45", jamaaahTime: "18:50"),
            Prayer(name: "Isha", startTime: "20:30", jamaaahTime: "20:45")
        ]
        
        for prayer in prayers {
            if settings.isEnabledFor(prayer: prayer.name) {
                scheduleNotification(for: prayer)
            }
        }
    }
    
    private func scheduleNotification(for prayer: Prayer) {
        guard let jamaaahDate = parseTime(prayer.jamaaahTime) else { return }
        
        // Calculate notification time (reminder minutes before Jamaa'ah)
        let notificationDate = jamaaahDate.addingTimeInterval(-TimeInterval(settings.reminderMinutes * 60))
        
        // Don't schedule notifications for past times
        guard notificationDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Prayer Reminder"
        content.body = "\(prayer.name) Jamaa'ah is in \(settings.reminderMinutes) minutes"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "PRAYER_REMINDER"
        content.userInfo = [
            "prayer": prayer.name,
            "jamaaahTime": prayer.jamaaahTime,
            "reminderMinutes": settings.reminderMinutes
        ]
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: notificationDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let identifier = "prayer_\(prayer.name.lowercased())_\(settings.reminderMinutes)min"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to schedule notification for \(prayer.name): \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func parseTime(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard let time = formatter.date(from: timeString) else { return nil }
        
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .day], from: now)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        
        var finalComponents = components
        finalComponents.hour = timeComponents.hour
        finalComponents.minute = timeComponents.minute
        
        return calendar.date(from: finalComponents)
    }
    
    // MARK: - Public Methods
    func togglePrayerNotification(for prayer: String) {
        let currentState = settings.isEnabledFor(prayer: prayer)
        settings.setEnabled(for: prayer, enabled: !currentState)
        saveSettings()
    }
    
    func updateReminderTime(_ minutes: Int) {
        settings.reminderMinutes = minutes
        saveSettings()
    }
}

// MARK: - Notification Settings View
struct NotificationSettingsView: View {
    @StateObject private var notificationManager = PrayerNotificationManager()
    @State private var showingPermissionAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Prayer Notifications")) {
                    if notificationManager.notificationPermissionStatus != .authorized {
                        NotificationPermissionView(
                            status: notificationManager.notificationPermissionStatus,
                            onRequestPermission: {
                                notificationManager.requestNotificationPermission()
                            }
                        )
                    } else {
                        NotificationToggleSection(notificationManager: notificationManager)
                        ReminderTimeSection(notificationManager: notificationManager)
                    }
                }
                
                if let errorMessage = notificationManager.errorMessage {
                    Section(header: Text("Error")) {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section(header: Text("About")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Prayer notifications will remind you before Jamaa'ah time at Central Mosque Rochdale.")
                        Text("Make sure to keep notifications enabled in your device settings.")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Notification Settings")
        }
    }
}

struct NotificationPermissionView: View {
    let status: UNAuthorizationStatus
    let onRequestPermission: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bell.slash")
                    .foregroundColor(.orange)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text("Notifications Disabled")
                        .font(.headline)
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Button(action: onRequestPermission) {
                HStack {
                    Image(systemName: "bell")
                    Text(buttonText)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, 8)
    }
    
    private var statusMessage: String {
        switch status {
        case .denied:
            return "Go to Settings to enable notifications"
        case .notDetermined:
            return "Tap to enable prayer reminders"
        default:
            return "Notifications are required for prayer reminders"
        }
    }
    
    private var buttonText: String {
        switch status {
        case .denied:
            return "Open Settings"
        default:
            return "Enable Notifications"
        }
    }
}

struct NotificationToggleSection: View {
    @ObservedObject var notificationManager: PrayerNotificationManager
    
    private let prayers = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]
    
    var body: some View {
        ForEach(prayers, id: \.self) { prayer in
            HStack {
                VStack(alignment: .leading) {
                    Text(prayer)
                        .font(.body)
                        .fontWeight(.medium)
                    Text("Jamaa'ah reminder")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { notificationManager.settings.isEnabledFor(prayer: prayer) },
                    set: { _ in notificationManager.togglePrayerNotification(for: prayer) }
                ))
            }
        }
    }
}

struct ReminderTimeSection: View {
    @ObservedObject var notificationManager: PrayerNotificationManager
    
    private let reminderOptions = [5, 10, 15]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reminder Time")
                .font(.headline)
            
            Text("How many minutes before Jamaa'ah would you like to be reminded?")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Picker("Reminder Time", selection: Binding(
                get: { notificationManager.settings.reminderMinutes },
                set: { notificationManager.updateReminderTime($0) }
            )) {
                ForEach(reminderOptions, id: \.self) { minutes in
                    Text("\(minutes) minutes before")
                        .tag(minutes)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview
struct NotificationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationSettingsView()
    }
}