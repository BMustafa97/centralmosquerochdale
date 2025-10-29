import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            themeManager.backgroundColor.ignoresSafeArea()
            
            List {
                Section(header: Text("Appearance")) {
                    HStack {
                        Image(systemName: themeManager.isDarkMode ? "moon.fill" : "sun.max.fill")
                            .foregroundColor(themeManager.isDarkMode ? themeManager.secondaryColor : themeManager.primaryColor)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Dark Mode")
                                .font(.headline)
                                .foregroundColor(themeManager.textPrimary)
                            Text(themeManager.isDarkMode ? "Enabled" : "Disabled")
                                .font(.caption)
                                .foregroundColor(themeManager.textSecondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $themeManager.isDarkMode)
                            .labelsHidden()
                            .tint(themeManager.primaryColor)
                    }
                    .padding(.vertical, 8)
                    .listRowBackground(themeManager.cardBackground)
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("App Version")
                            .foregroundColor(themeManager.textPrimary)
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(themeManager.textSecondary)
                    }
                    .listRowBackground(themeManager.cardBackground)
                    
                    HStack {
                        Text("Mosque")
                            .foregroundColor(themeManager.textPrimary)
                        Spacer()
                        Text("Central Mosque Rochdale")
                            .foregroundColor(themeManager.primaryColor)
                            .multilineTextAlignment(.trailing)
                    }
                    .listRowBackground(themeManager.cardBackground)
                }
            }
            .scrollContentBackground(.hidden)
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
