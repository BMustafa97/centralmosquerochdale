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
    
    // Mecca coordinates
    private let meccaCoordinate = CLLocationCoordinate2D(latitude: 21.4225, longitude: 39.8262)
    
    override init() {
        super.init()
        setupLocationManager()
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
                    ErrorView(message: errorMessage) {
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
    
    var qiblaDirection: Double {
        guard let direction = locationManager.calculateQiblaDirection() else { return 0 }
        return direction - locationManager.heading
    }
    
    var body: some View {
        VStack(spacing: 30) {
            // Location Info
            LocationInfoView(location: locationManager.location)
            
            // Compass
            ZStack {
                // Compass Background
                CompassBackgroundView()
                
                // Qibla Needle
                QiblaNeedleView()
                    .rotationEffect(.degrees(qiblaDirection))
                    .animation(.easeInOut(duration: 0.5), value: qiblaDirection)
                
                // Center Dot
                Circle()
                    .fill(Color.primary)
                    .frame(width: 8, height: 8)
            }
            .frame(width: 280, height: 280)
            
            // Direction Info
            DirectionInfoView(
                qiblaDirection: locationManager.calculateQiblaDirection(),
                currentHeading: locationManager.heading
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
            
            Text("Point your device toward the green needle to face Qibla")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
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

struct ErrorView: View {
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