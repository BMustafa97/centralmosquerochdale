import SwiftUI
import CoreLocation
import Combine

// MARK: - Location Manager
class QiblaLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    @Published var location: CLLocation?
    @Published var heading: CLLocationDirection = 0
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLocationEnabled = false
    @Published var errorMessage: String?
    
    // Kaaba coordinates (exact location in Makkah)
    private let meccaCoordinate = CLLocationCoordinate2D(latitude: 21.4225, longitude: 39.8262)
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    // Calculate distance to Makkah in kilometers
    func calculateDistanceToMakkah() -> Double? {
        guard let currentLocation = location else { return nil }
        let meccaLocation = CLLocation(latitude: meccaCoordinate.latitude, longitude: meccaCoordinate.longitude)
        let distanceInMeters = currentLocation.distance(from: meccaLocation)
        return distanceInMeters / 1000.0 // Convert to kilometers
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
        
        // Request permission
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startLocationUpdates() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            errorMessage = "Location permission is required to determine Qibla direction"
            return
        }
        
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        isLocationEnabled = true
        errorMessage = nil
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
        isLocationEnabled = false
    }
    
    // Calculate Qibla direction (bearing to Mecca)
    func calculateQiblaDirection() -> CLLocationDirection? {
        guard let currentLocation = location else { return nil }
        
        let lat1 = currentLocation.coordinate.latitude * .pi / 180
        let lon1 = currentLocation.coordinate.longitude * .pi / 180
        let lat2 = meccaCoordinate.latitude * .pi / 180
        let lon2 = meccaCoordinate.longitude * .pi / 180
        
        let deltaLon = lon2 - lon1
        
        let y = sin(deltaLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)
        
        let bearing = atan2(y, x) * 180 / .pi
        return (bearing + 360).truncatingRemainder(dividingBy: 360)
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        location = newLocation
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        heading = newHeading.magneticHeading
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        case .denied, .restricted:
            errorMessage = "Location access denied. Please enable location services in Settings."
            isLocationEnabled = false
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = "Location error: \(error.localizedDescription)"
    }
}

// MARK: - Qibla Compass View
struct QiblaCompassView: View {
    @StateObject private var locationManager = QiblaLocationManager()
    @State private var compassRotation: Double = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                if let errorMessage = locationManager.errorMessage {
                    QiblaErrorView(message: errorMessage) {
                        locationManager.startLocationUpdates()
                    }
                } else if locationManager.location == nil {
                    LoadingView()
                } else {
                    QiblaCompassContent(
                        locationManager: locationManager,
                        compassRotation: $compassRotation
                    )
                }
            }
            .padding()
            .navigationTitle("Qibla Compass")
            .onAppear {
                locationManager.startLocationUpdates()
            }
            .onDisappear {
                locationManager.stopLocationUpdates()
            }
        }
    }
}

struct QiblaCompassContent: View {
    @ObservedObject var locationManager: QiblaLocationManager
    @Binding var compassRotation: Double
    
    // Rotation needed to align compass so that user's heading is at bottom
    // and Qibla direction is at top
    var compassRotationAngle: Double {
        // Rotate the compass based on device heading
        return -locationManager.heading
    }
    
    // Calculate if user is aligned with Qibla (within tolerance)
    var isAlignedWithQibla: Bool {
        guard let qiblaDir = locationManager.calculateQiblaDirection() else { return false }
        let difference = abs(qiblaDir - locationManager.heading)
        let normalizedDiff = min(difference, 360 - difference)
        return normalizedDiff < 15 // Within 15 degrees is considered aligned
    }
    
    var body: some View {
        VStack(spacing: 30) {
            // Location Info
            LocationInfoView(location: locationManager.location)
            
            // Instructions
            VStack(spacing: 8) {
                Image(systemName: isAlignedWithQibla ? "checkmark.circle.fill" : "arrow.up.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(isAlignedWithQibla ? .green : .blue)
                    .animation(.easeInOut, value: isAlignedWithQibla)
                
                Text(isAlignedWithQibla ? "Aligned with Qibla!" : "Rotate to face Qibla")
                    .font(.headline)
                    .foregroundColor(isAlignedWithQibla ? .green : .primary)
                
                Text("The green arrow at the top points to Mecca")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(isAlignedWithQibla ? Color.green.opacity(0.1) : Color.blue.opacity(0.05))
            .cornerRadius(12)
            
            // Compass with fixed Qibla at top
            ZStack {
                // Compass Background that rotates with device heading
                CompassBackgroundView()
                    .rotationEffect(.degrees(compassRotationAngle))
                    .animation(.easeInOut(duration: 0.3), value: compassRotationAngle)
                
                // Fixed Qibla indicator at top (north)
                QiblaIndicatorView()
                    .rotationEffect(.degrees(locationManager.calculateQiblaDirection() ?? 0))
                    .rotationEffect(.degrees(compassRotationAngle))
                    .animation(.easeInOut(duration: 0.3), value: compassRotationAngle)
                
                // Device indicator (always at bottom - user's current direction)
                DeviceIndicatorView()
                
                // Center Kaaba icon
                Image(systemName: "house.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.green)
            }
            .frame(width: 280, height: 280)
            
            // Direction Info
            EnhancedDirectionInfoView(
                qiblaDirection: locationManager.calculateQiblaDirection(),
                currentHeading: locationManager.heading,
                isAligned: isAlignedWithQibla,
                distanceToMakkah: locationManager.calculateDistanceToMakkah()
            )
            
            Spacer()
        }
    }
}

struct CompassBackgroundView: View {
    var body: some View {
        ZStack {
            // Outer Circle
            Circle()
                .stroke(Color.primary.opacity(0.3), lineWidth: 2)
                .frame(width: 280, height: 280)
            
            // Inner Circle
            Circle()
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                .frame(width: 200, height: 200)
            
            // Cardinal Directions
            ForEach(0..<4) { index in
                VStack {
                    Text(["N", "E", "S", "W"][index])
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Spacer()
                }
                .frame(height: 140)
                .rotationEffect(.degrees(Double(index) * 90))
            }
            
            // Degree Markers
            ForEach(0..<36) { index in
                Rectangle()
                    .fill(Color.primary.opacity(0.6))
                    .frame(width: 2, height: index % 3 == 0 ? 20 : 10)
                    .offset(y: -130)
                    .rotationEffect(.degrees(Double(index) * 10))
            }
        }
    }
}

struct QiblaNeedleView: View {
    var body: some View {
        VStack {
            // Needle pointing to Qibla
            Triangle()
                .fill(
                    LinearGradient(
                        colors: [Color.green, Color.green.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 16, height: 80)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
            
            Spacer()
            
            // Counter needle
            Triangle()
                .fill(Color.red.opacity(0.8))
                .frame(width: 12, height: 40)
                .rotationEffect(.degrees(180))
        }
        .frame(height: 250)
    }
}

// Qibla indicator that stays fixed at top of screen
struct QiblaIndicatorView: View {
    var body: some View {
        VStack {
            // Large arrow pointing up (to Qibla/Mecca)
            ZStack {
                // Glow effect
                Triangle()
                    .fill(Color.green.opacity(0.3))
                    .frame(width: 30, height: 90)
                    .blur(radius: 5)
                
                Triangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.green, Color.green.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 20, height: 85)
                    .shadow(color: .green.opacity(0.5), radius: 3, x: 0, y: 0)
                
                // Kaaba icon at the tip
                Image(systemName: "figure.walk")
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                    .offset(y: -25)
            }
            
            Spacer()
        }
        .frame(height: 260)
    }
}

// Device indicator showing user's current direction (fixed at bottom)
struct DeviceIndicatorView: View {
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 4) {
                // Phone icon
                Image(systemName: "iphone")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                
                Text("YOU")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
        }
        .frame(height: 260)
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct LocationInfoView: View {
    let location: CLLocation?
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Current Location")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if let location = location {
                HStack(spacing: 20) {
                    VStack(alignment: .leading) {
                        Text("Latitude")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.4f°", location.coordinate.latitude))
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Longitude")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.4f°", location.coordinate.longitude))
                            .font(.body)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
}

struct DirectionInfoView: View {
    let qiblaDirection: Double?
    let currentHeading: Double
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 30) {
                VStack {
                    Text("Qibla Direction")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(qiblaDirection != nil ? String(format: "%.0f°", qiblaDirection!) : "N/A")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                VStack {
                    Text("Current Heading")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.0f°", currentHeading))
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
            
            Text("Point your device toward the needle to face Qibla")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
}

struct EnhancedDirectionInfoView: View {
    let qiblaDirection: Double?
    let currentHeading: Double
    let isAligned: Bool
    let distanceToMakkah: Double?
    
    var degreesToTurn: Double {
        guard let qiblaDir = qiblaDirection else { return 0 }
        let diff = qiblaDir - currentHeading
        // Normalize to -180 to 180 range
        if diff > 180 {
            return diff - 360
        } else if diff < -180 {
            return diff + 360
        }
        return diff
    }
    
    var turnDirection: String {
        if abs(degreesToTurn) < 15 {
            return "You're facing Qibla!"
        } else if degreesToTurn > 0 {
            return "Turn right \(Int(abs(degreesToTurn)))°"
        } else {
            return "Turn left \(Int(abs(degreesToTurn)))°"
        }
    }
    
    var formattedDistance: String {
        guard let distance = distanceToMakkah else { return "Calculating..." }
        if distance > 1000 {
            return String(format: "%.0f km", distance)
        } else {
            return String(format: "%.1f km", distance)
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Turn instruction
            HStack {
                if !isAligned {
                    Image(systemName: degreesToTurn > 0 ? "arrow.turn.up.right" : "arrow.turn.up.left")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                Text(turnDirection)
                    .font(.headline)
                    .foregroundColor(isAligned ? .green : .blue)
                    .fontWeight(.semibold)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(isAligned ? Color.green.opacity(0.15) : Color.blue.opacity(0.1))
            .cornerRadius(12)
            
            // Detailed info
            HStack(spacing: 30) {
                VStack {
                    Text("Qibla")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(qiblaDirection != nil ? String(format: "%.0f°", qiblaDirection!) : "N/A")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                VStack {
                    Text("You")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.0f°", currentHeading))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                VStack {
                    Text("Distance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formattedDistance)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Getting your location...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct QiblaErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "location.slash")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                onRetry()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview
struct QiblaCompassView_Previews: PreviewProvider {
    static var previews: some View {
        QiblaCompassView()
    }
}