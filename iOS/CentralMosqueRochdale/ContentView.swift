import SwiftUI
import UserNotifications
import CoreLocation
import Combine

// Prayer Times Models and Views
struct PrayerTime {
    let name: String
    let startTime: String
    let jamaahTime: String
    let icon: String
}

struct PrayerTimesView: View {
    let prayerTimes = [
        PrayerTime(name: "Fajr", startTime: "5:45", jamaahTime: "6:00", icon: "sunrise"),
        PrayerTime(name: "Dhuhr", startTime: "12:30", jamaahTime: "1:15", icon: "sun.max"),
        PrayerTime(name: "Asr", startTime: "3:45", jamaahTime: "4:00", icon: "sun.and.horizon"),
        PrayerTime(name: "Maghrib", startTime: "6:20", jamaahTime: "6:25", icon: "sunset"),
        PrayerTime(name: "Esha", startTime: "7:45", jamaahTime: "8:00", icon: "moon.stars")
    ]
    
    let jummahTime = "1:30"
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Today's Prayer Times")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(getCurrentDate())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Jummah Special Section
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.green)
                            .font(.title2)
                        Text("Jummah Prayer")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    
                    HStack {
                        Text("Friday Jamaa'ah")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(jummahTime)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Prayer Times Table
                VStack(spacing: 0) {
                    // Table Header
                    HStack {
                        Text("Prayer")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("Start Time")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                        
                        Text("Jamaa'ah")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    
                    // Prayer Rows
                    ForEach(Array(prayerTimes.enumerated()), id: \.offset) { index, prayer in
                        PrayerRow(prayer: prayer, isEven: index % 2 == 0)
                    }
                }
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                
                // Footer Info
                VStack(spacing: 8) {
                    Text("🕌 Central Mosque Rochdale")
                        .font(.footnote)
                        .fontWeight(.medium)
                    
                    Text("Prayer times are calculated for Rochdale, UK")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
        .navigationTitle("Prayer Times")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func getCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: Date())
    }
}

struct PrayerRow: View {
    let prayer: PrayerTime
    let isEven: Bool
    
    var body: some View {
        HStack {
            HStack(spacing: 12) {
                Image(systemName: prayer.icon)
                    .foregroundColor(.blue)
                    .font(.title3)
                    .frame(width: 20)
                
                Text(prayer.name)
                    .font(.body)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(prayer.startTime)
                .font(.body)
                .fontWeight(.regular)
                .frame(maxWidth: .infinity)
            
            Text(prayer.jamaahTime)
                .font(.body)
                .fontWeight(.bold)
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
        .background(isEven ? Color.gray.opacity(0.05) : Color.clear)
    }
}

// Qibla Compass Models and Views
class QiblaCompassViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var qiblaDirection: Double = 0
    @Published var currentHeading: Double = 0
    @Published var locationPermissionStatus: CLAuthorizationStatus = .notDetermined
    @Published var isCalculatingQibla = false
    @Published var errorMessage: String? = nil
    @Published var userLocation: CLLocation? = nil
    @Published var distanceToKaaba: Double = 0
    
    private let locationManager = CLLocationManager()
    private let kaabaCoordinates = CLLocationCoordinate2D(latitude: 21.4225, longitude: 39.8262)
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startLocationUpdates() {
        guard locationPermissionStatus == .authorizedWhenInUse || locationPermissionStatus == .authorizedAlways else {
            errorMessage = "Location permission required"
            return
        }
        
        isCalculatingQibla = true
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
    
    private func calculateQiblaDirection(from userLocation: CLLocation) {
        let userLat = userLocation.coordinate.latitude * .pi / 180
        let userLon = userLocation.coordinate.longitude * .pi / 180
        let kaabaLat = kaabaCoordinates.latitude * .pi / 180
        let kaabaLon = kaabaCoordinates.longitude * .pi / 180
        
        let dLon = kaabaLon - userLon
        
        let x = sin(dLon) * cos(kaabaLat)
        let y = cos(userLat) * sin(kaabaLat) - sin(userLat) * cos(kaabaLat) * cos(dLon)
        
        let qiblaRadians = atan2(x, y)
        var qiblaDegrees = qiblaRadians * 180 / .pi
        
        if qiblaDegrees < 0 {
            qiblaDegrees += 360
        }
        
        self.qiblaDirection = qiblaDegrees
        
        // Calculate distance to Kaaba
        let kaabaLocation = CLLocation(latitude: kaabaCoordinates.latitude, longitude: kaabaCoordinates.longitude)
        self.distanceToKaaba = userLocation.distance(from: kaabaLocation) / 1000 // Convert to kilometers
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.locationPermissionStatus = manager.authorizationStatus
            if self.locationPermissionStatus == .authorizedWhenInUse || self.locationPermissionStatus == .authorizedAlways {
                self.startLocationUpdates()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async {
            self.userLocation = location
            self.calculateQiblaDirection(from: location)
            self.isCalculatingQibla = false
            self.errorMessage = nil
        }
        
        // Stop location updates to save battery
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        DispatchQueue.main.async {
            self.currentHeading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.errorMessage = "Failed to get location: \(error.localizedDescription)"
            self.isCalculatingQibla = false
        }
    }
}

struct QiblaCompassView: View {
    @StateObject private var viewModel = QiblaCompassViewModel()
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 8) {
                Text("🕋 Qibla Direction")
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let location = viewModel.userLocation {
                    Text("📍 \(formatLocation(location))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top)
            
            // Permission/Error Handling
            if viewModel.locationPermissionStatus != .authorizedWhenInUse && viewModel.locationPermissionStatus != .authorizedAlways {
                VStack(spacing: 16) {
                    Image(systemName: "location.slash")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    
                    Text("Location Permission Required")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("To find the Qibla direction, please allow location access.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Enable Location") {
                        viewModel.requestLocationPermission()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                
            } else if let errorMessage = viewModel.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                    
                    Text("Error")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Try Again") {
                        viewModel.startLocationUpdates()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                
            } else if viewModel.isCalculatingQibla {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    
                    Text("Finding Qibla Direction...")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text("Getting your location...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                
            } else {
                // Main Compass View
                VStack(spacing: 30) {
                    // Compass
                    ZStack {
                        // Compass Background
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 250, height: 250)
                        
                        // Compass Markings
                        ForEach(0..<36) { index in
                            Rectangle()
                                .fill(index % 9 == 0 ? Color.primary : Color.gray)
                                .frame(width: index % 9 == 0 ? 3 : 1, height: index % 9 == 0 ? 20 : 10)
                                .offset(y: -115)
                                .rotationEffect(.degrees(Double(index) * 10))
                        }
                        
                        // Cardinal Directions
                        VStack {
                            Text("N")
                                .font(.headline)
                                .fontWeight(.bold)
                                .offset(y: -110)
                            Spacer()
                            Text("S")
                                .font(.headline)
                                .fontWeight(.bold)
                                .offset(y: 110)
                        }
                        .frame(height: 250)
                        
                        HStack {
                            Text("W")
                                .font(.headline)
                                .fontWeight(.bold)
                                .offset(x: -110)
                            Spacer()
                            Text("E")
                                .font(.headline)
                                .fontWeight(.bold)
                                .offset(x: 110)
                        }
                        .frame(width: 250)
                        
                        // Qibla Indicator (Fixed to Qibla direction)
                        Image(systemName: "triangle.fill")
                            .font(.title)
                            .foregroundColor(.green)
                            .offset(y: -100)
                            .rotationEffect(.degrees(viewModel.qiblaDirection - viewModel.currentHeading))
                        
                        // Phone Direction Indicator
                        Image(systemName: "phone")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .offset(y: -80)
                        
                        // Center Kaaba
                        Text("🕋")
                            .font(.title)
                    }
                    .rotationEffect(.degrees(-viewModel.currentHeading))
                    
                    // Direction Info
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Qibla Direction")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(Int(viewModel.qiblaDirection))°")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Your Heading")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(Int(viewModel.currentHeading))°")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        if viewModel.distanceToKaaba > 0 {
                            HStack {
                                Image(systemName: "location")
                                    .foregroundColor(.secondary)
                                Text("Distance to Kaaba: \(String(format: "%.0f", viewModel.distanceToKaaba)) km")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Instructions
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "triangle.fill")
                                .foregroundColor(.green)
                            Text("Green arrow points to Qibla")
                                .font(.caption)
                        }
                        
                        HStack {
                            Image(systemName: "phone")
                                .foregroundColor(.blue)
                            Text("Blue phone shows your direction")
                                .font(.caption)
                        }
                        
                        Text("Hold your phone flat and rotate until the green arrow points up")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            
            Spacer()
            
            // Footer
            Text("🕌 Central Mosque Rochdale")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .navigationTitle("Qibla Compass")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel.locationPermissionStatus == .authorizedWhenInUse || viewModel.locationPermissionStatus == .authorizedAlways {
                viewModel.startLocationUpdates()
            }
        }
    }
    
    private func formatLocation(_ location: CLLocation) -> String {
        let formatter = CLGeocoder()
        return "Lat: \(String(format: "%.4f", location.coordinate.latitude)), Lon: \(String(format: "%.4f", location.coordinate.longitude))"
    }
}

// Mosque Events Models and Views
struct MosqueEvent: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let date: Date
    let time: String
    let category: EventCategory
    let location: String
    let organizer: String
    let maxAttendees: Int?
    let currentAttendees: Int
    let isRegistrationRequired: Bool
    let imageSystemName: String
    let backgroundColor: Color
}

enum EventCategory: String, CaseIterable {
    case lecture = "Lecture"
    case community = "Community"
    case fundraising = "Fundraising"
    case educational = "Educational"
    case social = "Social"
    case religious = "Religious"
    case youth = "Youth"
    case charity = "Charity"
    
    var icon: String {
        switch self {
        case .lecture: return "book.closed"
        case .community: return "people"
        case .fundraising: return "heart.circle"
        case .educational: return "graduationcap"
        case .social: return "party.popper"
        case .religious: return "moon.stars"
        case .youth: return "figure.2.arms.open"
        case .charity: return "gift"
        }
    }
    
    var color: Color {
        switch self {
        case .lecture: return .blue
        case .community: return .green
        case .fundraising: return .red
        case .educational: return .purple
        case .social: return .orange
        case .religious: return .indigo
        case .youth: return .pink
        case .charity: return .teal
        }
    }
}

class MosqueEventsViewModel: ObservableObject {
    @Published var events: [MosqueEvent] = []
    @Published var selectedCategory: EventCategory? = nil
    @Published var isLoading = false
    
    init() {
        loadMockEvents()
    }
    
    private func loadMockEvents() {
        // Create dates for upcoming events
        let today = Date()
        let calendar = Calendar.current
        
        events = [
            MosqueEvent(
                title: "Friday Night Lecture Series",
                description: "Join us for an enlightening lecture on 'The Importance of Community in Islam' by Imam Abdullah. This weekly series focuses on building stronger bonds within our Muslim community and understanding our responsibilities toward one another.",
                date: calendar.date(byAdding: .day, value: 2, to: today) ?? today,
                time: "7:30 PM - 9:00 PM",
                category: .lecture,
                location: "Main Prayer Hall",
                organizer: "Imam Abdullah",
                maxAttendees: 150,
                currentAttendees: 87,
                isRegistrationRequired: false,
                imageSystemName: "book.closed.fill",
                backgroundColor: .blue.opacity(0.1)
            ),
            
            MosqueEvent(
                title: "Community Iftar Preparation",
                description: "Help us prepare for the upcoming community Iftar. We need volunteers to help with cooking, setting up tables, and welcoming guests. This is a great opportunity to earn rewards while serving our community.",
                date: calendar.date(byAdding: .day, value: 5, to: today) ?? today,
                time: "2:00 PM - 6:00 PM",
                category: .community,
                location: "Community Kitchen",
                organizer: "Sister Fatima",
                maxAttendees: 30,
                currentAttendees: 18,
                isRegistrationRequired: true,
                imageSystemName: "person.3.fill",
                backgroundColor: .green.opacity(0.1)
            ),
            
            MosqueEvent(
                title: "Mosque Expansion Fundraiser",
                description: "Annual fundraising dinner to support the mosque expansion project. Enjoy a delicious three-course meal while contributing to the growth of our Islamic center. Silent auction items available.",
                date: calendar.date(byAdding: .day, value: 12, to: today) ?? today,
                time: "6:00 PM - 10:00 PM",
                category: .fundraising,
                location: "Community Hall",
                organizer: "Fundraising Committee",
                maxAttendees: 200,
                currentAttendees: 156,
                isRegistrationRequired: true,
                imageSystemName: "heart.circle.fill",
                backgroundColor: .red.opacity(0.1)
            ),
            
            MosqueEvent(
                title: "Arabic Classes for Beginners",
                description: "Start your journey learning Arabic with our qualified teacher. Perfect for those who want to better understand the Quran and Islamic texts. Classes include basic grammar, vocabulary, and reading skills.",
                date: calendar.date(byAdding: .day, value: 7, to: today) ?? today,
                time: "10:00 AM - 12:00 PM",
                category: .educational,
                location: "Classroom A",
                organizer: "Ustadh Omar",
                maxAttendees: 25,
                currentAttendees: 12,
                isRegistrationRequired: true,
                imageSystemName: "graduationcap.fill",
                backgroundColor: .purple.opacity(0.1)
            ),
            
            MosqueEvent(
                title: "Youth Sports Tournament",
                description: "Annual youth sports day featuring football, basketball, and table tennis competitions. Open to all youth aged 12-18. Prizes for winners and refreshments provided. Bring your friends!",
                date: calendar.date(byAdding: .day, value: 15, to: today) ?? today,
                time: "9:00 AM - 5:00 PM",
                category: .youth,
                location: "Sports Ground",
                organizer: "Youth Committee",
                maxAttendees: 80,
                currentAttendees: 45,
                isRegistrationRequired: true,
                imageSystemName: "figure.2.arms.open",
                backgroundColor: .pink.opacity(0.1)
            ),
            
            MosqueEvent(
                title: "Night of Remembrance (Dhikr)",
                description: "Join us for a peaceful evening of dhikr and remembrance of Allah. We'll recite beautiful supplications, reflect on our faith, and strengthen our spiritual connection together.",
                date: calendar.date(byAdding: .day, value: 3, to: today) ?? today,
                time: "8:00 PM - 10:00 PM",
                category: .religious,
                location: "Main Prayer Hall",
                organizer: "Imam Abdullah",
                maxAttendees: nil,
                currentAttendees: 0,
                isRegistrationRequired: false,
                imageSystemName: "moon.stars.fill",
                backgroundColor: .indigo.opacity(0.1)
            )
        ]
    }
    
    var filteredEvents: [MosqueEvent] {
        if let selectedCategory = selectedCategory {
            return events.filter { $0.category == selectedCategory }
        }
        return events.sorted { $0.date < $1.date }
    }
}

struct MosqueEventsView: View {
    @StateObject private var viewModel = MosqueEventsViewModel()
    @State private var showingEventDetail = false
    @State private var selectedEvent: MosqueEvent? = nil
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 12) {
                    Text("🕌 Upcoming Events")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Stay connected with our mosque community")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        CategoryFilterButton(
                            title: "All Events",
                            isSelected: viewModel.selectedCategory == nil,
                            color: .blue
                        ) {
                            viewModel.selectedCategory = nil
                        }
                        
                        ForEach(EventCategory.allCases, id: \.self) { category in
                            CategoryFilterButton(
                                title: category.rawValue,
                                isSelected: viewModel.selectedCategory == category,
                                color: category.color
                            ) {
                                viewModel.selectedCategory = category == viewModel.selectedCategory ? nil : category
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Events List
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.filteredEvents) { event in
                        EventCard(event: event) {
                            selectedEvent = event
                            showingEventDetail = true
                        }
                    }
                }
                .padding(.horizontal)
                
                // Footer
                VStack(spacing: 8) {
                    Text("🕌 Central Mosque Rochdale")
                        .font(.footnote)
                        .fontWeight(.medium)
                    
                    Text("Building community through faith and fellowship")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
        .navigationTitle("Events")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEventDetail) {
            if let event = selectedEvent {
                EventDetailView(event: event)
            }
        }
    }
}

struct CategoryFilterButton: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? color : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct EventCard: View {
    let event: MosqueEvent
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with category and date
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: event.category.icon)
                            .foregroundColor(event.category.color)
                        Text(event.category.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(event.category.color)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(event.category.color.opacity(0.1))
                    .cornerRadius(8)
                    
                    Spacer()
                    
                    Text(formatDate(event.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Event Title and Description
                VStack(alignment: .leading, spacing: 8) {
                    Text(event.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(event.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                
                // Event Details
                VStack(spacing: 6) {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.blue)
                        Text(event.time)
                            .font(.caption)
                        Spacer()
                        Image(systemName: "location")
                            .foregroundColor(.blue)
                        Text(event.location)
                            .font(.caption)
                    }
                    
                    if let maxAttendees = event.maxAttendees {
                        HStack {
                            Image(systemName: "person.2")
                                .foregroundColor(.green)
                            Text("\(event.currentAttendees)/\(maxAttendees) attending")
                                .font(.caption)
                            
                            Spacer()
                            
                            if event.isRegistrationRequired {
                                Text("Registration Required")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
                .foregroundColor(.secondary)
                
                // Action Footer
                HStack {
                    Text("Organized by \(event.organizer)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(event.backgroundColor)
            .cornerRadius(12)
            .shadow(color: .gray.opacity(0.1), radius: 3, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

struct EventDetailView: View {
    let event: MosqueEvent
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Event Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: event.imageSystemName)
                                .font(.title)
                                .foregroundColor(event.category.color)
                            
                            VStack(alignment: .leading) {
                                Text(event.category.rawValue)
                                    .font(.caption)
                                    .foregroundColor(event.category.color)
                                Text(formatDate(event.date))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Text(event.title)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Divider()
                    
                    // Event Details
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Event Details")
                            .font(.headline)
                        
                        Text(event.description)
                            .font(.body)
                            .lineSpacing(4)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            DetailRow(icon: "clock", title: "Time", value: event.time)
                            DetailRow(icon: "location", title: "Location", value: event.location)
                            DetailRow(icon: "person", title: "Organizer", value: event.organizer)
                            
                            if let maxAttendees = event.maxAttendees {
                                DetailRow(icon: "person.2", title: "Attendance", value: "\(event.currentAttendees)/\(maxAttendees)")
                            }
                        }
                    }
                    
                    if event.isRegistrationRequired {
                        Divider()
                        
                        VStack(spacing: 12) {
                            Text("Registration Required")
                                .font(.headline)
                            
                            Text("Please register to secure your spot for this event.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Button("Register Now") {
                                // Registration action
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                        }
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("Event Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
}

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .fontWeight(.medium)
            
            Spacer()
            
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

// Notification Settings Models and Views
struct PrayerNotificationSetting: Equatable {
    let prayer: String
    let icon: String
    var isEnabled: Bool
    var reminderMinutes: Int
}

class NotificationSettingsViewModel: ObservableObject {
    @Published var prayerNotifications = [
        PrayerNotificationSetting(prayer: "Fajr", icon: "sunrise", isEnabled: true, reminderMinutes: 10),
        PrayerNotificationSetting(prayer: "Dhuhr", icon: "sun.max", isEnabled: true, reminderMinutes: 15),
        PrayerNotificationSetting(prayer: "Asr", icon: "sun.and.horizon", isEnabled: true, reminderMinutes: 10),
        PrayerNotificationSetting(prayer: "Maghrib", icon: "sunset", isEnabled: true, reminderMinutes: 5),
        PrayerNotificationSetting(prayer: "Esha", icon: "moon.stars", isEnabled: true, reminderMinutes: 10)
    ]
    
    @Published var jummahEnabled = true
    @Published var jummahReminderMinutes = 30
    @Published var notificationsPermissionGranted = false
    
    // Prayer times for notification scheduling (Jamaa'ah times)
    private let prayerJamaahTimes = [
        "Fajr": "6:00",
        "Dhuhr": "1:15", 
        "Asr": "4:00",
        "Maghrib": "6:25",
        "Esha": "8:00"
    ]
    
    private let jummahTime = "1:30"
    
    init() {
        checkNotificationPermission()
        scheduleAllNotifications()
    }
    
    func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationsPermissionGranted = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.notificationsPermissionGranted = granted
                if granted {
                    self.scheduleAllNotifications()
                }
            }
        }
    }
    
    // MARK: - Notification Scheduling
    
    func scheduleAllNotifications() {
        guard notificationsPermissionGranted else { return }
        
        // Cancel existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Schedule daily prayer notifications
        for (index, setting) in prayerNotifications.enumerated() {
            if setting.isEnabled {
                schedulePrayerNotification(for: setting, at: index)
            }
        }
        
        // Schedule Jummah notification
        if jummahEnabled {
            scheduleJummahNotification()
        }
    }
    
    private func schedulePrayerNotification(for setting: PrayerNotificationSetting, at index: Int) {
        guard let jamaahTimeString = prayerJamaahTimes[setting.prayer],
              let jamaahTime = timeFromString(jamaahTimeString) else { return }
        
        // Calculate notification time (reminder minutes before Jamaa'ah)
        let notificationTime = Calendar.current.date(byAdding: .minute, value: -setting.reminderMinutes, to: jamaahTime)!
        
        let content = UNMutableNotificationContent()
        content.title = "🕌 Prayer Reminder"
        content.body = "\(setting.prayer) Jamaa'ah in \(setting.reminderMinutes) minutes at Central Mosque Rochdale"
        content.sound = .default
        content.badge = 1
        
        // Create daily repeating trigger
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: notificationTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "prayer-\(setting.prayer.lowercased())",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling \(setting.prayer) notification: \(error)")
            }
        }
    }
    
    private func scheduleJummahNotification() {
        guard let jummahTimeObj = timeFromString(jummahTime) else { return }
        
        // Calculate notification time
        let notificationTime = Calendar.current.date(byAdding: .minute, value: -jummahReminderMinutes, to: jummahTimeObj)!
        
        let content = UNMutableNotificationContent()
        content.title = "🕌 Jummah Prayer Reminder"
        content.body = "Jummah prayer in \(jummahReminderMinutes) minutes at Central Mosque Rochdale. Don't miss the congregation!"
        content.sound = .default
        content.badge = 1
        
        // Schedule for Fridays only
        let calendar = Calendar.current
        var components = calendar.dateComponents([.hour, .minute], from: notificationTime)
        components.weekday = 6 // Friday
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "jummah-prayer",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling Jummah notification: \(error)")
            }
        }
    }
    
    private func timeFromString(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateFormat = "H:mm"
        
        if let time = formatter.date(from: timeString) {
            // Convert to today's date with this time
            let calendar = Calendar.current
            let now = Date()
            let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
            return calendar.date(bySettingHour: timeComponents.hour ?? 0, minute: timeComponents.minute ?? 0, second: 0, of: now)
        }
        return nil
    }
    
    func updateNotificationSettings() {
        scheduleAllNotifications()
    }
}

struct NotificationSettingsView: View {
    @StateObject private var viewModel = NotificationSettingsViewModel()
    
    var body: some View {
        List {
            // Permission Section
            Section {
                if !viewModel.notificationsPermissionGranted {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "bell.slash")
                                .foregroundColor(.orange)
                                .font(.title2)
                            Text("Notifications Disabled")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        Text("To receive prayer reminders, please enable notifications for this app.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button("Enable Notifications") {
                            viewModel.requestNotificationPermission()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.vertical, 8)
                } else {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Notifications Enabled")
                            .font(.headline)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Permission Status")
            }
            
            // Daily Prayers Section
            Section {
                ForEach(Array(viewModel.prayerNotifications.enumerated()), id: \.offset) { index, setting in
                    PrayerNotificationRow(
                        setting: $viewModel.prayerNotifications[index],
                        isEnabled: viewModel.notificationsPermissionGranted
                    )
                }
            } header: {
                HStack {
                    Image(systemName: "clock")
                    Text("Daily Prayer Reminders")
                }
            } footer: {
                Text("Receive notifications before Jamaa'ah (congregation) prayer times to never miss praying with the community at the mosque.")
                    .font(.caption)
            }
            
            // Jummah Section
            Section {
                HStack {
                    HStack(spacing: 12) {
                        Image(systemName: "calendar")
                            .foregroundColor(.green)
                            .font(.title3)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Jummah Prayer")
                                .font(.body)
                                .fontWeight(.medium)
                            Text("Friday congregation")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $viewModel.jummahEnabled)
                        .disabled(!viewModel.notificationsPermissionGranted)
                }
                
                if viewModel.jummahEnabled && viewModel.notificationsPermissionGranted {
                    HStack {
                        Text("Remind me")
                            .foregroundColor(.secondary)
                        Spacer()
                        Picker("Minutes", selection: $viewModel.jummahReminderMinutes) {
                            Text("15 minutes before").tag(15)
                            Text("30 minutes before").tag(30)
                            Text("1 hour before").tag(60)
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
            } header: {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                    Text("Jummah Reminder")
                }
            } footer: {
                Text("Special reminder for Friday Jummah prayer.")
                    .font(.caption)
            }
            
            // Settings Section
            Section {
                HStack {
                    Image(systemName: "speaker.wave.2")
                        .foregroundColor(.blue)
                    Text("Notification Sound")
                    Spacer()
                    Text("Default")
                        .foregroundColor(.secondary)
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                
                HStack {
                    Image(systemName: "gear")
                        .foregroundColor(.blue)
                    Text("Open Settings App")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .onTapGesture {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
            } header: {
                Text("Additional Settings")
            } footer: {
                Text("🕌 Central Mosque Rochdale\nStay connected with your prayer times")
                    .multilineTextAlignment(.center)
                    .font(.caption)
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.checkNotificationPermission()
        }
        .onChange(of: viewModel.prayerNotifications) { _ in
            viewModel.updateNotificationSettings()
        }
        .onChange(of: viewModel.jummahEnabled) { _ in
            viewModel.updateNotificationSettings()
        }
        .onChange(of: viewModel.jummahReminderMinutes) { _ in
            viewModel.updateNotificationSettings()
        }
    }
}

struct PrayerNotificationRow: View {
    @Binding var setting: PrayerNotificationSetting
    let isEnabled: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: setting.icon)
                        .foregroundColor(.blue)
                        .font(.title3)
                        .frame(width: 24)
                    
                    Text(setting.prayer)
                        .font(.body)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                Toggle("", isOn: $setting.isEnabled)
                    .disabled(!isEnabled)
            }
            
            if setting.isEnabled && isEnabled {
                HStack {
                    Text("Remind me")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Picker("Minutes", selection: $setting.reminderMinutes) {
                        Text("5 minutes before").tag(5)
                        Text("10 minutes before").tag(10)
                        Text("15 minutes before").tag(15)
                        Text("30 minutes before").tag(30)
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                .padding(.leading, 36)
            }
        }
    }
}

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("🕌 Central Mosque\nRochdale")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.top, 20)
                
                
                VStack(spacing: 20) {
                    NavigationLink(destination: PrayerTimesView()) {
                        FeatureRow(icon: "clock", title: "Prayer Times", description: "View daily prayer schedule")
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: QiblaCompassView()) {
                        FeatureRow(icon: "safari", title: "Qibla Compass", description: "Find prayer direction")
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: MosqueEventsView()) {
                        FeatureRow(icon: "calendar", title: "Events", description: "Mosque events & announcements")
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: NotificationSettingsView()) {
                        FeatureRow(icon: "bell", title: "Notifications", description: "Prayer reminders")
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
                    .foregroundColor(.primary)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

#Preview {
    ContentView()
}
