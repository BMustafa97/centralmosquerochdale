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
    
    private var yearlyData: YearlyPrayerTimes?
    
    func fetchPrayerTimes() {
        isLoading = true
        errorMessage = nil
        
        // Get today's date in YYYY-MM-DD format
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayString = dateFormatter.string(from: Date())
        
        // Format for display
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "EEEE, d MMMM yyyy"
        currentDate = displayFormatter.string(from: Date())
        
        // Load JSON file
        loadPrayerTimesFromJSON(for: todayString)
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
    
    var body: some View {
        NavigationView {
            VStack {
                if service.isLoading {
                    ProgressView("Loading prayer times...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = service.errorMessage {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .foregroundColor(.secondary)
                            .padding()
                        Button("Retry") {
                            service.fetchPrayerTimes()
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 0) {
                        // Date Header
                        if !service.currentDate.isEmpty {
                            Text(service.currentDate)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                                .padding(.bottom, 4)
                        }
                        
                        PrayerTimesTable(prayers: service.prayers, jummahTime: service.jummahTime)
                    }
                }
            }
            .navigationTitle("Prayer Times")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: NotificationSettingsView()) {
                        Image(systemName: "bell")
                            .font(.title3)
                    }
                }
            }
            .onAppear {
                service.fetchPrayerTimes()
            }
            .refreshable {
                service.fetchPrayerTimes()
            }
        }
    }
}

struct PrayerTimesTable: View {
    let prayers: [Prayer]
    let jummahTime: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Prayer")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Start Time")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                Text("Jamaa'ah")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding()
            .background(Color(UIColor.systemGray5))
            
            Divider()
            
            // Prayer rows
            ForEach(prayers) { prayer in
                PrayerRowView(prayer: prayer)
                if prayer.id != prayers.last?.id {
                    Divider()
                }
            }
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding()
    }
}

struct PrayerRowView: View {
    let prayer: Prayer
    
    var body: some View {
        HStack {
            Text(prayer.name)
                .font(.body)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(prayer.startTime)
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
            
            Text(prayer.jamaaahTime)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
    }
}

// MARK: - Preview
struct PrayerTimesView_Previews: PreviewProvider {
    static var previews: some View {
        PrayerTimesView()
    }
}