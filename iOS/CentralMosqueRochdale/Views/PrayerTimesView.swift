import SwiftUI

// MARK: - Data Models
struct Prayer: Identifiable, Codable {
    let id = UUID()
    let name: String
    let startTime: String
    let jamaaahTime: String
    
    enum CodingKeys: String, CodingKey {
        case name, startTime, jamaaahTime
    }
}

struct PrayerTime: Codable {
    let adhan: String
    let jamaah: String
}

struct DailyPrayerTimes: Codable {
    let date: String
    let fajr: PrayerTime
    let sunrise: String
    let dhuhr: PrayerTime
    let asr: PrayerTime
    let maghrib: PrayerTime
    let isha: PrayerTime
    let jummah: String?
}

struct YearlyPrayerTimes: Codable {
    let year: Int
    let mosque: String
    let location: LocationData
    let prayerTimes: [DailyPrayerTimes]
    
    struct LocationData: Codable {
        let latitude: Double
        let longitude: Double
    }
}

struct PrayerTimesResponse: Codable {
    let prayers: [Prayer]
}

// MARK: - Prayer Times Service
class PrayerTimesService: ObservableObject {
    @Published var prayers: [Prayer] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentDate: String = ""
    @Published var jummahTime: String = "13:00"
    @Published var selectedDate: Date = Date()
    
    private var yearlyData: YearlyPrayerTimes?
    
    func fetchPrayerTimes(for date: Date = Date()) {
        isLoading = true
        errorMessage = nil
        selectedDate = date
        
        // Get date in YYYY-MM-DD format
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        // Format for display
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "EEEE, d MMMM yyyy"
        currentDate = displayFormatter.string(from: date)
        
        // Load JSON file
        loadPrayerTimesFromJSON(for: dateString)
    }
    
    func goToNextDay() {
        let daysForward = Calendar.current.dateComponents([.day], from: Date(), to: selectedDate).day ?? 0
        if daysForward < 5, let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) {
            fetchPrayerTimes(for: nextDay)
        }
    }
    
    func goToPreviousDay() {
        let daysBack = Calendar.current.dateComponents([.day], from: selectedDate, to: Date()).day ?? 0
        if daysBack < 1, let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) {
            fetchPrayerTimes(for: previousDay)
        }
    }
    
    var canGoForward: Bool {
        let daysForward = Calendar.current.dateComponents([.day], from: Date(), to: selectedDate).day ?? 0
        return daysForward < 5
    }
    
    var canGoBack: Bool {
        let daysBack = Calendar.current.dateComponents([.day], from: selectedDate, to: Date()).day ?? 0
        return daysBack < 1
    }
    
    private func loadPrayerTimesFromJSON(for dateString: String) {
        guard let url = Bundle.main.url(forResource: "PrayerTimes2025", withExtension: "json") else {
            self.errorMessage = "Prayer times file not found"
            self.isLoading = false
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            yearlyData = try decoder.decode(YearlyPrayerTimes.self, from: data)
            
            // Find today's prayer times
            if let todaysPrayers = yearlyData?.prayerTimes.first(where: { $0.date == dateString }) {
                self.prayers = convertToPrayerArray(todaysPrayers)
                self.jummahTime = todaysPrayers.jummah ?? "13:00"
                self.isLoading = false
            } else {
                // If today's date not found, use mock data or show error
                self.errorMessage = "Prayer times for \(dateString) not found in the database"
                loadMockData() // Fallback to mock data
            }
        } catch {
            self.errorMessage = "Error loading prayer times: \(error.localizedDescription)"
            self.isLoading = false
            loadMockData() // Fallback to mock data
        }
    }
    
    private func convertToPrayerArray(_ dailyTimes: DailyPrayerTimes) -> [Prayer] {
        return [
            Prayer(name: "Fajr", startTime: dailyTimes.fajr.adhan, jamaaahTime: dailyTimes.fajr.jamaah),
            Prayer(name: "Sunrise", startTime: dailyTimes.sunrise, jamaaahTime: "-"),
            Prayer(name: "Dhuhr", startTime: dailyTimes.dhuhr.adhan, jamaaahTime: dailyTimes.dhuhr.jamaah),
            Prayer(name: "Asr", startTime: dailyTimes.asr.adhan, jamaaahTime: dailyTimes.asr.jamaah),
            Prayer(name: "Maghrib", startTime: dailyTimes.maghrib.adhan, jamaaahTime: dailyTimes.maghrib.jamaah),
            Prayer(name: "Isha", startTime: dailyTimes.isha.adhan, jamaaahTime: dailyTimes.isha.jamaah)
        ]
    }
    
    private func loadMockData() {
        let mockPrayers = [
            Prayer(name: "Fajr", startTime: "05:30", jamaaahTime: "05:45"),
            Prayer(name: "Sunrise", startTime: "07:25", jamaaahTime: "-"),
            Prayer(name: "Dhuhr", startTime: "12:05", jamaaahTime: "12:45"),
            Prayer(name: "Asr", startTime: "14:15", jamaaahTime: "14:30"),
            Prayer(name: "Maghrib", startTime: "16:30", jamaaahTime: "16:35"),
            Prayer(name: "Isha", startTime: "18:15", jamaaahTime: "18:30")
        ]
        
        self.prayers = mockPrayers
        self.isLoading = false
    }
}

// MARK: - SwiftUI Views
struct PrayerTimesView: View {
    @StateObject private var service = PrayerTimesService()
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            themeManager.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Date Navigation Header
                HStack {
                    // Home button
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "house.fill")
                            .font(.title3)
                            .foregroundColor(themeManager.primaryColor)
                            .frame(width: 40, height: 40)
                    }
                    
                    Button(action: {
                        service.goToPreviousDay()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(service.canGoBack ? themeManager.primaryColor : themeManager.textSecondary.opacity(0.3))
                            .frame(width: 44, height: 44)
                    }
                    .disabled(!service.canGoBack)
                    
                    Spacer()
                    
                    Text(service.currentDate)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Spacer()
                    
                    Button(action: {
                        service.goToNextDay()
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.title2)
                            .foregroundColor(service.canGoForward ? themeManager.primaryColor : themeManager.textSecondary.opacity(0.3))
                            .frame(width: 44, height: 44)
                    }
                    .disabled(!service.canGoForward)
                    
                    // Notification button
                    NavigationLink(destination: NotificationSettingsView()) {
                        Image(systemName: "bell")
                            .font(.title3)
                            .foregroundColor(themeManager.primaryColor)
                            .frame(width: 40, height: 40)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(themeManager.cardBackground)
                .shadow(color: themeManager.primaryColor.opacity(0.1), radius: 2, x: 0, y: 2)
                
                if service.isLoading {
                    ProgressView("Loading prayer times...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = service.errorMessage {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .foregroundColor(themeManager.textSecondary)
                            .padding()
                        Button("Retry") {
                            service.fetchPrayerTimes()
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Title
                            Text("Prayer Times")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(themeManager.textPrimary)
                                .padding(.top)
                            
                            // Jummah Section
                            VStack(spacing: 12) {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(themeManager.accentColor)
                                        .font(.title2)
                                    Text("Jummah Prayer")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(themeManager.textPrimary)
                                    Spacer()
                                }
                                
                                HStack {
                                    Text("Friday Jamaa'ah")
                                        .font(.subheadline)
                                        .foregroundColor(themeManager.textSecondary)
                                    Spacer()
                                    Text(service.jummahTime)
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(themeManager.accentColor)
                                }
                            }
                            .padding()
                            .background(themeManager.accentColor.opacity(0.15))
                            .cornerRadius(12)
                            .padding(.horizontal)
                            
                            PrayerTimesTable(prayers: service.prayers, jummahTime: service.jummahTime)
                                .environmentObject(themeManager)
                            
                            // Footer Info
                            VStack(spacing: 8) {
                                Text("🕌 Central Mosque Rochdale")
                                    .font(.footnote)
                                    .fontWeight(.medium)
                                    .foregroundColor(themeManager.primaryColor)
                                
                                Text("Prayer times are calculated for Rochdale, UK")
                                    .font(.caption)
                                    .foregroundColor(themeManager.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            service.fetchPrayerTimes()
        }
        .refreshable {
            service.fetchPrayerTimes()
        }
    }
}

struct PrayerTimesTable: View {
    let prayers: [Prayer]
    let jummahTime: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Prayer")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.cardBackground)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Start Time")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.cardBackground)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                Text("Jamaa'ah")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.cardBackground)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding()
            .background(themeManager.primaryColor)
            
            Divider()
            
            // Prayer rows
            ForEach(Array(prayers.enumerated()), id: \.element.id) { index, prayer in
                PrayerRowView(prayer: prayer, isEven: index % 2 == 0)
                    .environmentObject(themeManager)
                if prayer.id != prayers.last?.id {
                    Divider()
                        .background(themeManager.textSecondary.opacity(0.3))
                }
            }
        }
        .background(themeManager.cardBackground)
        .cornerRadius(12)
        .shadow(color: themeManager.primaryColor.opacity(0.2), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}

struct PrayerRowView: View {
    let prayer: Prayer
    let isEven: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    var prayerIcon: String {
        switch prayer.name {
        case "Fajr": return "sunrise"
        case "Sunrise": return "sun.and.horizon"
        case "Dhuhr": return "sun.max"
        case "Asr": return "sun.min"
        case "Maghrib": return "sunset"
        case "Isha": return "moon.stars"
        default: return "clock"
        }
    }
    
    var body: some View {
        HStack {
            HStack(spacing: 12) {
                Image(systemName: prayerIcon)
                    .foregroundColor(themeManager.primaryColor)
                    .font(.title3)
                    .frame(width: 20)
                
                Text(prayer.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(prayer.startTime)
                .font(.body)
                .foregroundColor(themeManager.textSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
            
            Text(prayer.jamaaahTime)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.accentColor)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .background(isEven ? themeManager.cardBackground : themeManager.backgroundColor.opacity(0.3))
    }
}

// MARK: - Preview
struct PrayerTimesView_Previews: PreviewProvider {
    static var previews: some View {
        PrayerTimesView()
            .environmentObject(ThemeManager())
    }
}