import SwiftUI

struct ExternalLinksView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ZStack {
            themeManager.backgroundColor.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "link.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(themeManager.primaryColor)
                        
                        Text("External Links")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.textPrimary)
                        
                        Text("Connect with us on various platforms")
                            .font(.subheadline)
                            .foregroundColor(themeManager.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    // Links Section
                    VStack(spacing: 16) {
                        // MyMasjid Portal - Live Stream
                        ExternalLinkCard(
                            icon: "play.tv.fill",
                            title: "MyMasjid Portal",
                            description: "Watch live streams and access mosque services",
                            url: "https://mymasjid.uk/live/cmrochdale",
                            accentColor: themeManager.accentColor
                        )
                        
                        // YouTube Channel
                        ExternalLinkCard(
                            icon: "play.rectangle.fill",
                            title: "YouTube Channel",
                            description: "Watch lectures, events, and educational content",
                            url: "https://youtube.com/centralmosquerochdale",
                            accentColor: Color.red
                        )
                        
                        // WhatsApp Community
                        ExternalLinkCard(
                            icon: "bubble.left.and.bubble.right.fill",
                            title: "WhatsApp Community",
                            description: "Join our community for updates and discussions",
                            url: "https://whatsapp.com/channel/0029VaGVe0k7j6g4FycciF2N",
                            accentColor: Color.green
                        )
                        
                        // Website
                        ExternalLinkCard(
                            icon: "globe",
                            title: "Website",
                            description: "Visit our official website",
                            url: "https://centralmosquerochdale.com",
                            accentColor: themeManager.primaryColor
                        )
                        
                        // Social Media Section
                        SocialMediaSection()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("Connect")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Link Opened", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
}

struct ExternalLinkCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let icon: String
    let title: String
    let description: String
    let url: String
    let accentColor: Color
    
    var body: some View {
        Button {
            openURL(url)
        } label: {
            HStack(spacing: 16) {
                // Icon Circle
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.system(size: 26))
                        .foregroundColor(accentColor)
                }
                
                // Text Content
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.textPrimary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(themeManager.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Arrow Indicator
                Image(systemName: "arrow.up.right.circle.fill")
                    .font(.title3)
                    .foregroundColor(accentColor.opacity(0.7))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.cardBackground)
                    .shadow(
                        color: themeManager.isDarkMode ? Color.clear : Color.black.opacity(0.08),
                        radius: 8,
                        x: 0,
                        y: 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}

struct SocialMediaSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Follow Us")
                .font(.headline)
                .foregroundColor(themeManager.textPrimary)
                .padding(.horizontal, 4)
            
            HStack(spacing: 12) {
                // Facebook
                SocialMediaButton(
                    icon: "f.circle.fill",
                    name: "Facebook",
                    url: "https://facebook.com/centralmosquerochdale",
                    color: Color.blue
                )
                
                // Instagram
                SocialMediaButton(
                    icon: "camera.circle.fill",
                    name: "Instagram",
                    url: "https://instagram.com/centralmosquerochdale",
                    color: Color.purple.opacity(0.8)
                )
                
                // Twitter/X
                SocialMediaButton(
                    icon: "xmark.circle.fill",
                    name: "Twitter",
                    url: "https://twitter.com/CMRochdale",
                    color: Color.black
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.cardBackground)
                .shadow(
                    color: themeManager.isDarkMode ? Color.clear : Color.black.opacity(0.08),
                    radius: 8,
                    x: 0,
                    y: 2
                )
        )
    }
}

struct SocialMediaButton: View {
    @EnvironmentObject var themeManager: ThemeManager
    let icon: String
    let name: String
    let url: String
    let color: Color
    
    var body: some View {
        Button {
            openURL(url)
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(color)
                }
                
                Text(name)
                    .font(.caption2)
                    .foregroundColor(themeManager.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    NavigationView {
        ExternalLinksView()
            .environmentObject(ThemeManager())
    }
}
