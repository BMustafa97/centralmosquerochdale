import SwiftUI

struct ContentView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                ScrollView {
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
                        
                        // Main Services Grid
                        VStack(spacing: 16) {
                            NavigationLink(destination: PrayerTimesView().environmentObject(themeManager)) {
                                GlassFeatureCard(
                                    icon: "clock.fill",
                                    title: "Prayer Times",
                                    description: "View daily prayer schedule",
                                    gradient: [themeManager.primaryColor, themeManager.primaryColor.opacity(0.7)]
                                )
                                .environmentObject(themeManager)
                            }
                            .buttonStyle(GlassButtonStyle())
                            
                            NavigationLink(destination: QiblaCompassView().environmentObject(themeManager)) {
                                GlassFeatureCard(
                                    icon: "safari.fill",
                                    title: "Qibla Compass",
                                    description: "Find prayer direction",
                                    gradient: [themeManager.accentColor, themeManager.accentColor.opacity(0.7)]
                                )
                                .environmentObject(themeManager)
                            }
                            .buttonStyle(GlassButtonStyle())
                            
                            NavigationLink(destination: MosqueEventsView().environmentObject(themeManager)) {
                                GlassFeatureCard(
                                    icon: "calendar.circle.fill",
                                    title: "Events",
                                    description: "Mosque events & announcements",
                                    gradient: [themeManager.secondaryColor, themeManager.secondaryColor.opacity(0.7)]
                                )
                                .environmentObject(themeManager)
                            }
                            .buttonStyle(GlassButtonStyle())
                            
                            NavigationLink(destination: DonationView().environmentObject(themeManager)) {
                                GlassFeatureCard(
                                    icon: "hands.sparkles.fill",
                                    title: "Donate",
                                    description: "Support your mosque",
                                    gradient: [Color.green, Color.green.opacity(0.7)]
                                )
                                .environmentObject(themeManager)
                            }
                            .buttonStyle(GlassButtonStyle())
                            
                            NavigationLink(destination: ExternalLinksView().environmentObject(themeManager)) {
                                GlassFeatureCard(
                                    icon: "link.circle.fill",
                                    title: "Connect",
                                    description: "YouTube, WhatsApp & Live Stream",
                                    gradient: [Color.blue, Color.blue.opacity(0.7)]
                                )
                                .environmentObject(themeManager)
                            }
                            .buttonStyle(GlassButtonStyle())
                            
                            NavigationLink(destination: SettingsView().environmentObject(themeManager)) {
                                GlassFeatureCard(
                                    icon: "gearshape.fill",
                                    title: "Settings",
                                    description: "Notifications & Preferences",
                                    gradient: [Color.gray.opacity(0.8), Color.gray.opacity(0.5)]
                                )
                                .environmentObject(themeManager)
                            }
                            .buttonStyle(GlassButtonStyle())
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 20)
                    }
                }
            }
        }
    }
}

// Glass Morphism Card Component
struct GlassFeatureCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let icon: String
    let title: String
    let description: String
    let gradient: [Color]
    
    var body: some View {
        HStack(spacing: 20) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }
            
            // Text Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.textPrimary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(themeManager.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(gradient[0].opacity(0.8))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(themeManager.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    gradient[0].opacity(0.3),
                                    gradient[1].opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: themeManager.isDarkMode ? Color.clear : gradient[0].opacity(0.15),
                    radius: 12,
                    x: 0,
                    y: 4
                )
        )
    }
}

// Glass Button Style with Press Effect
struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        configuration.isPressed ?
                            Color.white.opacity(0.2) :
                            Color.clear
                    )
                    .allowsHitTesting(false)
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
        .environmentObject(ThemeManager())
}
