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

struct PrayerTimesResponse: Codable {
    let prayers: [Prayer]
}

// MARK: - Mock API Service
class PrayerTimesService: ObservableObject {
    @Published var prayers: [Prayer] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func fetchPrayerTimes() {
        isLoading = true
        errorMessage = nil
        
        // Simulate API delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.loadMockData()
        }
    }
    
    private func loadMockData() {
        let mockPrayers = [
            Prayer(name: "Fajr", startTime: "05:30", jamaaahTime: "05:45"),
            Prayer(name: "Dhuhr", startTime: "12:45", jamaaahTime: "13:00"),
            Prayer(name: "Asr", startTime: "16:15", jamaaahTime: "16:30"),
            Prayer(name: "Maghrib", startTime: "18:45", jamaaahTime: "18:50"),
            Prayer(name: "Isha", startTime: "20:30", jamaaahTime: "20:45")
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
                        Button("Retry") {
                            service.fetchPrayerTimes()
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    PrayerTimesTable(prayers: service.prayers)
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