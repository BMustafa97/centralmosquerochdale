import SwiftUI

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
                    FeatureRow(icon: "clock", title: "Prayer Times", description: "View daily prayer schedule")
                    FeatureRow(icon: "safari", title: "Qibla Compass", description: "Find prayer direction")
                    FeatureRow(icon: "calendar", title: "Events", description: "Mosque events & announcements")
                    FeatureRow(icon: "bell", title: "Notifications", description: "Prayer reminders")
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
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

#Preview {
    ContentView()
}