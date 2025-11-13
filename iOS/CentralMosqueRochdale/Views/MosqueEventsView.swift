import SwiftUI

// MARK: - Event Models
struct MosqueEvent: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let category: String
    let dayOfWeek: String
    let time: String
    let recurrence: String
    let location: String
    let organizer: String
    let isImportant: Bool
    let startDate: String
    let endDate: String
    
    var categoryEnum: EventCategory {
        EventCategory(rawValue: category) ?? .community
    }
    
    var displayTime: String {
        "\(dayOfWeek)s \(time)"
    }
    
    var recurrenceDisplay: String {
        switch recurrence {
        case "weekly": return "Every \(dayOfWeek)"
        case "biweekly": return "Every 2 weeks on \(dayOfWeek)"
        default: return dayOfWeek
        }
    }
}

struct EventsData: Codable {
    let events: [MosqueEvent]
}

enum EventCategory: String, CaseIterable, Codable {
    case lecture = "lecture"
    case education = "education"
    case religious = "religious"
    case community = "community"
    case youth = "youth"
    
    var displayName: String {
        switch self {
        case .lecture: return "Islamic Lectures"
        case .education: return "Educational"
        case .religious: return "Religious"
        case .community: return "Community Events"
        case .youth: return "Youth Programs"
        }
    }
    
    var icon: String {
        switch self {
        case .lecture: return "book.fill"
        case .education: return "graduationcap.fill"
        case .religious: return "moon.fill"
        case .community: return "person.3.fill"
        case .youth: return "figure.run"
        }
    }
}

// MARK: - Event Service
class EventService: ObservableObject {
    @Published var events: [MosqueEvent] = []
    @Published var errorMessage: String?
    
    func loadEvents() {
        guard let url = Bundle.main.url(forResource: "MosqueEvents2025", withExtension: "json") else {
            errorMessage = "Could not find MosqueEvents2025.json"
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let eventsData = try decoder.decode(EventsData.self, from: data)
            self.events = eventsData.events
            self.errorMessage = nil
        } catch {
            errorMessage = "Failed to load events: \(error.localizedDescription)"
        }
    }
}

// MARK: - Events View
struct MosqueEventsView: View {
    @StateObject private var eventService = EventService()
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: EventCategory?
    @State private var showingSubscriptionSettings = false
    
    private var filteredEvents: [MosqueEvent] {
        if let category = selectedCategory {
            return eventService.events.filter { $0.categoryEnum == category }
        }
        return eventService.events
    }
    
    var body: some View {
        ZStack {
            themeManager.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "house.fill")
                            .font(.title3)
                            .foregroundColor(themeManager.primaryColor)
                    }
                    
                    Spacer()
                    
                    Text("Mosque Events")
                        .font(.headline)
                        .foregroundColor(themeManager.textPrimary)
                    
                    Spacer()
                    
                    Button(action: { showingSubscriptionSettings = true }) {
                        Image(systemName: "bell.badge")
                            .font(.title3)
                            .foregroundColor(themeManager.primaryColor)
                    }
                }
                .padding()
                .background(themeManager.cardBackground)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
                
                if let errorMessage = eventService.errorMessage {
                    MosqueEventsErrorView(
                        message: errorMessage,
                        themeManager: themeManager,
                        onRetry: { eventService.loadEvents() }
                    )
                } else {
                    EventsContent(
                        events: filteredEvents,
                        selectedCategory: $selectedCategory,
                        themeManager: themeManager
                    )
                }
            }
        }
        .sheet(isPresented: $showingSubscriptionSettings) {
            EventSubscriptionView()
        }
        .onAppear {
            eventService.loadEvents()
        }
    }
}

struct EventsContent: View {
    let events: [MosqueEvent]
    @Binding var selectedCategory: EventCategory?
    @ObservedObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Category Filter
            CategoryFilterView(
                selectedCategory: $selectedCategory,
                themeManager: themeManager
            )
            
            // Events List
            if events.isEmpty {
                EmptyEventsView(themeManager: themeManager)
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(events) { event in
                            EventCardView(
                                event: event,
                                themeManager: themeManager
                            )
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

struct CategoryFilterView: View {
    @Binding var selectedCategory: EventCategory?
    @ObservedObject var themeManager: ThemeManager
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterChip(
                    title: "All Events",
                    isSelected: selectedCategory == nil,
                    themeManager: themeManager,
                    action: { selectedCategory = nil }
                )
                
                ForEach(EventCategory.allCases, id: \.self) { category in
                    FilterChip(
                        title: category.displayName,
                        isSelected: selectedCategory == category,
                        themeManager: themeManager,
                        action: { 
                            selectedCategory = selectedCategory == category ? nil : category 
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(themeManager.cardBackground)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    @ObservedObject var themeManager: ThemeManager
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : themeManager.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? themeManager.primaryColor : Color(white: themeManager.colorScheme == .dark ? 0.2 : 0.95))
                )
        }
    }
}

struct EventCardView: View {
    let event: MosqueEvent
    @ObservedObject var themeManager: ThemeManager
    @State private var showingEventDetail = false
    
    var body: some View {
        Button(action: { showingEventDetail = true }) {
            VStack(alignment: .leading, spacing: 12) {
                // Event Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.title)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.textPrimary)
                            .multilineTextAlignment(.leading)
                        
                        Text(event.categoryEnum.displayName)
                            .font(.caption)
                            .foregroundColor(themeManager.accentColor)
                    }
                    
                    Spacer()
                    
                    if event.isImportant {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(themeManager.secondaryColor)
                            .font(.title3)
                    }
                    
                    Image(systemName: event.categoryEnum.icon)
                        .foregroundColor(themeManager.primaryColor)
                        .font(.title2)
                }
                
                // Event Details
                Text(event.description)
                    .font(.body)
                    .foregroundColor(themeManager.textSecondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                Divider()
                    .background(themeManager.textSecondary.opacity(0.3))
                
                // Schedule and Location Info
                VStack(spacing: 8) {
                    HStack {
                        Label(event.recurrenceDisplay, systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(themeManager.textSecondary)
                        Spacer()
                    }
                    
                    HStack {
                        Label(event.time, systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(themeManager.textSecondary)
                        Spacer()
                    }
                    
                    HStack {
                        Label(event.location, systemImage: "location.fill")
                            .font(.caption)
                            .foregroundColor(themeManager.textSecondary)
                        Spacer()
                    }
                    
                    HStack {
                        Label(event.organizer, systemImage: "person.fill")
                            .font(.caption)
                            .foregroundColor(themeManager.textSecondary)
                        Spacer()
                    }
                }
            }
            .padding()
            .background(themeManager.cardBackground)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .sheet(isPresented: $showingEventDetail) {
            EventDetailView(event: event, themeManager: themeManager)
        }
    }
}

struct EmptyEventsView: View {
    @ObservedObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(themeManager.textSecondary)
            
            Text("No Events Found")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.textPrimary)
            
            Text("Check back later for upcoming mosque events and programs.")
                .font(.body)
                .foregroundColor(themeManager.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct MosqueEventsErrorView: View {
    let message: String
    @ObservedObject var themeManager: ThemeManager
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(themeManager.accentColor)
            
            Text("Error")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.textPrimary)
            
            Text(message)
                .font(.body)
                .foregroundColor(themeManager.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button("Retry", action: onRetry)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(themeManager.primaryColor)
                .cornerRadius(8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Event Detail View
struct EventDetailView: View {
    let event: MosqueEvent
    @ObservedObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            themeManager.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    Text("Event Details")
                        .font(.headline)
                        .foregroundColor(themeManager.textPrimary)
                    Spacer()
                }
                .padding()
                .background(themeManager.cardBackground)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Event Header
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(event.title)
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(themeManager.textPrimary)
                                
                                Spacer()
                                
                                if event.isImportant {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(themeManager.secondaryColor)
                                        .font(.title)
                                }
                            }
                            
                            HStack {
                                Image(systemName: event.categoryEnum.icon)
                                    .foregroundColor(themeManager.primaryColor)
                                Text(event.categoryEnum.displayName)
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.accentColor)
                            }
                        }
                        
                        Divider()
                            .background(themeManager.textSecondary.opacity(0.3))
                        
                        // Event Details
                        VStack(alignment: .leading, spacing: 16) {
                            DetailRow(
                                icon: "calendar.badge.clock",
                                title: "Schedule",
                                value: event.recurrenceDisplay,
                                themeManager: themeManager
                            )
                            
                            DetailRow(
                                icon: "clock",
                                title: "Time",
                                value: event.time,
                                themeManager: themeManager
                            )
                            
                            DetailRow(
                                icon: "location",
                                title: "Location",
                                value: event.location,
                                themeManager: themeManager
                            )
                            
                            DetailRow(
                                icon: "person",
                                title: "Organizer",
                                value: event.organizer,
                                themeManager: themeManager
                            )
                            
                            DetailRow(
                                icon: "calendar",
                                title: "Period",
                                value: "\(event.startDate) to \(event.endDate)",
                                themeManager: themeManager
                            )
                        }
                        
                        Divider()
                            .background(themeManager.textSecondary.opacity(0.3))
                        
                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)
                                .foregroundColor(themeManager.textPrimary)
                            Text(event.description)
                                .font(.body)
                                .foregroundColor(themeManager.textSecondary)
                        }
                        
                        Spacer(minLength: 20)
                    }
                    .padding()
                }
                
                // Close Button
                Button(action: { dismiss() }) {
                    Text("Close")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(themeManager.primaryColor)
                        .cornerRadius(12)
                }
                .padding()
            }
        }
    }
}

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    @ObservedObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(themeManager.primaryColor)
                .frame(width: 20, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(themeManager.textSecondary)
                Text(value)
                    .font(.body)
                    .foregroundColor(themeManager.textPrimary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview
struct MosqueEventsView_Previews: PreviewProvider {
    static var previews: some View {
        MosqueEventsView()
    }
}