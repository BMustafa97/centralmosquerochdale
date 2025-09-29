package com.centralmosque.rochdale.ui.events

import android.content.Context
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import com.google.firebase.messaging.FirebaseMessaging
import com.google.firebase.messaging.RemoteMessage
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import java.io.IOException
import java.text.SimpleDateFormat
import java.util.*

// MARK: - Data Models
data class MosqueEvent(
    val id: String,
    val title: String,
    val description: String,
    val startDate: Date,
    val endDate: Date? = null,
    val category: EventCategory,
    val location: String,
    val organizer: String,
    val isImportant: Boolean = false,
    val imageURL: String? = null,
    val maxAttendees: Int? = null,
    val currentAttendees: Int = 0,
    val requiresRegistration: Boolean = false,
    val createdAt: Date = Date(),
    val updatedAt: Date = Date()
)

enum class EventCategory(
    val displayName: String,
    val icon: ImageVector,
    val color: Color
) {
    LECTURE("Islamic Lectures", Icons.Default.MenuBook, Color(0xFF2196F3)),
    FUNDRAISING("Fundraising", Icons.Default.AttachMoney, Color(0xFF4CAF50)),
    COMMUNITY("Community Events", Icons.Default.Groups, Color(0xFFFF9800)),
    EDUCATION("Educational", Icons.Default.School, Color(0xFF9C27B0)),
    RELIGIOUS("Religious", Icons.Default.Star, Color(0xFF3F51B5)),
    YOUTH("Youth Programs", Icons.Default.ChildCare, Color(0xFFE91E63)),
    CHARITY("Charity Work", Icons.Default.Favorite, Color(0xFFF44336)),
    ANNOUNCEMENT("Announcements", Icons.Default.Campaign, Color(0xFFFFEB3B))
}

data class EventSubscription(
    val userId: String,
    val subscribedCategories: Set<EventCategory> = EventCategory.values().toSet(),
    val notifyBeforeMinutes: Int = 30,
    val isEnabled: Boolean = true,
    val lastUpdated: Date = Date()
)

data class CreateEventRequest(
    val title: String,
    val description: String,
    val startDate: Date,
    val endDate: Date? = null,
    val category: EventCategory,
    val location: String,
    val organizer: String,
    val isImportant: Boolean = false,
    val imageURL: String? = null,
    val maxAttendees: Int? = null,
    val requiresRegistration: Boolean = false
)

data class EventsState(
    val events: List<MosqueEvent> = emptyList(),
    val filteredEvents: List<MosqueEvent> = emptyList(),
    val selectedCategory: EventCategory? = null,
    val userSubscriptions: EventSubscription? = null,
    val isLoading: Boolean = false,
    val isCreatingEvent: Boolean = false,
    val errorMessage: String? = null,
    val fcmToken: String? = null
)

// MARK: - Event API Service
class EventAPIService(private val context: Context) {
    private val baseURL = "https://api.centralmosquerochdale.org"
    private val client = OkHttpClient()
    private val mediaType = "application/json; charset=utf-8".toMediaType()
    
    suspend fun fetchEvents(): List<MosqueEvent> {
        return try {
            val request = Request.Builder()
                .url("$baseURL/api/events")
                .build()
            
            val response = client.newCall(request).execute()
            if (response.isSuccessful) {
                // Parse JSON response to List<MosqueEvent>
                // This would typically use Gson or kotlinx.serialization
                mockEvents() // For now, return mock data
            } else {
                throw IOException("Server error: ${response.code}")
            }
        } catch (e: Exception) {
            throw e
        }
    }
    
    suspend fun createEvent(request: CreateEventRequest, adminToken: String): MosqueEvent {
        return try {
            val json = """
                {
                    "title": "${request.title}",
                    "description": "${request.description}",
                    "category": "${request.category.name}",
                    "location": "${request.location}",
                    "organizer": "${request.organizer}",
                    "isImportant": ${request.isImportant},
                    "requiresRegistration": ${request.requiresRegistration}
                }
            """.trimIndent()
            
            val body = json.toRequestBody(mediaType)
            val httpRequest = Request.Builder()
                .url("$baseURL/api/admin/events")
                .header("Authorization", "Bearer $adminToken")
                .post(body)
                .build()
            
            val response = client.newCall(httpRequest).execute()
            if (response.isSuccessful) {
                // Parse response to MosqueEvent
                // Return mock event for now
                MosqueEvent(
                    id = UUID.randomUUID().toString(),
                    title = request.title,
                    description = request.description,
                    startDate = request.startDate,
                    endDate = request.endDate,
                    category = request.category,
                    location = request.location,
                    organizer = request.organizer,
                    isImportant = request.isImportant,
                    imageURL = request.imageURL,
                    maxAttendees = request.maxAttendees,
                    requiresRegistration = request.requiresRegistration
                )
            } else {
                throw IOException("Failed to create event: ${response.code}")
            }
        } catch (e: Exception) {
            throw e
        }
    }
    
    suspend fun updateSubscriptions(subscription: EventSubscription): Boolean {
        return try {
            // API call to update user subscriptions
            // Return true for success
            true
        } catch (e: Exception) {
            false
        }
    }
    
    suspend fun registerForEvent(eventId: String, userId: String): Boolean {
        return try {
            val json = """{"userId": "$userId"}"""
            val body = json.toRequestBody(mediaType)
            val request = Request.Builder()
                .url("$baseURL/api/events/$eventId/register")
                .post(body)
                .build()
            
            val response = client.newCall(request).execute()
            response.isSuccessful
        } catch (e: Exception) {
            false
        }
    }
    
    suspend fun getFCMToken(): String? {
        return try {
            FirebaseMessaging.getInstance().token.await()
        } catch (e: Exception) {
            null
        }
    }
    
    private fun mockEvents(): List<MosqueEvent> {
        val calendar = Calendar.getInstance()
        return listOf(
            MosqueEvent(
                id = "1",
                title = "Friday Khutbah: The Importance of Community",
                description = "Join us for this week's Friday sermon focusing on building stronger community bonds and supporting one another.",
                startDate = calendar.apply { add(Calendar.DAY_OF_MONTH, 2) }.time,
                category = EventCategory.RELIGIOUS,
                location = "Main Prayer Hall",
                organizer = "Imam Abdullah Rahman",
                isImportant = true
            ),
            MosqueEvent(
                id = "2",
                title = "Islamic Finance Workshop",
                description = "Learn about Islamic banking principles, halal investments, and managing finances according to Islamic teachings.",
                startDate = calendar.apply { add(Calendar.DAY_OF_MONTH, 5) }.time,
                category = EventCategory.EDUCATION,
                location = "Conference Room",
                organizer = "Dr. Sarah Ahmed",
                requiresRegistration = true,
                maxAttendees = 50,
                currentAttendees = 23
            ),
            MosqueEvent(
                id = "3",
                title = "Youth Football Tournament",
                description = "Annual youth football tournament for ages 12-18. Registration required. Trophies and prizes for winners!",
                startDate = calendar.apply { add(Calendar.DAY_OF_MONTH, 10) }.time,
                category = EventCategory.YOUTH,
                location = "Mosque Sports Ground",
                organizer = "Youth Committee",
                requiresRegistration = true,
                maxAttendees = 64,
                currentAttendees = 48
            ),
            MosqueEvent(
                id = "4",
                title = "Charity Drive: Winter Clothing Collection",
                description = "Help us collect warm clothing for those in need this winter. Drop-off point at the mosque entrance.",
                startDate = calendar.apply { add(Calendar.DAY_OF_MONTH, 1) }.time,
                endDate = calendar.apply { add(Calendar.DAY_OF_MONTH, 14) }.time,
                category = EventCategory.CHARITY,
                location = "Mosque Entrance Hall",
                organizer = "Charity Committee",
                isImportant = true
            ),
            MosqueEvent(
                id = "5",
                title = "Community Iftar Preparation",
                description = "Volunteers needed to help prepare iftar meals for the community. Join us in this blessed work.",
                startDate = calendar.apply { add(Calendar.DAY_OF_MONTH, 7) }.time,
                category = EventCategory.COMMUNITY,
                location = "Community Kitchen",
                organizer = "Sisters Committee"
            )
        )
    }
}

// MARK: - Events ViewModel
class EventsViewModel(private val context: Context) : ViewModel() {
    private val eventService = EventAPIService(context)
    
    private val _state = MutableStateFlow(EventsState())
    val state: StateFlow<EventsState> = _state.asStateFlow()
    
    init {
        loadEvents()
        getFCMToken()
    }
    
    fun loadEvents() {
        viewModelScope.launch {
            _state.value = _state.value.copy(isLoading = true, errorMessage = null)
            
            try {
                val events = eventService.fetchEvents()
                _state.value = _state.value.copy(
                    events = events,
                    filteredEvents = filterEvents(events, _state.value.selectedCategory),
                    isLoading = false
                )
            } catch (e: Exception) {
                _state.value = _state.value.copy(
                    isLoading = false,
                    errorMessage = "Failed to load events: ${e.message}"
                )
            }
        }
    }
    
    fun filterByCategory(category: EventCategory?) {
        val currentState = _state.value
        _state.value = currentState.copy(
            selectedCategory = category,
            filteredEvents = filterEvents(currentState.events, category)
        )
    }
    
    private fun filterEvents(events: List<MosqueEvent>, category: EventCategory?): List<MosqueEvent> {
        return if (category == null) {
            events.sortedBy { it.startDate }
        } else {
            events.filter { it.category == category }.sortedBy { it.startDate }
        }
    }
    
    fun createEvent(request: CreateEventRequest, adminToken: String) {
        viewModelScope.launch {
            _state.value = _state.value.copy(isCreatingEvent = true, errorMessage = null)
            
            try {
                val newEvent = eventService.createEvent(request, adminToken)
                val updatedEvents = _state.value.events + newEvent
                
                _state.value = _state.value.copy(
                    events = updatedEvents,
                    filteredEvents = filterEvents(updatedEvents, _state.value.selectedCategory),
                    isCreatingEvent = false
                )
            } catch (e: Exception) {
                _state.value = _state.value.copy(
                    isCreatingEvent = false,
                    errorMessage = "Failed to create event: ${e.message}"
                )
            }
        }
    }
    
    fun updateSubscriptions(subscription: EventSubscription) {
        viewModelScope.launch {
            try {
                val success = eventService.updateSubscriptions(subscription)
                if (success) {
                    _state.value = _state.value.copy(userSubscriptions = subscription)
                }
            } catch (e: Exception) {
                _state.value = _state.value.copy(
                    errorMessage = "Failed to update subscriptions: ${e.message}"
                )
            }
        }
    }
    
    fun registerForEvent(eventId: String, userId: String) {
        viewModelScope.launch {
            try {
                val success = eventService.registerForEvent(eventId, userId)
                if (success) {
                    // Update local event data
                    val updatedEvents = _state.value.events.map { event ->
                        if (event.id == eventId) {
                            event.copy(currentAttendees = event.currentAttendees + 1)
                        } else {
                            event
                        }
                    }
                    
                    _state.value = _state.value.copy(
                        events = updatedEvents,
                        filteredEvents = filterEvents(updatedEvents, _state.value.selectedCategory)
                    )
                }
            } catch (e: Exception) {
                _state.value = _state.value.copy(
                    errorMessage = "Failed to register for event: ${e.message}"
                )
            }
        }
    }
    
    private fun getFCMToken() {
        viewModelScope.launch {
            try {
                val token = eventService.getFCMToken()
                _state.value = _state.value.copy(fcmToken = token)
            } catch (e: Exception) {
                // Handle FCM token error silently
            }
        }
    }
}

// MARK: - Composables
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MosqueEventsScreen(
    viewModel: EventsViewModel = viewModel { EventsViewModel(LocalContext.current) }
) {
    val state by viewModel.state.collectAsState()
    var showSubscriptionSheet by remember { mutableStateOf(false) }
    var showCreateEventSheet by remember { mutableStateOf(false) }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Mosque Events") },
                actions = {
                    IconButton(onClick = { showSubscriptionSheet = true }) {
                        Icon(Icons.Default.NotificationsActive, "Subscriptions")
                    }
                    IconButton(onClick = { showCreateEventSheet = true }) {
                        Icon(Icons.Default.Add, "Create Event")
                    }
                }
            )
        }
    ) { paddingValues ->
        Column(
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
                        onRetry = { viewModel.loadEvents() }
                    )
                }
                
                else -> {
                    EventsContent(
                        events = state.filteredEvents,
                        selectedCategory = state.selectedCategory,
                        onCategorySelected = { viewModel.filterByCategory(it) },
                        onEventRegister = { eventId ->
                            viewModel.registerForEvent(eventId, "current_user_id")
                        }
                    )
                }
            }
        }
        
        if (showSubscriptionSheet) {
            EventSubscriptionSheet(
                currentSubscription = state.userSubscriptions,
                onSubscriptionUpdate = { subscription ->
                    viewModel.updateSubscriptions(subscription)
                },
                onDismiss = { showSubscriptionSheet = false }
            )
        }
        
        if (showCreateEventSheet) {
            CreateEventSheet(
                isCreating = state.isCreatingEvent,
                onCreateEvent = { request, token ->
                    viewModel.createEvent(request, token)
                },
                onDismiss = { showCreateEventSheet = false }
            )
        }
    }
}

@Composable
fun EventsContent(
    events: List<MosqueEvent>,
    selectedCategory: EventCategory?,
    onCategorySelected: (EventCategory?) -> Unit,
    onEventRegister: (String) -> Unit
) {
    Column {
        // Category Filter
        CategoryFilterRow(
            selectedCategory = selectedCategory,
            onCategorySelected = onCategorySelected
        )
        
        // Events List
        if (events.isEmpty()) {
            EmptyEventsView()
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                items(events) { event ->
                    EventCard(
                        event = event,
                        onRegisterClick = { onEventRegister(event.id) }
                    )
                }
            }
        }
    }
}

@Composable
fun CategoryFilterRow(
    selectedCategory: EventCategory?,
    onCategorySelected: (EventCategory?) -> Unit
) {
    LazyRow(
        modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        item {
            FilterChip(
                selected = selectedCategory == null,
                onClick = { onCategorySelected(null) },
                label = { Text("All Events") }
            )
        }
        
        items(EventCategory.values()) { category ->
            FilterChip(
                selected = selectedCategory == category,
                onClick = { 
                    onCategorySelected(if (selectedCategory == category) null else category)
                },
                label = { Text(category.displayName) },
                leadingIcon = {
                    Icon(
                        imageVector = category.icon,
                        contentDescription = null,
                        modifier = Modifier.size(16.dp)
                    )
                }
            )
        }
    }
}

@Composable
fun EventCard(
    event: MosqueEvent,
    onRegisterClick: () -> Unit
) {
    var showDetails by remember { mutableStateOf(false) }
    
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { showDetails = true },
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            // Header
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Top
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = event.title,
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = FontWeight.Bold,
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis
                    )
                    
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.padding(top = 4.dp)
                    ) {
                        Icon(
                            imageVector = event.category.icon,
                            contentDescription = null,
                            tint = event.category.color,
                            modifier = Modifier.size(16.dp)
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(
                            text = event.category.displayName,
                            style = MaterialTheme.typography.bodySmall,
                            color = event.category.color
                        )
                    }
                }
                
                if (event.isImportant) {
                    Icon(
                        imageVector = Icons.Default.PriorityHigh,
                        contentDescription = "Important",
                        tint = MaterialTheme.colorScheme.error
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            // Description
            Text(
                text = event.description,
                style = MaterialTheme.typography.bodyMedium,
                maxLines = 3,
                overflow = TextOverflow.Ellipsis,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            
            Spacer(modifier = Modifier.height(12.dp))
            
            // Event Info
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Bottom
            ) {
                Column {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            imageVector = Icons.Default.Schedule,
                            contentDescription = null,
                            modifier = Modifier.size(16.dp),
                            tint = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(
                            text = formatDate(event.startDate),
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    
                    if (event.requiresRegistration) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier.padding(top = 2.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Default.People,
                                contentDescription = null,
                                modifier = Modifier.size(16.dp),
                                tint = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Text(
                                text = "${event.currentAttendees}/${event.maxAttendees ?: "∞"}",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }
                
                if (event.requiresRegistration && !isEventFull(event)) {
                    Button(
                        onClick = onRegisterClick,
                        modifier = Modifier.height(36.dp)
                    ) {
                        Text("Register")
                    }
                }
            }
        }
    }
    
    if (showDetails) {
        EventDetailDialog(
            event = event,
            onDismiss = { showDetails = false },
            onRegister = onRegisterClick
        )
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
            Text("Loading events...")
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
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.padding(32.dp)
        ) {
            Icon(
                imageVector = Icons.Default.Error,
                contentDescription = "Error",
                modifier = Modifier.size(64.dp),
                tint = MaterialTheme.colorScheme.error
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Text(
                text = "Error",
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Text(
                text = message,
                style = MaterialTheme.typography.bodyMedium,
                textAlign = TextAlign.Center,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Button(onClick = onRetry) {
                Text("Retry")
            }
        }
    }
}

@Composable
fun EmptyEventsView() {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.padding(32.dp)
        ) {
            Icon(
                imageVector = Icons.Default.EventNote,
                contentDescription = "No Events",
                modifier = Modifier.size(64.dp),
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Text(
                text = "No Events Found",
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Text(
                text = "Check back later for upcoming mosque events and programs.",
                style = MaterialTheme.typography.bodyMedium,
                textAlign = TextAlign.Center,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

// Helper functions
private fun formatDate(date: Date): String {
    val formatter = SimpleDateFormat("MMM dd, yyyy HH:mm", Locale.getDefault())
    return formatter.format(date)
}

private fun isEventFull(event: MosqueEvent): Boolean {
    return event.maxAttendees?.let { max ->
        event.currentAttendees >= max
    } ?: false
}

// MARK: - Preview
@Preview(showBackground = true)
@Composable
fun MosqueEventsScreenPreview() {
    MaterialTheme {
        MosqueEventsScreen()
    }
}