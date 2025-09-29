🔧 Core Features
1. Prayer Times Table

"Generate SwiftUI and Jetpack Compose code to display a table with five daily prayers. Each row should show the prayer name, start time, and Jamaa'ah time. Data should be fetched from a mock API."

2. Qibla Finder

"Create a Qibla compass using device orientation and location. Use CoreLocation (iOS) and LocationManager (Android). Show a compass needle pointing toward Mecca."

3. Push Notifications

"Implement push notification toggles for each prayer. Users should be able to choose alerts at 5, 10, or 15 minutes before Jamaa'ah time. Use Firebase for Android and APNs for iOS."

4. Event Notifications

"Add a feature to send push notifications for mosque events. Admins should be able to create events via a backend API, and users should receive alerts if subscribed."


🧪 Backend & API
5. Prayer Times API

"Design a REST API that returns prayer times and Jamaa'ah times for a mosque. Include endpoints for today’s schedule, weekly schedule, and event announcements."

6. User Preferences

"Create a backend model and API for storing user preferences: notification toggles, alert timing, and location."


🧭 Location & Qibla
7. Qibla Calculation

"Write a function that calculates the Qibla direction from any latitude/longitude using the great-circle formula."


🧱 Architecture & State Management
8. MVVM Setup

"Set up MVVM architecture for a prayer times screen in SwiftUI. Include ViewModel with Combine, and mock data service."

9. Clean Architecture Example

"Show how to structure a Clean Architecture app for prayer times, with domain, data, and presentation layers."


🧪 Testing
10. Unit Tests

"Write unit tests for the Qibla calculation function and prayer time notification scheduler."