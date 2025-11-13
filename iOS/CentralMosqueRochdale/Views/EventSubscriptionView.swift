import SwiftUI

// MARK: - Event Subscription Settings View
struct EventSubscriptionView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @AppStorage("eventsNotificationsEnabled") private var isEnabled = true
    @AppStorage("eventsNotifyMinutes") private var notifyBeforeMinutes = 30
    @State private var subscribedCategories: Set<EventCategory> = Set(EventCategory.allCases)
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            themeManager.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header
                HStack {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.primaryColor)
                    
                    Spacer()
                    
                    Text("Event Subscriptions")
                        .font(.headline)
                        .foregroundColor(themeManager.textPrimary)
                    
                    Spacer()
                    
                    // Placeholder for symmetry
                    Text("Close")
                        .foregroundColor(.clear)
                }
                .padding()
                .background(themeManager.cardBackground)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
                
                Form {
                    Section(header: Text("Event Notifications")
                        .foregroundColor(themeManager.textSecondary)) {
                        Toggle("Enable Event Notifications", isOn: $isEnabled)
                            .tint(themeManager.primaryColor)
                    }
                    
                    if isEnabled {
                        Section(header: Text("Categories")
                            .foregroundColor(themeManager.textSecondary)) {
                            ForEach(EventCategory.allCases, id: \.self) { category in
                                HStack {
                                    Image(systemName: category.icon)
                                        .foregroundColor(themeManager.primaryColor)
                                        .frame(width: 24)
                                    
                                    VStack(alignment: .leading) {
                                        Text(category.displayName)
                                            .font(.body)
                                            .foregroundColor(themeManager.textPrimary)
                                        Text(categoryDescription(category))
                                            .font(.caption)
                                            .foregroundColor(themeManager.textSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: Binding(
                                        get: { subscribedCategories.contains(category) },
                                        set: { isEnabled in
                                            if isEnabled {
                                                subscribedCategories.insert(category)
                                            } else {
                                                subscribedCategories.remove(category)
                                            }
                                        }
                                    ))
                                    .tint(themeManager.primaryColor)
                                }
                            }
                        }
                        
                        Section(header: Text("Notification Timing")
                            .foregroundColor(themeManager.textSecondary)) {
                            Picker("Notify me before", selection: $notifyBeforeMinutes) {
                                Text("15 minutes").tag(15)
                                Text("30 minutes").tag(30)
                                Text("1 hour").tag(60)
                                Text("2 hours").tag(120)
                                Text("1 day").tag(1440)
                            }
                            .tint(themeManager.primaryColor)
                        }
                    }
                    
                    Section(footer: footerText) {
                        EmptyView()
                    }
                }
                .scrollContentBackground(.hidden)
                .background(themeManager.backgroundColor)
            }
        }
    }
    
    private var footerText: Text {
        Text("You will receive local notifications for events in selected categories. Notifications will be sent \(formatNotificationTime(notifyBeforeMinutes)) before each event starts.")
            .foregroundColor(themeManager.textSecondary)
    }
    
    private func categoryDescription(_ category: EventCategory) -> String {
        switch category {
        case .lecture: return "Islamic talks and educational sessions"
        case .education: return "Classes and educational programs"
        case .religious: return "Special prayers and religious observances"
        case .community: return "Community gatherings and social events"
        case .youth: return "Youth activities and programs"
        }
    }
    
    private func formatNotificationTime(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) minutes"
        } else if minutes < 1440 {
            let hours = minutes / 60
            return "\(hours) hour\(hours > 1 ? "s" : "")"
        } else {
            let days = minutes / 1440
            return "\(days) day\(days > 1 ? "s" : "")"
        }
    }
}

// MARK: - Preview
struct EventSubscriptionView_Previews: PreviewProvider {
    static var previews: some View {
        EventSubscriptionView()
            .environmentObject(ThemeManager())
    }
}
