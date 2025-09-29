# Push Notification Implementation - SwiftUI & Jetpack Compose

Comprehensive push notification system for prayer reminders using Apple Push Notification Service (APNs) for iOS and Firebase Cloud Messaging (FCM) for Android.

## Features

- **Individual Prayer Toggles**: Enable/disable notifications for each of the five daily prayers
- **Customizable Reminder Times**: Choose 5, 10, or 15 minutes before Jamaa'ah time
- **Local & Remote Notifications**: Support for both local scheduled notifications and remote push notifications
- **Permission Management**: Proper notification permission handling with clear user prompts
- **Persistent Settings**: User preferences saved locally and synchronized
- **Background Scheduling**: Notifications work even when app is closed

## iOS Implementation (SwiftUI + APNs)

### Key Components

#### `PrayerNotificationManager`
- **ObservableObject** for reactive state management
- **UserNotifications** framework integration
- Local notification scheduling with `UNCalendarNotificationTrigger`
- Settings persistence using `UserDefaults`

#### Core Features
```swift
// Request notification permission
func requestNotificationPermission() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
}

// Schedule daily repeating notifications
let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
```

#### UI Components
- **`NotificationSettingsView`**: Main settings screen with form-based layout
- **`NotificationPermissionView`**: Permission request UI with status handling
- **`NotificationToggleSection`**: Individual prayer toggle switches
- **`ReminderTimeSection`**: Segmented picker for reminder timing

#### Permission States
- **Not Determined**: Show permission request UI
- **Denied**: Direct user to Settings app
- **Authorized**: Enable full notification functionality

### Required Setup

#### Info.plist
```xml
<key>NSUserNotificationsUsageDescription</key>
<string>This app needs notification permission to send prayer reminders</string>
```

#### App Delegate Integration
```swift
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
}
```

## Android Implementation (Jetpack Compose + Firebase)

### Key Components

#### `PrayerFirebaseMessagingService`
- Extends `FirebaseMessagingService` for remote push notifications
- Handles FCM token registration and renewal
- Creates notification channels for Android 8.0+
- Custom notification display with mosque branding

#### `PrayerNotificationWorker`
- **WorkManager** integration for reliable background scheduling
- Local notification delivery even when app is closed
- Handles notification timing and content

#### `PrayerNotificationManager`
- Settings persistence using `SharedPreferences`
- FCM token management and server communication
- WorkManager task scheduling for all prayer notifications

### Core Features
```kotlin
// Schedule notification with WorkManager
val workRequest = OneTimeWorkRequestBuilder<PrayerNotificationWorker>()
    .setInitialDelay(delay, TimeUnit.MILLISECONDS)
    .addTag("prayer_notifications")
    .build()

// Create notification channel (Android 8.0+)
val channel = NotificationChannel(
    "prayer_notifications",
    "Prayer Notifications",
    NotificationManager.IMPORTANCE_HIGH
)
```

#### UI Components
- **`NotificationSettingsScreen`**: Material Design 3 settings interface
- **`NotificationPermissionCard`**: Permission request with error state handling
- **`NotificationToggleSection`**: Prayer-specific notification toggles
- **`ReminderTimeSection`**: Chip-based time selection interface

### Required Setup

#### AndroidManifest.xml
```xml
<!-- Notification permission (Android 13+) -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<!-- Firebase Messaging Service -->
<service
    android:name=".PrayerFirebaseMessagingService"
    android:exported="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
</service>
```

#### build.gradle Dependencies
```gradle
implementation 'com.google.firebase:firebase-messaging:23.3.1'
implementation 'androidx.work:work-runtime-ktx:2.8.1'
implementation 'androidx.compose.material3:material3:1.1.2'
```

#### Firebase Configuration
1. Add `google-services.json` to app directory
2. Configure Firebase project with FCM enabled
3. Set up server endpoint for token management

## Architecture Patterns

### iOS (MVVM + Combine)
```swift
@StateObject private var notificationManager = PrayerNotificationManager()

// Reactive state updates
@Published var settings = PrayerNotificationSettings()
@Published var notificationPermissionStatus: UNAuthorizationStatus
```

### Android (MVVM + StateFlow)
```kotlin
class NotificationSettingsViewModel : ViewModel() {
    private val _state = MutableStateFlow(NotificationState())
    val state: StateFlow<NotificationState> = _state.asStateFlow()
}
```

## Notification Scheduling Logic

### Time Calculation
Both platforms calculate notification time by:
1. Parsing Jamaa'ah time string (HH:mm format)
2. Subtracting reminder minutes (5, 10, or 15)
3. Scheduling for today if time hasn't passed, tomorrow otherwise
4. Setting up daily repeating notifications

### Example Calculation
```
Maghrib Jamaa'ah: 18:50
Reminder Time: 10 minutes
Notification Time: 18:40
```

## User Experience Flow

### First Launch
1. **Permission Request**: Show explanation of notification benefits
2. **Settings Tour**: Guide user through prayer toggle options
3. **Reminder Setup**: Help user choose preferred reminder timing
4. **Confirmation**: Show scheduled notifications summary

### Daily Usage
1. **Background Notifications**: Automatic reminders without app interaction
2. **Quick Settings**: Easy access to toggle individual prayers
3. **Time Adjustment**: Simple interface to change reminder timing
4. **Status Feedback**: Clear indicators of notification status

## Advanced Features

### Smart Scheduling
- **Timezone Awareness**: Automatic adjustment for travel
- **Seasonal Updates**: Prayer times change with seasons
- **Weekend Handling**: Special scheduling for Friday prayers
- **Holiday Management**: Adjusted timing for Islamic holidays

### Analytics & Tracking
- **Notification Delivery**: Track successful notification delivery
- **User Engagement**: Monitor which prayers get most attention
- **Settings Usage**: Understand user preference patterns
- **Performance Metrics**: Notification timing accuracy

### Server Integration
- **Token Management**: FCM token registration and updates
- **Targeted Messaging**: Location-based notifications
- **Bulk Operations**: Mass notification scheduling
- **Analytics Dashboard**: Server-side notification metrics

## Error Handling

### Common Scenarios
- **Permission Denied**: Graceful fallback with settings redirect
- **Network Issues**: Local notifications as backup
- **Time Zone Changes**: Automatic rescheduling
- **App Updates**: Notification migration and validation

### Recovery Strategies
- **Permission Recovery**: Re-request with better explanation
- **Scheduling Failures**: Retry logic with exponential backoff
- **Token Expiry**: Automatic FCM token refresh
- **Data Corruption**: Settings reset with user confirmation

## Testing Strategy

### Unit Tests
- Notification timing calculations
- Settings persistence and retrieval
- Permission state handling
- Time parsing and validation

### Integration Tests
- End-to-end notification delivery
- Firebase messaging integration
- WorkManager scheduling reliability
- Cross-platform consistency

### User Testing
- Permission flow usability
- Settings discoverability
- Notification timing accuracy
- Error state handling

## Performance Considerations

### Battery Optimization
- **Efficient Scheduling**: Minimal background processing
- **Batch Operations**: Group notification updates
- **Smart Triggers**: Only schedule when needed
- **Resource Management**: Clean up expired notifications

### Memory Usage
- **Lightweight Services**: Minimal service footprint
- **Data Efficiency**: Compact settings storage
- **Cache Management**: Optimal token and settings caching
- **Leak Prevention**: Proper resource cleanup

This implementation provides a complete, production-ready notification system that respects platform conventions while delivering a consistent user experience across iOS and Android platforms.