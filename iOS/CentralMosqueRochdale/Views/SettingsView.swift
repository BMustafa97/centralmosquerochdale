import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        List {
            Section(header: Text("Appearance")) {
                HStack {
                    Image(systemName: themeManager.isDarkMode ? "moon.fill" : "sun.max.fill")
                        .foregroundColor(themeManager.isDarkMode ? .purple : .orange)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dark Mode")
                            .font(.headline)
                        Text(themeManager.isDarkMode ? "Enabled" : "Disabled")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $themeManager.isDarkMode)
                        .labelsHidden()
                }
                .padding(.vertical, 8)
            }
            
            Section(header: Text("About")) {
                HStack {
                    Text("App Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Mosque")
                    Spacer()
                    Text("Central Mosque Rochdale")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        SettingsView()
            .environmentObject(ThemeManager())
    }
}
