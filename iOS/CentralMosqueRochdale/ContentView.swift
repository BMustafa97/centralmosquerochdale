import SwiftUI
import UserNotifications
import CoreLocation
import Combine

// Prayer Times Models and Views
struct PrayerTime {
    let name: String
    let startTime: String
    let jamaahTime: String
    let icon: String
}

struct PrayerTimesView: View {
    let prayerTimes = [
        PrayerTime(name: "Fajr", startTime: "5:45", jamaahTime: "6:00", icon: "sunrise"),
        PrayerTime(name: "Dhuhr", startTime: "12:30", jamaahTime: "1:15", icon: "sun.max"),
        PrayerTime(name: "Asr", startTime: "3:45", jamaahTime: "4:00", icon: "sun.and.horizon"),
        PrayerTime(name: "Maghrib", startTime: "6:20", jamaahTime: "6:25", icon: "sunset"),
        PrayerTime(name: "Esha", startTime: "7:45", jamaahTime: "8:00", icon: "moon.stars")
    ]
    
    let jummahTime = "1:30"
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Today's Prayer Times")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(getCurrentDate())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Jummah Special Section
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.green)
                            .font(.title2)
                        Text("Jummah Prayer")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    
                    HStack {
                        Text("Friday Jamaa'ah")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(jummahTime)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Prayer Times Table
                VStack(spacing: 0) {
                    // Table Header
                    HStack {
                        Text("Prayer")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("Start Time")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                        
                        Text("Jamaa'ah")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    
                    // Prayer Rows
                    ForEach(Array(prayerTimes.enumerated()), id: \.offset) { index, prayer in
                        PrayerRow(prayer: prayer, isEven: index % 2 == 0)
                    }
                }
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                
                // Footer Info
                VStack(spacing: 8) {
                    Text("🕌 Central Mosque Rochdale")
                        .font(.footnote)
                        .fontWeight(.medium)
                    
                    Text("Prayer times are calculated for Rochdale, UK")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
        .navigationTitle("Prayer Times")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func getCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: Date())
    }
}

struct PrayerRow: View {
    let prayer: PrayerTime
    let isEven: Bool
    
    var body: some View {
        HStack {
            HStack(spacing: 12) {
                Image(systemName: prayer.icon)
                    .foregroundColor(.blue)
                    .font(.title3)
                    .frame(width: 20)
                
                Text(prayer.name)
                    .font(.body)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(prayer.startTime)
                .font(.body)
                .fontWeight(.regular)
                .frame(maxWidth: .infinity)
            
            Text(prayer.jamaahTime)
                .font(.body)
                .fontWeight(.bold)
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
        .background(isEven ? Color.gray.opacity(0.05) : Color.clear)
    }
}

// Qibla Compass Models and Views
class QiblaCompassViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var qiblaDirection: Double = 0
    @Published var currentHeading: Double = 0
    @Published var locationPermissionStatus: CLAuthorizationStatus = .notDetermined
    @Published var isCalculatingQibla = false
    @Published var errorMessage: String? = nil
    @Published var userLocation: CLLocation? = nil
    @Published var distanceToKaaba: Double = 0
    
    private let locationManager = CLLocationManager()
    private let kaabaCoordinates = CLLocationCoordinate2D(latitude: 21.4225, longitude: 39.8262)
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startLocationUpdates() {
        guard locationPermissionStatus == .authorizedWhenInUse || locationPermissionStatus == .authorizedAlways else {
            errorMessage = "Location permission required"
            return
        }
        
        isCalculatingQibla = true
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
    
    private func calculateQiblaDirection(from userLocation: CLLocation) {
        let userLat = userLocation.coordinate.latitude * .pi / 180
        let userLon = userLocation.coordinate.longitude * .pi / 180
        let kaabaLat = kaabaCoordinates.latitude * .pi / 180
        let kaabaLon = kaabaCoordinates.longitude * .pi / 180
        
        let dLon = kaabaLon - userLon
        
        let x = sin(dLon) * cos(kaabaLat)
        let y = cos(userLat) * sin(kaabaLat) - sin(userLat) * cos(kaabaLat) * cos(dLon)
        
        let qiblaRadians = atan2(x, y)
        var qiblaDegrees = qiblaRadians * 180 / .pi
        
        if qiblaDegrees < 0 {
            qiblaDegrees += 360
        }
        
        self.qiblaDirection = qiblaDegrees
        
        // Calculate distance to Kaaba
        let kaabaLocation = CLLocation(latitude: kaabaCoordinates.latitude, longitude: kaabaCoordinates.longitude)
        self.distanceToKaaba = userLocation.distance(from: kaabaLocation) / 1000 // Convert to kilometers
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.locationPermissionStatus = manager.authorizationStatus
            if self.locationPermissionStatus == .authorizedWhenInUse || self.locationPermissionStatus == .authorizedAlways {
                self.startLocationUpdates()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async {
            self.userLocation = location
            self.calculateQiblaDirection(from: location)
            self.isCalculatingQibla = false
            self.errorMessage = nil
        }
        
        // Stop location updates to save battery
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        DispatchQueue.main.async {
            self.currentHeading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.errorMessage = "Failed to get location: \(error.localizedDescription)"
            self.isCalculatingQibla = false
        }
    }
}

struct QiblaCompassView: View {
    @StateObject private var viewModel = QiblaCompassViewModel()
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 8) {
                Text("🕋 Qibla Direction")
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let location = viewModel.userLocation {
                    Text("📍 \(formatLocation(location))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top)
            
            // Permission/Error Handling
            if viewModel.locationPermissionStatus != .authorizedWhenInUse && viewModel.locationPermissionStatus != .authorizedAlways {
                VStack(spacing: 16) {
                    Image(systemName: "location.slash")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    
                    Text("Location Permission Required")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("To find the Qibla direction, please allow location access.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Enable Location") {
                        viewModel.requestLocationPermission()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                
            } else if let errorMessage = viewModel.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                    
                    Text("Error")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Try Again") {
                        viewModel.startLocationUpdates()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                
            } else if viewModel.isCalculatingQibla {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    
                    Text("Finding Qibla Direction...")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text("Getting your location...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                
            } else {
                // Main Compass View
                VStack(spacing: 30) {
                    // Compass
                    ZStack {
                        // Compass Background
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 250, height: 250)
                        
                        // Compass Markings
                        ForEach(0..<36) { index in
                            Rectangle()
                                .fill(index % 9 == 0 ? Color.primary : Color.gray)
                                .frame(width: index % 9 == 0 ? 3 : 1, height: index % 9 == 0 ? 20 : 10)
                                .offset(y: -115)
                                .rotationEffect(.degrees(Double(index) * 10))
                        }
                        
                        // Cardinal Directions
                        VStack {
                            Text("N")
                                .font(.headline)
                                .fontWeight(.bold)
                                .offset(y: -110)
                            Spacer()
                            Text("S")
                                .font(.headline)
                                .fontWeight(.bold)
                                .offset(y: 110)
                        }
                        .frame(height: 250)
                        
                        HStack {
                            Text("W")
                                .font(.headline)
                                .fontWeight(.bold)
                                .offset(x: -110)
                            Spacer()
                            Text("E")
                                .font(.headline)
                                .fontWeight(.bold)
                                .offset(x: 110)
                        }
                        .frame(width: 250)
                        
                        // Qibla Indicator (Fixed to Qibla direction)
                        Image(systemName: "triangle.fill")
                            .font(.title)
                            .foregroundColor(.green)
                            .offset(y: -100)
                            .rotationEffect(.degrees(viewModel.qiblaDirection - viewModel.currentHeading))
                        
                        // Phone Direction Indicator
                        Image(systemName: "phone")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .offset(y: -80)
                        
                        // Center Kaaba
                        Text("🕋")
                            .font(.title)
                    }
                    .rotationEffect(.degrees(-viewModel.currentHeading))
                    
                    // Direction Info
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Qibla Direction")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(Int(viewModel.qiblaDirection))°")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Your Heading")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(Int(viewModel.currentHeading))°")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        if viewModel.distanceToKaaba > 0 {
                            HStack {
                                Image(systemName: "location")
                                    .foregroundColor(.secondary)
                                Text("Distance to Kaaba: \(String(format: "%.0f", viewModel.distanceToKaaba)) km")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Instructions
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "triangle.fill")
                                .foregroundColor(.green)
                            Text("Green arrow points to Qibla")
                                .font(.caption)
                        }
                        
                        HStack {
                            Image(systemName: "phone")
                                .foregroundColor(.blue)
                            Text("Blue phone shows your direction")
                                .font(.caption)
                        }
                        
                        Text("Hold your phone flat and rotate until the green arrow points up")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            
            Spacer()
            
            // Footer
            Text("🕌 Central Mosque Rochdale")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .navigationTitle("Qibla Compass")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel.locationPermissionStatus == .authorizedWhenInUse || viewModel.locationPermissionStatus == .authorizedAlways {
                viewModel.startLocationUpdates()
            }
        }
    }
    
    private func formatLocation(_ location: CLLocation) -> String {
        let formatter = CLGeocoder()
        return "Lat: \(String(format: "%.4f", location.coordinate.latitude)), Lon: \(String(format: "%.4f", location.coordinate.longitude))"
    }
}

struct MosqueEventsView: View {
    var body: some View {
        Text("Mosque Events - Coming Soon!")
            .navigationTitle("Events")
    }
}

// Notification Settings Models and Views
struct PrayerNotificationSetting {
    let prayer: String
    let icon: String
    var isEnabled: Bool
    var reminderMinutes: Int
}

class NotificationSettingsViewModel: ObservableObject {
    @Published var prayerNotifications = [
        PrayerNotificationSetting(prayer: "Fajr", icon: "sunrise", isEnabled: true, reminderMinutes: 10),
        PrayerNotificationSetting(prayer: "Dhuhr", icon: "sun.max", isEnabled: true, reminderMinutes: 15),
        PrayerNotificationSetting(prayer: "Asr", icon: "sun.and.horizon", isEnabled: true, reminderMinutes: 10),
        PrayerNotificationSetting(prayer: "Maghrib", icon: "sunset", isEnabled: true, reminderMinutes: 5),
        PrayerNotificationSetting(prayer: "Esha", icon: "moon.stars", isEnabled: true, reminderMinutes: 10)
    ]
    
    @Published var jummahEnabled = true
    @Published var jummahReminderMinutes = 30
    @Published var notificationsPermissionGranted = false
    
    init() {
        checkNotificationPermission()
    }
    
    func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationsPermissionGranted = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.notificationsPermissionGranted = granted
            }
        }
    }
}

struct NotificationSettingsView: View {
    @StateObject private var viewModel = NotificationSettingsViewModel()
    
    var body: some View {
        List {
            // Permission Section
            Section {
                if !viewModel.notificationsPermissionGranted {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "bell.slash")
                                .foregroundColor(.orange)
                                .font(.title2)
                            Text("Notifications Disabled")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        Text("To receive prayer reminders, please enable notifications for this app.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button("Enable Notifications") {
                            viewModel.requestNotificationPermission()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.vertical, 8)
                } else {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Notifications Enabled")
                            .font(.headline)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Permission Status")
            }
            
            // Daily Prayers Section
            Section {
                ForEach(Array(viewModel.prayerNotifications.enumerated()), id: \.offset) { index, setting in
                    PrayerNotificationRow(
                        setting: $viewModel.prayerNotifications[index],
                        isEnabled: viewModel.notificationsPermissionGranted
                    )
                }
            } header: {
                HStack {
                    Image(systemName: "clock")
                    Text("Daily Prayer Reminders")
                }
            } footer: {
                Text("Receive notifications before each prayer time to never miss Jamaa'ah.")
                    .font(.caption)
            }
            
            // Jummah Section
            Section {
                HStack {
                    HStack(spacing: 12) {
                        Image(systemName: "calendar")
                            .foregroundColor(.green)
                            .font(.title3)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Jummah Prayer")
                                .font(.body)
                                .fontWeight(.medium)
                            Text("Friday congregation")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $viewModel.jummahEnabled)
                        .disabled(!viewModel.notificationsPermissionGranted)
                }
                
                if viewModel.jummahEnabled && viewModel.notificationsPermissionGranted {
                    HStack {
                        Text("Remind me")
                            .foregroundColor(.secondary)
                        Spacer()
                        Picker("Minutes", selection: $viewModel.jummahReminderMinutes) {
                            Text("15 minutes before").tag(15)
                            Text("30 minutes before").tag(30)
                            Text("1 hour before").tag(60)
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
            } header: {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                    Text("Jummah Reminder")
                }
            } footer: {
                Text("Special reminder for Friday Jummah prayer.")
                    .font(.caption)
            }
            
            // Settings Section
            Section {
                HStack {
                    Image(systemName: "speaker.wave.2")
                        .foregroundColor(.blue)
                    Text("Notification Sound")
                    Spacer()
                    Text("Default")
                        .foregroundColor(.secondary)
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                
                HStack {
                    Image(systemName: "gear")
                        .foregroundColor(.blue)
                    Text("Open Settings App")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .onTapGesture {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
            } header: {
                Text("Additional Settings")
            } footer: {
                Text("🕌 Central Mosque Rochdale\nStay connected with your prayer times")
                    .multilineTextAlignment(.center)
                    .font(.caption)
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.checkNotificationPermission()
        }
    }
}

struct PrayerNotificationRow: View {
    @Binding var setting: PrayerNotificationSetting
    let isEnabled: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: setting.icon)
                        .foregroundColor(.blue)
                        .font(.title3)
                        .frame(width: 24)
                    
                    Text(setting.prayer)
                        .font(.body)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                Toggle("", isOn: $setting.isEnabled)
                    .disabled(!isEnabled)
            }
            
            if setting.isEnabled && isEnabled {
                HStack {
                    Text("Remind me")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Picker("Minutes", selection: $setting.reminderMinutes) {
                        Text("5 minutes before").tag(5)
                        Text("10 minutes before").tag(10)
                        Text("15 minutes before").tag(15)
                        Text("30 minutes before").tag(30)
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                .padding(.leading, 36)
            }
        }
    }
}

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("🕌 Central Mosque\nRochdale")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.top, 20)
                
                Text("Welcome to the Mosque App")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 20) {
                    NavigationLink(destination: PrayerTimesView()) {
                        FeatureRow(icon: "clock", title: "Prayer Times", description: "View daily prayer schedule")
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: QiblaCompassView()) {
                        FeatureRow(icon: "safari", title: "Qibla Compass", description: "Find prayer direction")
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: MosqueEventsView()) {
                        FeatureRow(icon: "calendar", title: "Events", description: "Mosque events & announcements")
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: NotificationSettingsView()) {
                        FeatureRow(icon: "bell", title: "Notifications", description: "Prayer reminders")
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding()
                
                Spacer()
            }
            .padding()
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

#Preview {
    ContentView()
}