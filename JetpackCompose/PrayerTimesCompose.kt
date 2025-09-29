package com.centralmosque.rochdale.ui.prayer

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

// MARK: - Data Models
data class Prayer(
    val name: String,
    val startTime: String,
    val jamaaahTime: String
)

data class PrayerTimesState(
    val prayers: List<Prayer> = emptyList(),
    val isLoading: Boolean = false,
    val errorMessage: String? = null
)

// MARK: - Mock API Service
class PrayerTimesService {
    suspend fun fetchPrayerTimes(): List<Prayer> {
        // Simulate network delay
        delay(1000)
        
        return listOf(
            Prayer("Fajr", "05:30", "05:45"),
            Prayer("Dhuhr", "12:45", "13:00"),
            Prayer("Asr", "16:15", "16:30"),
            Prayer("Maghrib", "18:45", "18:50"),
            Prayer("Isha", "20:30", "20:45")
        )
    }
}

// MARK: - ViewModel
class PrayerTimesViewModel(
    private val service: PrayerTimesService = PrayerTimesService()
) : ViewModel() {
    
    private val _state = MutableStateFlow(PrayerTimesState())
    val state: StateFlow<PrayerTimesState> = _state.asStateFlow()
    
    fun fetchPrayerTimes() {
        viewModelScope.launch {
            _state.value = _state.value.copy(isLoading = true, errorMessage = null)
            
            try {
                val prayers = service.fetchPrayerTimes()
                _state.value = _state.value.copy(
                    prayers = prayers,
                    isLoading = false
                )
            } catch (e: Exception) {
                _state.value = _state.value.copy(
                    isLoading = false,
                    errorMessage = "Failed to load prayer times: ${e.message}"
                )
            }
        }
    }
}

// MARK: - Composables
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PrayerTimesScreen(
    viewModel: PrayerTimesViewModel = viewModel()
) {
    val state by viewModel.state.collectAsState()
    
    LaunchedEffect(Unit) {
        viewModel.fetchPrayerTimes()
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Prayer Times") }
            )
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            when {
                state.isLoading -> {
                    LoadingView()
                }
                
                state.errorMessage != null -> {
                    ErrorView(
                        message = state.errorMessage!!,
                        onRetry = { viewModel.fetchPrayerTimes() }
                    )
                }
                
                else -> {
                    PrayerTimesTable(
                        prayers = state.prayers,
                        modifier = Modifier.padding(16.dp)
                    )
                }
            }
        }
    }
}

@Composable
fun LoadingView() {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            CircularProgressIndicator()
            Spacer(modifier = Modifier.height(16.dp))
            Text("Loading prayer times...")
        }
    }
}

@Composable
fun ErrorView(
    message: String,
    onRetry: () -> Unit
) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                imageVector = Icons.Default.Warning,
                contentDescription = "Error",
                tint = MaterialTheme.colorScheme.error,
                modifier = Modifier.size(48.dp)
            )
            Spacer(modifier = Modifier.height(16.dp))
            Text(
                text = message,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )
            Spacer(modifier = Modifier.height(16.dp))
            Button(onClick = onRetry) {
                Text("Retry")
            }
        }
    }
}

@Composable
fun PrayerTimesTable(
    prayers: List<Prayer>,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier
            .fillMaxWidth()
            .shadow(4.dp, RoundedCornerShape(12.dp)),
        shape = RoundedCornerShape(12.dp)
    ) {
        Column {
            // Header
            PrayerTableHeader()
            
            // Prayer rows
            LazyColumn {
                items(prayers) { prayer ->
                    PrayerRow(prayer = prayer)
                    if (prayer != prayers.last()) {
                        HorizontalDivider()
                    }
                }
            }
        }
    }
}

@Composable
fun PrayerTableHeader() {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(MaterialTheme.colorScheme.surfaceVariant)
            .padding(16.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = "Prayer",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.weight(1f)
        )
        
        Text(
            text = "Start Time",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Center,
            modifier = Modifier.weight(1f)
        )
        
        Text(
            text = "Jamaa'ah",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.End,
            modifier = Modifier.weight(1f)
        )
    }
}

@Composable
fun PrayerRow(prayer: Prayer) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = prayer.name,
            style = MaterialTheme.typography.bodyLarge,
            fontWeight = FontWeight.Medium,
            modifier = Modifier.weight(1f)
        )
        
        Text(
            text = prayer.startTime,
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center,
            modifier = Modifier.weight(1f)
        )
        
        Text(
            text = prayer.jamaaahTime,
            style = MaterialTheme.typography.bodyLarge,
            fontWeight = FontWeight.SemiBold,
            textAlign = TextAlign.End,
            modifier = Modifier.weight(1f)
        )
    }
}

// MARK: - Preview
@Preview(showBackground = true)
@Composable
fun PrayerTimesScreenPreview() {
    MaterialTheme {
        PrayerTimesScreen()
    }
}

@Preview(showBackground = true)
@Composable
fun PrayerTimesTablePreview() {
    val samplePrayers = listOf(
        Prayer("Fajr", "05:30", "05:45"),
        Prayer("Dhuhr", "12:45", "13:00"),
        Prayer("Asr", "16:15", "16:30"),
        Prayer("Maghrib", "18:45", "18:50"),
        Prayer("Isha", "20:30", "20:45")
    )
    
    MaterialTheme {
        PrayerTimesTable(
            prayers = samplePrayers,
            modifier = Modifier.padding(16.dp)
        )
    }
}