import SwiftUI

// MARK: - Event Subscription Settings View
struct EventSubscriptionView: View {
    @ObservedObject var eventService: EventAPIService
    @State private var subscriptions = EventSubscription(
        userId: "current_user_id", // Replace with actual user ID
        subscribedCategories: Set(EventCategory.allCases),
        notifyBeforeMinutes: 30,
        isEnabled: true,
        lastUpdated: Date()
    )
    @State private var isUpdating = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Event Notifications")) {
                    Toggle("Enable Event Notifications", isOn: $subscriptions.isEnabled)
                        .onChange(of: subscriptions.isEnabled) { _ in
                            updateSubscriptions()
                        }
                }
                
                if subscriptions.isEnabled {
                    Section(header: Text("Categories")) {
                        ForEach(EventCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(category.color)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading) {
                                    Text(category.displayName)
                                        .font(.body)
                                    Text(categoryDescription(category))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: Binding(
                                    get: { subscriptions.subscribedCategories.contains(category) },
                                    set: { isEnabled in
                                        if isEnabled {
                                            subscriptions.subscribedCategories.insert(category)
                                        } else {
                                            subscriptions.subscribedCategories.remove(category)
                                        }
                                        updateSubscriptions()
                                    }
                                ))
                            }
                        }
                    }
                    
                    Section(header: Text("Notification Timing")) {
                        Picker("Notify me before", selection: $subscriptions.notifyBeforeMinutes) {
                            Text("15 minutes").tag(15)
                            Text("30 minutes").tag(30)
                            Text("1 hour").tag(60)
                            Text("2 hours").tag(120)
                            Text("1 day").tag(1440)
                        }
                        .onChange(of: subscriptions.notifyBeforeMinutes) { _ in
                            updateSubscriptions()
                        }
                    }
                }
                
                Section(footer: footerText) {
                    EmptyView()
                }
            }
            .navigationTitle("Event Subscriptions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isUpdating {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
            .onAppear {
                loadCurrentSubscriptions()
            }
        }
    }
    
    private var footerText: Text {
        Text("You will receive push notifications for events in selected categories. Notifications will be sent \(formatNotificationTime(subscriptions.notifyBeforeMinutes)) before each event starts.")
    }
    
    private func categoryDescription(_ category: EventCategory) -> String {
        switch category {
        case .lecture: return "Islamic talks and educational sessions"
        case .fundraising: return "Charity drives and fundraising events"
        case .community: return "Community gatherings and social events"
        case .education: return "Classes and educational programs"
        case .religious: return "Special prayers and religious observances"
        case .youth: return "Youth activities and programs"
        case .charity: return "Charitable work and volunteer opportunities"
        case .announcement: return "Important mosque announcements"
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
    
    private func loadCurrentSubscriptions() {
        if let currentSubscriptions = eventService.userSubscriptions {
            subscriptions = currentSubscriptions
        }
    }
    
    private func updateSubscriptions() {
        isUpdating = true
        subscriptions.lastUpdated = Date()
        
        Task {
            let success = await eventService.updateSubscriptions(
                subscriptions, 
                userId: subscriptions.userId
            )
            
            await MainActor.run {
                isUpdating = false
                if !success {
                    // Handle error - could show an alert
                }
            }
        }
    }
}

// MARK: - Create Event View (Admin)
struct CreateEventView: View {
    @ObservedObject var eventService: EventAPIService
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory = EventCategory.announcement
    @State private var startDate = Date()
    @State private var endDate: Date?
    @State private var hasEndDate = false
    @State private var location = ""
    @State private var organizer = ""
    @State private var isImportant = false
    @State private var imageURL = ""
    @State private var requiresRegistration = false
    @State private var maxAttendees = ""
    @State private var adminToken = ""
    @State private var isCreating = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Admin Authentication")) {
                    SecureField("Admin Token", text: $adminToken)
                        .textContentType(.password)
                }
                
                Section(header: Text("Event Details")) {
                    TextField("Event Title", text: $title)
                        .textContentType(.none)
                    
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(EventCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.displayName)
                            }
                            .tag(category)
                        }
                    }
                    
                    TextField("Location", text: $location)
                    TextField("Organizer", text: $organizer)
                    
                    Toggle("Important Event", isOn: $isImportant)
                    
                    TextField("Image URL (optional)", text: $imageURL)
                        .textContentType(.URL)
                        .keyboardType(.URL)
                }
                
                Section(header: Text("Date & Time")) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                    
                    Toggle("Has End Date", isOn: $hasEndDate)
                    
                    if hasEndDate {
                        DatePicker("End Date", selection: Binding(
                            get: { endDate ?? startDate },
                            set: { endDate = $0 }
                        ), displayedComponents: [.date, .hourAndMinute])
                    }
                }
                
                Section(header: Text("Registration")) {
                    Toggle("Requires Registration", isOn: $requiresRegistration)
                    
                    if requiresRegistration {
                        TextField("Max Attendees", text: $maxAttendees)
                            .keyboardType(.numberPad)
                    }
                }
            }
            .navigationTitle("Create Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createEvent()
                    }
                    .disabled(isCreating || !isFormValid)
                }
            }
            .disabled(isCreating)
            .overlay {
                if isCreating {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Creating Event...")
                            .font(.headline)
                            .padding(.top)
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(12)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var isFormValid: Bool {
        !title.isEmpty && !description.isEmpty && !location.isEmpty && 
        !organizer.isEmpty && !adminToken.isEmpty
    }
    
    private func createEvent() {
        guard isFormValid else { return }
        
        isCreating = true
        
        let request = CreateEventRequest(
            title: title,
            description: description,
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            category: selectedCategory,
            location: location,
            organizer: organizer,
            isImportant: isImportant,
            imageURL: imageURL.isEmpty ? nil : imageURL,
            maxAttendees: requiresRegistration ? Int(maxAttendees) : nil,
            requiresRegistration: requiresRegistration
        )
        
        Task {
            let result = await eventService.createEvent(request, adminToken: adminToken)
            
            await MainActor.run {
                isCreating = false
                
                switch result {
                case .success:
                    dismiss()
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

// MARK: - Event Detail View
struct EventDetailView: View {
    let event: MosqueEvent
    @ObservedObject var eventService: EventAPIService
    @State private var isRegistering = false
    @State private var showingRegistrationSuccess = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Event Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(event.title)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            if event.isImportant {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.title)
                            }
                        }
                        
                        HStack {
                            Image(systemName: event.category.icon)
                                .foregroundColor(event.category.color)
                            Text(event.category.displayName)
                                .font(.subheadline)
                                .foregroundColor(event.category.color)
                        }
                    }
                    
                    Divider()
                    
                    // Event Details
                    VStack(alignment: .leading, spacing: 16) {
                        DetailRow(icon: "calendar", title: "Date", value: formatDate(event.startDate))
                        
                        if let endDate = event.endDate, endDate != event.startDate {
                            DetailRow(icon: "calendar.badge.clock", title: "End Date", value: formatDate(endDate))
                        }
                        
                        DetailRow(icon: "location", title: "Location", value: event.location)
                        DetailRow(icon: "person", title: "Organizer", value: event.organizer)
                        
                        if event.requiresRegistration {
                            DetailRow(
                                icon: "person.3", 
                                title: "Attendees", 
                                value: "\(event.currentAttendees)\(event.maxAttendees.map { "/\($0)" } ?? "")"
                            )
                        }
                    }
                    
                    Divider()
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        Text(event.description)
                            .font(.body)
                    }
                    
                    Divider()
                    
                    // Registration Section
                    if event.requiresRegistration {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Registration")
                                .font(.headline)
                            
                            if isEventFull(event) {
                                Text("This event is fully booked.")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Registration is required for this event.")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                
                                Button("Register for Event") {
                                    registerForEvent()
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(isRegistering)
                            }
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Event Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Registration Successful", isPresented: $showingRegistrationSuccess) {
                Button("OK") { }
            } message: {
                Text("You have successfully registered for \(event.title).")
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func isEventFull(_ event: MosqueEvent) -> Bool {
        guard let maxAttendees = event.maxAttendees else { return false }
        return event.currentAttendees >= maxAttendees
    }
    
    private func registerForEvent() {
        isRegistering = true
        
        Task {
            let success = await eventService.registerForEvent(
                eventId: event.id, 
                userId: "current_user_id" // Replace with actual user ID
            )
            
            await MainActor.run {
                isRegistering = false
                if success {
                    showingRegistrationSuccess = true
                }
            }
        }
    }
}

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview
struct EventSubscriptionView_Previews: PreviewProvider {
    static var previews: some View {
        EventSubscriptionView(eventService: EventAPIService())
    }
}

struct CreateEventView_Previews: PreviewProvider {
    static var previews: some View {
        CreateEventView(eventService: EventAPIService())
    }
}

struct EventDetailView_Previews: PreviewProvider {
    static var previews: some View {
        EventDetailView(
            event: MosqueEvent(
                id: "1",
                title: "Islamic Finance Workshop",
                description: "Learn about Islamic banking and finance principles.",
                startDate: Date(),
                endDate: nil,
                category: .education,
                location: "Main Hall",
                organizer: "Imam Abdullah",
                isImportant: true,
                imageURL: nil,
                maxAttendees: 50,
                currentAttendees: 25,
                requiresRegistration: true,
                createdAt: Date(),
                updatedAt: Date()
            ),
            eventService: EventAPIService()
        )
    }
}