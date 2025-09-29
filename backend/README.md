# User Preferences Backend API

This backend service manages user preferences for the Central Mosque Rochdale app, including notification settings, alert timing, and location data.

## 🚀 Quick Start

```bash
# Install dependencies
npm install

# Set up environment
cp .env.example .env
# Edit .env with your MongoDB connection string

# Start development server
npm run dev

# Start production server
npm start
```

## 📡 API Endpoints

### User Preferences

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/users/:userId/preferences` | Get user preferences |
| PUT | `/api/users/:userId/preferences` | Update user preferences |
| POST | `/api/users/:userId/preferences` | Create user preferences |
| DELETE | `/api/users/:userId/preferences` | Reset preferences to default |

### Prayer Notifications

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/users/:userId/notifications` | Get notification settings |
| PUT | `/api/users/:userId/notifications` | Update notification settings |
| POST | `/api/users/:userId/notifications/test` | Send test notification |

### Location Services

| Method | Endpoint | Description |
|--------|----------|-------------|
| PUT | `/api/users/:userId/location` | Update user location |
| GET | `/api/users/:userId/location` | Get user location |
| GET | `/api/users/:userId/prayer-times` | Get prayer times for user location |

## 📊 Data Models

### User Preferences Schema
```json
{
  "userId": "string",
  "notifications": {
    "fajr": { "enabled": true, "alertMinutes": 10 },
    "dhuhr": { "enabled": true, "alertMinutes": 15 },
    "asr": { "enabled": false, "alertMinutes": 5 },
    "maghrib": { "enabled": true, "alertMinutes": 10 },
    "isha": { "enabled": true, "alertMinutes": 15 }
  },
  "location": {
    "latitude": 53.6158,
    "longitude": -2.1561,
    "city": "Rochdale",
    "country": "UK",
    "timezone": "Europe/London"
  },
  "deviceTokens": {
    "ios": "string",
    "android": "string"
  },
  "preferences": {
    "language": "en",
    "theme": "light",
    "soundEnabled": true,
    "vibrationEnabled": true
  },
  "createdAt": "2025-09-29T22:00:00Z",
  "updatedAt": "2025-09-29T22:00:00Z"
}
```

## 🔧 Environment Variables

```env
NODE_ENV=development
PORT=3000
MONGODB_URI=mongodb://localhost:27017/mosque-app
JWT_SECRET=your-jwt-secret
FIREBASE_PROJECT_ID=your-firebase-project
APNS_KEY_ID=your-apns-key-id
APNS_TEAM_ID=your-team-id
```

## 📱 Integration Examples

### iOS Swift
```swift
let preferences = UserPreferences(
    notifications: [
        "fajr": NotificationSetting(enabled: true, alertMinutes: 10)
    ],
    location: Location(latitude: 53.6158, longitude: -2.1561)
)
```

### Android Kotlin
```kotlin
val preferences = UserPreferences(
    notifications = mapOf(
        "fajr" to NotificationSetting(enabled = true, alertMinutes = 10)
    ),
    location = Location(latitude = 53.6158, longitude = -2.1561)
)
```