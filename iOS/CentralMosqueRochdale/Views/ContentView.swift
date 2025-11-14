import SwiftUI

struct ContentView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Header with branding
                    VStack(spacing: 12) {
                        Image("MosqueLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .cornerRadius(16)
                            .shadow(color: themeManager.primaryColor.opacity(0.3), radius: 8, x: 0, y: 4)
                        
                        Text("Central Mosque Rochdale")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundColor(themeManager.primaryColor)
                            .lineSpacing(4)
                        
                        Text("Prayer • Community • Guidance")
                            .font(.subheadline)
                            .foregroundColor(themeManager.textSecondary)
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 16) {
                        NavigationLink(destination: PrayerTimesView().environmentObject(themeManager)) {
                            FeatureRow(icon: "clock", title: "Prayer Times", description: "View daily prayer schedule")
                                .environmentObject(themeManager)
                        }
                        .buttonStyle(PlainButtonStyle())

                        NavigationLink(destination: MosqueEventsView().environmentObject(themeManager)) {
                            FeatureRow(icon: "calendar", title: "Events", description: "Mosque events & announcements")
                                .environmentObject(themeManager)
                        }
                        .buttonStyle(PlainButtonStyle())

                        NavigationLink(destination: DonationView().environmentObject(themeManager)) {
                            FeatureRow(icon: "hands.sparkles.fill", title: "Donate", description: "Support your mosque")
                                .environmentObject(themeManager)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        NavigationLink(destination: QiblaCompassView().environmentObject(themeManager)) {
                            FeatureRow(icon: "safari", title: "Qibla Compass", description: "Find prayer direction")
                                .environmentObject(themeManager)
                        }
                        .buttonStyle(PlainButtonStyle())

                        NavigationLink(destination: ExternalLinksView().environmentObject(themeManager)) {
                            FeatureRow(icon: "link.circle", title: "Connect", description: "YouTube, WhatsApp & Live Stream")
                                .environmentObject(themeManager)
                        }
                        .buttonStyle(PlainButtonStyle())    
                        
                        NavigationLink(destination: NotificationSettingsView().environmentObject(themeManager)) {
                            FeatureRow(icon: "bell", title: "Notifications", description: "Prayer reminders")
                                .environmentObject(themeManager)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        NavigationLink(destination: SettingsView()) {
                            FeatureRow(icon: "gearshape.fill", title: "Settings", description: "App preferences & theme")
                                .environmentObject(themeManager)
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
}

struct FeatureRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(themeManager.primaryColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(themeManager.textPrimary)
                Text(description)
                    .font(.caption)
                    .foregroundColor(themeManager.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(themeManager.accentColor)
        }
        .padding()
        .background(themeManager.cardBackground)
        .cornerRadius(12)
        .shadow(color: themeManager.primaryColor.opacity(0.1), radius: 3, x: 0, y: 2)
    }
}

#Preview {
    ContentView()
}
