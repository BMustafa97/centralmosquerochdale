# Qibla Compass - SwiftUI & Jetpack Compose

A Qibla compass implementation for both iOS (SwiftUI) and Android (Jetpack Compose) that uses device location and orientation sensors to point toward Mecca (Kaaba) for Islamic prayers.

## Features

- **Accurate Qibla Direction**: Calculates the precise bearing to Mecca from user's current location
- **Real-time Compass**: Uses device magnetometer and accelerometer for live orientation updates
- **Location Services**: Integrates with CoreLocation (iOS) and LocationManager (Android)
- **Beautiful UI**: Native compass designs with animated needle and cardinal directions
- **Permission Handling**: Proper location permission requests and error states
- **Offline Calculation**: Works without internet once location is obtained

## How It Works

### Qibla Calculation
The Qibla direction is calculated using the great-circle bearing formula:
```
θ = atan2(sin(Δlong).cos(lat2), cos(lat1).sin(lat2) − sin(lat1).cos(lat2).cos(Δlong))
```

Where:
- `lat1, long1` = User's current location
- `lat2, long2` = Mecca coordinates (21.4225°N, 39.8262°E)
- `θ` = Bearing angle from North

## SwiftUI Implementation

### Key Components

#### `QiblaLocationManager`
- Manages CoreLocation services and device heading
- Implements `CLLocationManagerDelegate` for location updates
- Uses `CLHeading` for magnetic compass readings
- Calculates Qibla direction using great-circle formula

#### Location Services
```swift
locationManager.requestWhenInUseAuthorization()
locationManager.startUpdatingLocation()
locationManager.startUpdatingHeading()
```

#### UI Components
- **`QiblaCompassView`**: Main navigation view with state management
- **`CompassBackgroundView`**: Circular compass with cardinal directions and degree markers
- **`QiblaNeedleView`**: Animated needle pointing to Qibla (green) with counter-needle (red)
- **`LocationInfoView`**: Displays current latitude/longitude
- **`DirectionInfoView`**: Shows Qibla bearing and current device heading

### Required Permissions (Info.plist)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to determine Qibla direction for prayer</string>
```

## Jetpack Compose Implementation

### Key Components

#### `QiblaManager`
- Implements `SensorEventListener` for accelerometer and magnetometer
- Implements `LocationListener` for GPS updates
- Combines sensor data to calculate device orientation
- Uses `SensorManager.getRotationMatrix()` for accurate heading

#### Location & Sensor Services
```kotlin
// Location
locationManager.requestLocationUpdates(LocationManager.GPS_PROVIDER, 1000L, 10f, this)

// Sensors
sensorManager.registerListener(this, accelerometer, SensorManager.SENSOR_DELAY_UI)
sensorManager.registerListener(this, magnetometer, SensorManager.SENSOR_DELAY_UI)
```

#### UI Components
- **`QiblaCompassScreen`**: Main screen with Scaffold and permission handling
- **`CompassBackground`**: Canvas-drawn compass with markers and cardinal directions
- **`QiblaNeedle`**: Custom Canvas needle with smooth animations
- **`LocationInfoCard`**: Material Design card showing coordinates
- **`DirectionInfoCard`**: Displays bearing information

### Required Permissions (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

## Architecture Patterns

### SwiftUI (MVVM)
- `@StateObject` and `@Published` for reactive state management
- `ObservableObject` pattern for location manager
- Combine framework for data flow

### Jetpack Compose (MVVM)
- `StateFlow` and `collectAsState()` for state management
- ViewModel with lifecycle awareness
- Coroutines for background operations

## Usage Examples

### SwiftUI Integration
```swift
struct ContentView: View {
    var body: some View {
        TabView {
            PrayerTimesView()
                .tabItem {
                    Image(systemName: "clock")
                    Text("Prayer Times")
                }
            
            QiblaCompassView()
                .tabItem {
                    Image(systemName: "location.north")
                    Text("Qibla")
                }
        }
    }
}
```

### Jetpack Compose Integration
```kotlin
@Composable
fun MainScreen() {
    var selectedTab by remember { mutableStateOf(0) }
    
    Scaffold(
        bottomBar = {
            NavigationBar {
                NavigationBarItem(
                    selected = selectedTab == 0,
                    onClick = { selectedTab = 0 },
                    icon = { Icon(Icons.Default.Schedule, "Prayer Times") },
                    label = { Text("Prayer Times") }
                )
                NavigationBarItem(
                    selected = selectedTab == 1,
                    onClick = { selectedTab = 1 },
                    icon = { Icon(Icons.Default.Navigation, "Qibla") },
                    label = { Text("Qibla") }
                )
            }
        }
    ) { paddingValues ->
        when (selectedTab) {
            0 -> PrayerTimesScreen()
            1 -> QiblaCompassScreen()
        }
    }
}
```

## Error Handling

Both implementations handle common scenarios:

### Permission States
- **Not Determined**: Request permission from user
- **Denied**: Show error message with settings redirect
- **Authorized**: Start location and sensor updates

### Location Issues
- **GPS Disabled**: Prompt user to enable location services
- **No Location**: Show loading state until location is acquired
- **Location Errors**: Display specific error messages

### Sensor Issues
- **No Magnetometer**: Fallback to basic compass functionality
- **Sensor Accuracy**: Handle low accuracy readings gracefully

## Accuracy Considerations

### Factors Affecting Accuracy
1. **Magnetic Declination**: Device automatically accounts for magnetic vs. true north
2. **Device Calibration**: Users should calibrate compass by moving device in figure-8 pattern
3. **Magnetic Interference**: Metal objects and electronics can affect readings
4. **Location Accuracy**: GPS accuracy affects Qibla calculation precision

### Improving Accuracy
- Use high-accuracy location settings
- Implement sensor fusion algorithms
- Regular compass calibration prompts
- Filter out erratic sensor readings

## Customization Options

### Visual Styling
- Compass colors and themes
- Needle designs and animations
- Background patterns and markers
- Typography and spacing

### Functional Features
- Multiple calculation methods (great circle vs. rhumb line)
- Prayer time integration
- Night mode support
- Haptic feedback for accurate alignment

## Future Enhancements

- **Augmented Reality**: AR view showing Qibla direction overlay
- **Multiple Calculation Methods**: Support for different madhabs
- **Offline Maps**: Show Mecca direction on satellite imagery
- **Prayer Reminders**: Integration with prayer time notifications
- **Calibration Wizard**: Guide users through compass calibration
- **Travel Mode**: Remember Qibla for different cities

## Technical Requirements

### iOS
- iOS 14.0+
- CoreLocation framework
- Device with magnetometer (all modern iOS devices)

### Android
- Android API 21+
- Location services enabled
- Magnetometer and accelerometer sensors
- Runtime permissions handling

Both implementations provide accurate, reliable Qibla direction calculation with beautiful, native user interfaces optimized for their respective platforms.