package com.centralmosque.rochdale.ui.qibla

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.LocationOff
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlin.math.*

// MARK: - Data Models
data class QiblaState(
    val currentLocation: Location? = null,
    val currentHeading: Float = 0f,
    val qiblaDirection: Float = 0f,
    val isLocationEnabled: Boolean = false,
    val hasLocationPermission: Boolean = false,
    val isLoading: Boolean = true,
    val errorMessage: String? = null
)

// MARK: - Location and Sensor Manager
class QiblaManager(private val context: Context) : SensorEventListener, LocationListener {
    private val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
    private val sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    
    private val accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
    private val magnetometer = sensorManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD)
    
    private var gravity = FloatArray(3)
    private var geomagnetic = FloatArray(3)
    private var rotationMatrix = FloatArray(9)
    private var orientation = FloatArray(3)
    
    // Mecca coordinates
    private val meccaLatitude = 21.4225
    private val meccaLongitude = 39.8262
    
    var onStateChanged: ((QiblaState) -> Unit)? = null
    private var currentState = QiblaState()
    
    fun startListening() {
        if (hasLocationPermission()) {
            startLocationUpdates()
            startSensorUpdates()
            updateState(currentState.copy(hasLocationPermission = true))
        } else {
            updateState(currentState.copy(
                hasLocationPermission = false,
                errorMessage = "Location permission is required"
            ))
        }
    }
    
    fun stopListening() {
        locationManager.removeUpdates(this)
        sensorManager.unregisterListener(this)
    }
    
    private fun hasLocationPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
    }
    
    private fun startLocationUpdates() {
        try {
            locationManager.requestLocationUpdates(
                LocationManager.GPS_PROVIDER,
                1000L, // 1 second
                10f,   // 10 meters
                this
            )
            
            // Also try network provider as backup
            locationManager.requestLocationUpdates(
                LocationManager.NETWORK_PROVIDER,
                1000L,
                10f,
                this
            )
            
            updateState(currentState.copy(isLocationEnabled = true))
        } catch (e: SecurityException) {
            updateState(currentState.copy(
                errorMessage = "Location permission denied",
                isLocationEnabled = false
            ))
        }
    }
    
    private fun startSensorUpdates() {
        accelerometer?.let {
            sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_UI)
        }
        magnetometer?.let {
            sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_UI)
        }
    }
    
    private fun calculateQiblaDirection(currentLocation: Location): Float {
        val lat1 = Math.toRadians(currentLocation.latitude)
        val lon1 = Math.toRadians(currentLocation.longitude)
        val lat2 = Math.toRadians(meccaLatitude)
        val lon2 = Math.toRadians(meccaLongitude)
        
        val deltaLon = lon2 - lon1
        
        val y = sin(deltaLon) * cos(lat2)
        val x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)
        
        val bearing = Math.toDegrees(atan2(y, x))
        return ((bearing + 360) % 360).toFloat()
    }
    
    private fun updateState(newState: QiblaState) {
        currentState = newState
        onStateChanged?.invoke(currentState)
    }
    
    // LocationListener implementation
    override fun onLocationChanged(location: Location) {
        val qiblaDirection = calculateQiblaDirection(location)
        updateState(currentState.copy(
            currentLocation = location,
            qiblaDirection = qiblaDirection,
            isLoading = false,
            errorMessage = null
        ))
    }
    
    override fun onProviderEnabled(provider: String) {
        updateState(currentState.copy(isLocationEnabled = true))
    }
    
    override fun onProviderDisabled(provider: String) {
        updateState(currentState.copy(
            isLocationEnabled = false,
            errorMessage = "Please enable GPS in your device settings"
        ))
    }
    
    // SensorEventListener implementation
    override fun onSensorChanged(event: SensorEvent) {
        when (event.sensor.type) {
            Sensor.TYPE_ACCELEROMETER -> {
                gravity = event.values.clone()
            }
            Sensor.TYPE_MAGNETIC_FIELD -> {
                geomagnetic = event.values.clone()
            }
        }
        
        if (gravity.isNotEmpty() && geomagnetic.isNotEmpty()) {
            val success = SensorManager.getRotationMatrix(rotationMatrix, null, gravity, geomagnetic)
            if (success) {
                SensorManager.getOrientation(rotationMatrix, orientation)
                val azimuth = Math.toDegrees(orientation[0].toDouble()).toFloat()
                val heading = (azimuth + 360) % 360
                
                updateState(currentState.copy(currentHeading = heading))
            }
        }
    }
    
    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        // Handle accuracy changes if needed
    }
}

// MARK: - ViewModel
class QiblaViewModel(private val context: Context) : ViewModel() {
    private val qiblaManager = QiblaManager(context)
    
    private val _state = MutableStateFlow(QiblaState())
    val state: StateFlow<QiblaState> = _state.asStateFlow()
    
    init {
        qiblaManager.onStateChanged = { newState ->
            viewModelScope.launch {
                _state.value = newState
            }
        }
    }
    
    fun startQiblaTracking() {
        qiblaManager.startListening()
    }
    
    fun stopQiblaTracking() {
        qiblaManager.stopListening()
    }
    
    override fun onCleared() {
        super.onCleared()
        qiblaManager.stopListening()
    }
}

// MARK: - Composables
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun QiblaCompassScreen(
    viewModel: QiblaViewModel = viewModel { QiblaViewModel(LocalContext.current) }
) {
    val context = LocalContext.current
    val state by viewModel.state.collectAsState()
    
    val permissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        if (isGranted) {
            viewModel.startQiblaTracking()
        }
    }
    
    LaunchedEffect(Unit) {
        if (ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.ACCESS_FINE_LOCATION
            ) == PackageManager.PERMISSION_GRANTED
        ) {
            viewModel.startQiblaTracking()
        } else {
            permissionLauncher.launch(Manifest.permission.ACCESS_FINE_LOCATION)
        }
    }
    
    DisposableEffect(Unit) {
        onDispose {
            viewModel.stopQiblaTracking()
        }
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Qibla Compass") }
            )
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(16.dp)
        ) {
            when {
                !state.hasLocationPermission -> {
                    PermissionRequestView {
                        permissionLauncher.launch(Manifest.permission.ACCESS_FINE_LOCATION)
                    }
                }
                
                state.isLoading || state.currentLocation == null -> {
                    LoadingView()
                }
                
                state.errorMessage != null -> {
                    ErrorView(state.errorMessage!!) {
                        viewModel.startQiblaTracking()
                    }
                }
                
                else -> {
                    QiblaCompassContent(state = state)
                }
            }
        }
    }
}

@Composable
fun QiblaCompassContent(state: QiblaState) {
    val needleRotation by animateFloatAsState(
        targetValue = state.qiblaDirection - state.currentHeading,
        animationSpec = tween(durationMillis = 300),
        label = "needle_rotation"
    )
    
    Column(
        modifier = Modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(24.dp)
    ) {
        // Location Info
        LocationInfoCard(location = state.currentLocation)
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // Compass
        Box(
            modifier = Modifier.size(300.dp),
            contentAlignment = Alignment.Center
        ) {
            // Compass Background
            CompassBackground()
            
            // Qibla Needle
            QiblaNeedle(
                modifier = Modifier.rotate(needleRotation)
            )
            
            // Center dot
            Box(
                modifier = Modifier
                    .size(12.dp)
                    .background(
                        color = MaterialTheme.colorScheme.primary,
                        shape = CircleShape
                    )
            )
        }
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // Direction Info
        DirectionInfoCard(
            qiblaDirection = state.qiblaDirection,
            currentHeading = state.currentHeading
        )
        
        // Instruction Text
        Text(
            text = "Point your device toward the green needle to face Qibla",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = 32.dp)
        )
    }
}

@Composable
fun CompassBackground() {
    Canvas(modifier = Modifier.size(300.dp)) {
        val center = Offset(size.width / 2, size.height / 2)
        val radius = size.width / 2 - 20.dp.toPx()
        
        // Outer circle
        drawCircle(
            color = Color.Gray.copy(alpha = 0.3f),
            radius = radius,
            center = center,
            style = Stroke(width = 2.dp.toPx())
        )
        
        // Inner circle
        drawCircle(
            color = Color.Gray.copy(alpha = 0.1f),
            radius = radius * 0.7f,
            center = center,
            style = Stroke(width = 1.dp.toPx())
        )
        
        // Cardinal directions and degree markers
        drawCompassMarkers(center, radius)
    }
}

private fun DrawScope.drawCompassMarkers(center: Offset, radius: Float) {
    val cardinalDirections = listOf("N", "E", "S", "W")
    
    // Draw degree markers
    for (i in 0 until 36) {
        val angle = i * 10f
        val isCardinal = i % 9 == 0
        val lineLength = if (isCardinal) 30.dp.toPx() else 15.dp.toPx()
        val lineWidth = if (isCardinal) 3.dp.toPx() else 1.dp.toPx()
        
        val startRadius = radius - lineLength
        val endRadius = radius
        
        val angleRad = Math.toRadians((angle - 90).toDouble())
        val startX = center.x + startRadius * cos(angleRad).toFloat()
        val startY = center.y + startRadius * sin(angleRad).toFloat()
        val endX = center.x + endRadius * cos(angleRad).toFloat()
        val endY = center.y + endRadius * sin(angleRad).toFloat()
        
        drawLine(
            color = Color.Gray.copy(alpha = 0.6f),
            start = Offset(startX, startY),
            end = Offset(endX, endY),
            strokeWidth = lineWidth
        )
    }
}

@Composable
fun QiblaNeedle(modifier: Modifier = Modifier) {
    Canvas(
        modifier = modifier.size(280.dp)
    ) {
        val center = Offset(size.width / 2, size.height / 2)
        val needleLength = size.height / 2 - 40.dp.toPx()
        
        // Main needle (pointing to Qibla)
        val needlePath = Path().apply {
            moveTo(center.x, center.y - needleLength)
            lineTo(center.x - 12.dp.toPx(), center.y - 20.dp.toPx())
            lineTo(center.x + 12.dp.toPx(), center.y - 20.dp.toPx())
            close()
        }
        
        drawPath(
            path = needlePath,
            color = Color.Green
        )
        
        // Counter needle
        val counterNeedlePath = Path().apply {
            moveTo(center.x, center.y + needleLength / 2)
            lineTo(center.x - 8.dp.toPx(), center.y + 20.dp.toPx())
            lineTo(center.x + 8.dp.toPx(), center.y + 20.dp.toPx())
            close()
        }
        
        drawPath(
            path = counterNeedlePath,
            color = Color.Red.copy(alpha = 0.8f)
        )
    }
}

@Composable
fun LocationInfoCard(location: Location?) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = "Current Location",
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            if (location != null) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceEvenly
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(
                            text = "Latitude",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Text(
                            text = String.format("%.4f°", location.latitude),
                            style = MaterialTheme.typography.bodyLarge,
                            fontWeight = FontWeight.Medium
                        )
                    }
                    
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(
                            text = "Longitude",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Text(
                            text = String.format("%.4f°", location.longitude),
                            style = MaterialTheme.typography.bodyLarge,
                            fontWeight = FontWeight.Medium
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun DirectionInfoCard(qiblaDirection: Float, currentHeading: Float) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(
                        text = "Qibla Direction",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = "${qiblaDirection.toInt()}°",
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = FontWeight.Bold,
                        color = Color.Green
                    )
                }
                
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(
                        text = "Current Heading",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = "${currentHeading.toInt()}°",
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
        }
    }
}

@Composable
fun LoadingView() {
    Column(
        modifier = Modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        CircularProgressIndicator(modifier = Modifier.size(48.dp))
        Spacer(modifier = Modifier.height(16.dp))
        Text(
            text = "Getting your location...",
            style = MaterialTheme.typography.headlineSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
fun ErrorView(message: String, onRetry: () -> Unit) {
    Column(
        modifier = Modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            imageVector = Icons.Default.LocationOff,
            contentDescription = "Location Error",
            tint = MaterialTheme.colorScheme.error,
            modifier = Modifier.size(64.dp)
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        Text(
            text = message,
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        Button(onClick = onRetry) {
            Text("Retry")
        }
    }
}

@Composable
fun PermissionRequestView(onRequestPermission: () -> Unit) {
    Column(
        modifier = Modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            imageVector = Icons.Default.LocationOff,
            contentDescription = "Location Permission",
            tint = MaterialTheme.colorScheme.primary,
            modifier = Modifier.size(64.dp)
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        Text(
            text = "Location Permission Required",
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold
        )
        
        Spacer(modifier = Modifier.height(8.dp))
        
        Text(
            text = "This app needs location permission to determine the Qibla direction",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = 32.dp)
        )
        
        Spacer(modifier = Modifier.height(24.dp))
        
        Button(onClick = onRequestPermission) {
            Text("Grant Permission")
        }
    }
}

// MARK: - Preview
@Preview(showBackground = true)
@Composable
fun QiblaCompassScreenPreview() {
    MaterialTheme {
        QiblaCompassScreen()
    }
}