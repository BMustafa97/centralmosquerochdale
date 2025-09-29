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