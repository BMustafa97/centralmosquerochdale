# Mosque Events System - Push Notifications & Admin Management

A comprehensive mosque events system with push notifications, user subscriptions, and admin event creation capabilities for both iOS (SwiftUI) and Android (Jetpack Compose).

## Features

### 📅 Event Management
- **Event Categories**: 8 distinct categories with custom icons and colors
  - Islamic Lectures, Fundraising, Community Events, Educational
  - Religious, Youth Programs, Charity Work, Announcements
- **Event Details**: Title, description, date/time, location, organizer
- **Registration System**: Optional event registration with attendance limits
- **Importance Flags**: Mark critical events for priority notifications

### 🔔 Push Notification System
- **Category Subscriptions**: Users choose which event types to follow
- **Customizable Timing**: Notifications 15 minutes to 1 day before events
- **Smart Filtering**: Only receive alerts for subscribed categories
- **Real-time Delivery**: Firebase FCM for Android, APNs for iOS

### 👨‍💼 Admin Features
- **Event Creation**: Secure admin interface for creating new events
- **Token Authentication**: Admin token-based security
- **Real-time Updates**: Events appear immediately after creation
- **Bulk Management**: Mass event operations and notifications

### 📱 User Experience
- **Category Filtering**: Filter events by category or view all
- **Event Registration**: One-tap registration for limited events
- **Detailed Views**: Full event information with organizer details
- **Subscription Management**: Easy notification preference controls

## iOS Implementation (SwiftUI)

### Core Components

#### `MosqueEventsView.swift`
- **EventAPIService**: ObservableObject for API communication
- **Event Models**: Comprehensive data structures for events and subscriptions
- **Category System**: Enum-based categories with icons and colors
- **Networking**: URLSession-based API integration with error handling

#### Key Features
```swift
// Event fetching with error handling
func fetchEvents() async {
    do {
        let fetchedEvents = try decoder.decode([MosqueEvent].self, from: data)
        await MainActor.run {
            self.events = fetchedEvents.sorted { $0.startDate < $1.startDate }
        }
    } catch {
        // Handle errors gracefully
    }
}

// Real-time subscription updates
func updateSubscriptions(_ subscription: EventSubscription, userId: String) async -> Bool
```

#### UI Components
- **EventCardView**: Card-based event display with registration buttons
- **CategoryFilterView**: Horizontal scrolling category chips
- **EventDetailView**: Full-screen event details with registration
- **ErrorView & EmptyEventsView**: Proper state handling

### Event Subscription Management

#### `EventSubscriptionView.swift`
- **Category Toggles**: Individual switches for each event category
- **Notification Timing**: Picker for reminder timing (15min - 1 day)
- **Form Validation**: Real-time validation with user feedback
- **Settings Persistence**: UserDefaults integration for preferences

#### Admin Event Creation
- **Secure Authentication**: Admin token requirement
- **Form Validation**: Complete form validation with visual feedback
- **Date Selection**: DatePicker integration for event scheduling
- **Category Selection**: Dropdown with visual category indicators

## Android Implementation (Jetpack Compose)

### Core Components

#### `MosqueEventsCompose.kt`
- **EventsViewModel**: MVVM architecture with StateFlow
- **Firebase Integration**: FCM for push notification delivery
- **OkHttp Networking**: REST API communication with JSON handling
- **Material Design 3**: Native Android design components

#### Key Features
```kotlin
// State management with StateFlow
class EventsViewModel : ViewModel() {
    private val _state = MutableStateFlow(EventsState())
    val state: StateFlow<EventsState> = _state.asStateFlow()
    
    fun filterByCategory(category: EventCategory?) {
        _state.value = currentState.copy(
            selectedCategory = category,
            filteredEvents = filterEvents(currentState.events, category)
        )
    }
}
```

#### UI Components
- **EventCard**: Material Design cards with elevation and animations
- **CategoryFilterRow**: LazyRow with FilterChips for categories
- **LoadingView & ErrorView**: Consistent state management
- **EventDetailDialog**: Full-screen modal with event details

### Event Subscription System

#### `EventSubscriptionCompose.kt`
- **Dialog-based Interface**: Full-screen subscription management
- **Switch Controls**: Individual category toggles with descriptions
- **Radio Button Groups**: Notification timing selection
- **Real-time Updates**: Immediate preference synchronization

#### Admin Panel
- **Secure Token Input**: Password-masked admin authentication
- **Dropdown Menus**: Category selection with icons
- **Form Validation**: Real-time validation with error states
- **Progress Indicators**: Loading states during event creation

## Data Models & API Integration

### Event Structure
```swift
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
    let maxAttendees: Int?
    let currentAttendees: Int
    let requiresRegistration: Bool
}
```

### Subscription Management
```kotlin
data class EventSubscription(
    val userId: String,
    val subscribedCategories: Set<EventCategory>,
    val notifyBeforeMinutes: Int,
    val isEnabled: Boolean,
    val lastUpdated: Date
)
```

## API Endpoints

### Event Management
- `GET /api/events` - Fetch all events
- `POST /api/admin/events` - Create new event (admin only)
- `PUT /api/events/{id}` - Update event (admin only)
- `DELETE /api/events/{id}` - Delete event (admin only)

### User Management
- `GET /api/users/{id}/subscriptions` - Get user subscriptions
- `PUT /api/users/{id}/subscriptions` - Update subscriptions
- `POST /api/events/{id}/register` - Register for event
- `DELETE /api/events/{id}/register/{userId}` - Cancel registration

### Notification System
- `POST /api/notifications/send` - Send push notification (admin)
- `POST /api/notifications/schedule` - Schedule event notifications
- `GET /api/notifications/tokens` - Manage FCM tokens

## Push Notification Flow

### iOS (APNs)
1. **Registration**: App registers for remote notifications
2. **Token Management**: Device token sent to server
3. **Event Creation**: Admin creates event via API
4. **Notification Scheduling**: Server schedules notifications based on user subscriptions
5. **Delivery**: APNs delivers notifications at scheduled times

### Android (FCM)
1. **Firebase Setup**: FCM token generation and management
2. **Subscription Sync**: User preferences synchronized with server
3. **Event Notifications**: Server sends targeted notifications via FCM
4. **Local Notifications**: WorkManager for reliable local notifications
5. **Background Processing**: Notifications work even when app is closed

## Security & Authentication

### Admin Authentication
- **Token-based Security**: Secure admin tokens for event management
- **Role-based Access**: Different permission levels for users and admins
- **API Rate Limiting**: Prevent abuse of admin endpoints
- **Audit Logging**: Track all admin actions and event modifications

### User Privacy
- **Subscription Control**: Complete user control over notification preferences
- **Data Encryption**: Secure transmission of user preferences
- **GDPR Compliance**: User data handling and deletion rights
- **Opt-out Options**: Easy unsubscribe from all notifications

## Event Categories & Customization

### Category System
Each category includes:
- **Display Name**: User-friendly category name
- **Icon**: Vector icon for visual identification
- **Color**: Brand-consistent color coding
- **Description**: Helpful category explanation

### Extensibility
- **New Categories**: Easy addition of new event types
- **Custom Icons**: Support for custom category icons
- **Localization**: Multi-language category names
- **Theming**: Customizable color schemes

## Performance & Scalability

### Optimization
- **Lazy Loading**: Events loaded on-demand with pagination
- **Image Caching**: Efficient event image handling
- **Background Refresh**: Smart content updates without user interaction
- **Memory Management**: Proper resource cleanup and management

### Scalability
- **Database Indexing**: Optimized queries for large event datasets
- **CDN Integration**: Fast image and content delivery
- **Caching Strategy**: Multi-level caching for improved performance
- **Load Balancing**: Server-side scaling for high traffic

## Testing & Quality Assurance

### Unit Testing
- **API Integration**: Mock API responses for testing
- **State Management**: ViewModel and ObservableObject testing
- **Business Logic**: Event filtering and subscription logic
- **Error Handling**: Comprehensive error scenario testing

### UI Testing
- **User Flows**: Complete user journey testing
- **Accessibility**: Screen reader and accessibility compliance
- **Cross-device**: Testing on various screen sizes and orientations
- **Performance**: Memory usage and battery impact testing

This implementation provides a complete, production-ready mosque events system with sophisticated push notification capabilities, admin management tools, and excellent user experience across both iOS and Android platforms.