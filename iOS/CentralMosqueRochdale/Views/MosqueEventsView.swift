import SwiftUI
import Combine

// MARK: - Event Models
struct MosqueEvent: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let startDate: Date
    let endDate: Date?
    let category: EventCategory
    let location: String
    let organizer: String
    let isImportant: Bool
    let imageURL: String?
    let maxAttendees: Int?
    let currentAttendees: Int
    let requiresRegistration: Bool
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, startDate, endDate, category
        case location, organizer, isImportant, imageURL, maxAttendees
        case currentAttendees, requiresRegistration, createdAt, updatedAt
    }
}

enum EventCategory: String, CaseIterable, Codable {
    case lecture = "lecture"
    case fundraising = "fundraising"
    case community = "community"
    case education = "education"
    case religious = "religious"
    case youth = "youth"
    case charity = "charity"
    case announcement = "announcement"
    
    var displayName: String {
        switch self {
        case .lecture: return "Islamic Lectures"
        case .fundraising: return "Fundraising"
        case .community: return "Community Events"
        case .education: return "Educational"
        case .religious: return "Religious"
        case .youth: return "Youth Programs"
        case .charity: return "Charity Work"
        case .announcement: return "Announcements"
        }
    }
    
    var icon: String {
        switch self {
        case .lecture: return "book.fill"
        case .fundraising: return "dollarsign.circle.fill"
        case .community: return "person.3.fill"
        case .education: return "graduationcap.fill"
        case .religious: return "moon.fill"
        case .youth: return "figure.run"
        case .charity: return "heart.fill"
        case .announcement: return "megaphone.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .lecture: return .blue
        case .fundraising: return .green
        case .community: return .orange
        case .education: return .purple
        case .religious: return .indigo
        case .youth: return .pink
        case .charity: return .red
        case .announcement: return .yellow
        }
    }
}

struct EventSubscription: Codable {
    let userId: String
    var subscribedCategories: Set<EventCategory>
    var notifyBeforeMinutes: Int
    var isEnabled: Bool
    var lastUpdated: Date
}

struct CreateEventRequest: Codable {
    let title: String
    let description: String
    let startDate: Date
    let endDate: Date?
    let category: EventCategory
    let location: String
    let organizer: String
    let isImportant: Bool
    let imageURL: String?
    let maxAttendees: Int?
    let requiresRegistration: Bool
}

// MARK: - Event API Service
class EventAPIService: ObservableObject {
    private let baseURL = "https://api.centralmosquerochdale.org"
    private let session = URLSession.shared
    
    @Published var events: [MosqueEvent] = []
    @Published var userSubscriptions: EventSubscription?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Event Management
    func fetchEvents() async {
        await MainActor.run { isLoading = true }
        
        do {
            guard let url = URL(string: "\(baseURL)/api/events") else {
                throw APIError.invalidURL
            }
            
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw APIError.serverError
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let fetchedEvents = try decoder.decode([MosqueEvent].self, from: data)
            
            await MainActor.run {
                self.events = fetchedEvents.sorted { $0.startDate < $1.startDate }
                self.isLoading = false
                self.errorMessage = nil
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Failed to fetch events: \(error.localizedDescription)"
            }
        }
    }
    
    func createEvent(_ request: CreateEventRequest, adminToken: String) async -> Result<MosqueEvent, Error> {
        do {
            guard let url = URL(string: "\(baseURL)/api/admin/events") else {
                return .failure(APIError.invalidURL)
            }
            
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("Bearer \(adminToken)", forHTTPHeaderField: "Authorization")
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            urlRequest.httpBody = try encoder.encode(request)
            
            let (data, response) = try await session.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 201 else {
                return .failure(APIError.serverError)
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let newEvent = try decoder.decode(MosqueEvent.self, from: data)
            
            await MainActor.run {
                self.events.append(newEvent)
                self.events.sort { $0.startDate < $1.startDate }
            }
            
            return .success(newEvent)
        } catch {
            return .failure(error)
        }
    }
    
    // MARK: - Subscription Management
    func fetchUserSubscriptions(userId: String) async {
        do {
            guard let url = URL(string: "\(baseURL)/api/users/\(userId)/subscriptions") else {
                throw APIError.invalidURL
            }
            
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw APIError.serverError
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let subscriptions = try decoder.decode(EventSubscription.self, from: data)
            
            await MainActor.run {
                self.userSubscriptions = subscriptions
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to fetch subscriptions: \(error.localizedDescription)"
            }
        }
    }
    
    func updateSubscriptions(_ subscription: EventSubscription, userId: String) async -> Bool {
        do {
            guard let url = URL(string: "\(baseURL)/api/users/\(userId)/subscriptions") else {
                return false
            }
            
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "PUT"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            urlRequest.httpBody = try encoder.encode(subscription)
            
            let (_, response) = try await session.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return false
            }
            
            await MainActor.run {
                self.userSubscriptions = subscription
            }
            
            return true
        } catch {
            return false
        }
    }
    
    func registerForEvent(eventId: String, userId: String) async -> Bool {
        do {
            guard let url = URL(string: "\(baseURL)/api/events/\(eventId)/register") else {
                return false
            }
            
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let requestBody = ["userId": userId]
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (_, response) = try await session.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return false
            }
            
            // Update local event data
            if let eventIndex = events.firstIndex(where: { $0.id == eventId }) {
                await MainActor.run {
                    self.events[eventIndex] = MosqueEvent(
                        id: self.events[eventIndex].id,
                        title: self.events[eventIndex].title,
                        description: self.events[eventIndex].description,
                        startDate: self.events[eventIndex].startDate,
                        endDate: self.events[eventIndex].endDate,
                        category: self.events[eventIndex].category,
                        location: self.events[eventIndex].location,
                        organizer: self.events[eventIndex].organizer,
                        isImportant: self.events[eventIndex].isImportant,
                        imageURL: self.events[eventIndex].imageURL,
                        maxAttendees: self.events[eventIndex].maxAttendees,
                        currentAttendees: self.events[eventIndex].currentAttendees + 1,
                        requiresRegistration: self.events[eventIndex].requiresRegistration,
                        createdAt: self.events[eventIndex].createdAt,
                        updatedAt: Date()
                    )
                }
            }
            
            return true
        } catch {
            return false
        }
    }
}

enum APIError: Error {
    case invalidURL
    case serverError
    case decodingError
    case networkError
    
    var localizedDescription: String {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .serverError: return "Server error occurred"
        case .decodingError: return "Failed to decode response"
        case .networkError: return "Network connection error"
        }
    }
}

// MARK: - Events View
struct MosqueEventsView: View {
    @StateObject private var eventService = EventAPIService()
    @State private var selectedCategory: EventCategory?
    @State private var showingSubscriptionSettings = false
    @State private var showingCreateEvent = false
    
    private var filteredEvents: [MosqueEvent] {
        if let category = selectedCategory {
            return eventService.events.filter { $0.category == category }
        }
        return eventService.events
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if eventService.isLoading {
                    ProgressView("Loading events...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = eventService.errorMessage {
                    MosqueEventsErrorView(message: errorMessage) {
                        Task { await eventService.fetchEvents() }
                    }
                } else {
                    EventsContent(
                        events: filteredEvents,
                        selectedCategory: $selectedCategory,
                        eventService: eventService
                    )
                }
            }
            .navigationTitle("Mosque Events")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        showingSubscriptionSettings = true
                    } label: {
                        Image(systemName: "bell.badge")
                    }
                    
                    Button {
                        showingCreateEvent = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingSubscriptionSettings) {
                EventSubscriptionView(eventService: eventService)
            }
            .sheet(isPresented: $showingCreateEvent) {
                CreateEventView(eventService: eventService)
            }
            .refreshable {
                await eventService.fetchEvents()
            }
            .task {
                await eventService.fetchEvents()
            }
        }
    }
}

struct EventsContent: View {
    let events: [MosqueEvent]
    @Binding var selectedCategory: EventCategory?
    @ObservedObject var eventService: EventAPIService
    
    var body: some View {
        VStack {
            // Category Filter
            CategoryFilterView(selectedCategory: $selectedCategory)
            
            // Events List
            if events.isEmpty {
                EmptyEventsView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(events) { event in
                            EventCardView(event: event, eventService: eventService)
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
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterChip(
                    title: "All Events",
                    isSelected: selectedCategory == nil,
                    action: { selectedCategory = nil }
                )
                
                ForEach(EventCategory.allCases, id: \.self) { category in
                    FilterChip(
                        title: category.displayName,
                        isSelected: selectedCategory == category,
                        action: { 
                            selectedCategory = selectedCategory == category ? nil : category 
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.blue : Color(UIColor.systemGray5))
                )
        }
    }
}

struct EventCardView: View {
    let event: MosqueEvent
    @ObservedObject var eventService: EventAPIService
    @State private var showingEventDetail = false
    @State private var isRegistering = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Event Header
            HStack {
                VStack(alignment: .leading) {
                    Text(event.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.leading)
                    
                    Text(event.category.displayName)
                        .font(.caption)
                        .foregroundColor(event.category.color)
                }
                
                Spacer()
                
                if event.isImportant {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                }
                
                Image(systemName: event.category.icon)
                    .foregroundColor(event.category.color)
                    .font(.title2)
            }
            
            // Event Details
            Text(event.description)
                .font(.body)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            
            HStack {
                Label(formatDate(event.startDate), systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if event.requiresRegistration {
                    Text("\(event.currentAttendees)/\(event.maxAttendees ?? 0)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Action Buttons
            HStack {
                Button("View Details") {
                    showingEventDetail = true
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                if event.requiresRegistration && !isEventFull(event) {
                    Button("Register") {
                        Task {
                            isRegistering = true
                            // Replace with actual user ID
                            let success = await eventService.registerForEvent(
                                eventId: event.id, 
                                userId: "current_user_id"
                            )
                            isRegistering = false
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isRegistering)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .sheet(isPresented: $showingEventDetail) {
            EventDetailView(event: event, eventService: eventService)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func isEventFull(_ event: MosqueEvent) -> Bool {
        guard let maxAttendees = event.maxAttendees else { return false }
        return event.currentAttendees >= maxAttendees
    }
}

struct EmptyEventsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Events Found")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Check back later for upcoming mosque events and programs.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct MosqueEventsErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Error")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button("Retry", action: onRetry)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview
struct MosqueEventsView_Previews: PreviewProvider {
    static var previews: some View {
        MosqueEventsView()
    }
}