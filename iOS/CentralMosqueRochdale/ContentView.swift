import SwiftUI

// Temporary placeholder views until we fix the imports
struct PrayerTimesView: View {
    var body: some View {
        Text("Prayer Times - Coming Soon!")
            .navigationTitle("Prayer Times")
    }
}

struct QiblaCompassView: View {
    var body: some View {
        Text("Qibla Compass - Coming Soon!")
            .navigationTitle("Qibla")
    }
}

struct MosqueEventsView: View {
    var body: some View {
        Text("Mosque Events - Coming Soon!")
            .navigationTitle("Events")
    }
}

struct NotificationSettingsView: View {
    var body: some View {
        Text("Notification Settings - Coming Soon!")
            .navigationTitle("Notifications")
    }
}

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "house.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("🕌 Central Mosque Rochdale")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
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
            .navigationTitle("Mosque App")
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