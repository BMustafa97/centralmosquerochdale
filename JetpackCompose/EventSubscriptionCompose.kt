package com.centralmosque.rochdale.ui.events

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import java.text.SimpleDateFormat
import java.util.*

// MARK: - Event Subscription Sheet
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EventSubscriptionSheet(
    currentSubscription: EventSubscription?,
    onSubscriptionUpdate: (EventSubscription) -> Unit,
    onDismiss: () -> Unit
) {
    var subscription by remember {
        mutableStateOf(
            currentSubscription ?: EventSubscription(
                userId = "current_user_id",
                subscribedCategories = EventCategory.values().toSet(),
                notifyBeforeMinutes = 30,
                isEnabled = true
            )
        )
    }
    
    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false)
    ) {
        Surface(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp),
            shape = MaterialTheme.shapes.large
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(24.dp)
            ) {
                // Header
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Event Subscriptions",
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = FontWeight.Bold
                    )
                    
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Default.Close, contentDescription = "Close")
                    }
                }
                
                Spacer(modifier = Modifier.height(16.dp))
                
                LazyColumn(
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    item {
                        // Enable/Disable Toggle
                        Card {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(16.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    text = "Enable Event Notifications",
                                    style = MaterialTheme.typography.titleMedium
                                )
                                
                                Switch(
                                    checked = subscription.isEnabled,
                                    onCheckedChange = { enabled ->
                                        subscription = subscription.copy(isEnabled = enabled)
                                        onSubscriptionUpdate(subscription)
                                    }
                                )
                            }
                        }
                    }
                    
                    if (subscription.isEnabled) {
                        item {
                            // Categories Section
                            Card {
                                Column(
                                    modifier = Modifier.padding(16.dp)
                                ) {
                                    Text(
                                        text = "Event Categories",
                                        style = MaterialTheme.typography.titleMedium,
                                        fontWeight = FontWeight.Bold
                                    )
                                    
                                    Spacer(modifier = Modifier.height(12.dp))
                                    
                                    EventCategory.values().forEach { category ->
                                        Row(
                                            modifier = Modifier
                                                .fillMaxWidth()
                                                .padding(vertical = 4.dp),
                                            horizontalArrangement = Arrangement.SpaceBetween,
                                            verticalAlignment = Alignment.CenterVertically
                                        ) {
                                            Row(
                                                verticalAlignment = Alignment.CenterVertically
                                            ) {
                                                Icon(
                                                    imageVector = category.icon,
                                                    contentDescription = null,
                                                    tint = category.color,
                                                    modifier = Modifier.size(20.dp)
                                                )
                                                
                                                Spacer(modifier = Modifier.width(12.dp))
                                                
                                                Column {
                                                    Text(
                                                        text = category.displayName,
                                                        style = MaterialTheme.typography.bodyMedium
                                                    )
                                                    Text(
                                                        text = getCategoryDescription(category),
                                                        style = MaterialTheme.typography.bodySmall,
                                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                                    )
                                                }
                                            }
                                            
                                            Switch(
                                                checked = subscription.subscribedCategories.contains(category),
                                                onCheckedChange = { enabled ->
                                                    val newCategories = if (enabled) {
                                                        subscription.subscribedCategories + category
                                                    } else {
                                                        subscription.subscribedCategories - category
                                                    }
                                                    subscription = subscription.copy(subscribedCategories = newCategories)
                                                    onSubscriptionUpdate(subscription)
                                                }
                                            )
                                        }
                                        
                                        if (category != EventCategory.values().last()) {
                                            HorizontalDivider(
                                                modifier = Modifier.padding(vertical = 8.dp),
                                                color = MaterialTheme.colorScheme.outline.copy(alpha = 0.12f)
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        
                        item {
                            // Notification Timing
                            Card {
                                Column(
                                    modifier = Modifier.padding(16.dp)
                                ) {
                                    Text(
                                        text = "Notification Timing",
                                        style = MaterialTheme.typography.titleMedium,
                                        fontWeight = FontWeight.Bold
                                    )
                                    
                                    Spacer(modifier = Modifier.height(8.dp))
                                    
                                    Text(
                                        text = "How far in advance would you like to be notified?",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                    
                                    Spacer(modifier = Modifier.height(12.dp))
                                    
                                    val timingOptions = listOf(
                                        15 to "15 minutes",
                                        30 to "30 minutes", 
                                        60 to "1 hour",
                                        120 to "2 hours",
                                        1440 to "1 day"
                                    )
                                    
                                    Column {
                                        timingOptions.forEach { (minutes, label) ->
                                            Row(
                                                modifier = Modifier.fillMaxWidth(),
                                                verticalAlignment = Alignment.CenterVertically
                                            ) {
                                                RadioButton(
                                                    selected = subscription.notifyBeforeMinutes == minutes,
                                                    onClick = {
                                                        subscription = subscription.copy(notifyBeforeMinutes = minutes)
                                                        onSubscriptionUpdate(subscription)
                                                    }
                                                )
                                                
                                                Spacer(modifier = Modifier.width(8.dp))
                                                
                                                Text(
                                                    text = label,
                                                    style = MaterialTheme.typography.bodyMedium
                                                )
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        item {
                            // Info Card
                            Card(
                                colors = CardDefaults.cardColors(
                                    containerColor = MaterialTheme.colorScheme.surfaceVariant
                                )
                            ) {
                                Row(
                                    modifier = Modifier.padding(16.dp),
                                    verticalAlignment = Alignment.Top
                                ) {
                                    Icon(
                                        imageVector = Icons.Default.Info,
                                        contentDescription = null,
                                        tint = MaterialTheme.colorScheme.primary,
                                        modifier = Modifier.size(20.dp)
                                    )
                                    
                                    Spacer(modifier = Modifier.width(12.dp))
                                    
                                    Text(
                                        text = "You will receive push notifications for events in selected categories. " +
                                                "Notifications are sent ${formatNotificationTime(subscription.notifyBeforeMinutes)} before each event starts.",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Create Event Sheet
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CreateEventSheet(
    isCreating: Boolean,
    onCreateEvent: (CreateEventRequest, String) -> Unit,
    onDismiss: () -> Unit
) {
    var title by remember { mutableStateOf("") }
    var description by remember { mutableStateOf("") }
    var selectedCategory by remember { mutableStateOf(EventCategory.ANNOUNCEMENT) }
    var location by remember { mutableStateOf("") }
    var organizer by remember { mutableStateOf("") }
    var isImportant by remember { mutableStateOf(false) }
    var requiresRegistration by remember { mutableStateOf(false) }
    var maxAttendees by remember { mutableStateOf("") }
    var adminToken by remember { mutableStateOf("") }
    var showDatePicker by remember { mutableStateOf(false) }
    var selectedDate by remember { mutableStateOf(Date()) }
    
    val isFormValid = title.isNotBlank() && description.isNotBlank() && 
            location.isNotBlank() && organizer.isNotBlank() && adminToken.isNotBlank()
    
    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false)
    ) {
        Surface(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp),
            shape = MaterialTheme.shapes.large
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(24.dp)
            ) {
                // Header
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Create Event",
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = FontWeight.Bold
                    )
                    
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Default.Close, contentDescription = "Close")
                    }
                }
                
                Spacer(modifier = Modifier.height(16.dp))
                
                Column(
                    modifier = Modifier
                        .weight(1f)
                        .verticalScroll(rememberScrollState()),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    // Admin Token
                    OutlinedTextField(
                        value = adminToken,
                        onValueChange = { adminToken = it },
                        label = { Text("Admin Token") },
                        visualTransformation = PasswordVisualTransformation(),
                        modifier = Modifier.fillMaxWidth(),
                        leadingIcon = {
                            Icon(Icons.Default.Security, contentDescription = null)
                        }
                    )
                    
                    // Event Title
                    OutlinedTextField(
                        value = title,
                        onValueChange = { title = it },
                        label = { Text("Event Title") },
                        modifier = Modifier.fillMaxWidth(),
                        leadingIcon = {
                            Icon(Icons.Default.Title, contentDescription = null)
                        }
                    )
                    
                    // Description
                    OutlinedTextField(
                        value = description,
                        onValueChange = { description = it },
                        label = { Text("Description") },
                        modifier = Modifier.fillMaxWidth(),
                        minLines = 3,
                        maxLines = 5,
                        leadingIcon = {
                            Icon(Icons.Default.Description, contentDescription = null)
                        }
                    )
                    
                    // Category Dropdown
                    var categoryExpanded by remember { mutableStateOf(false) }
                    
                    ExposedDropdownMenuBox(
                        expanded = categoryExpanded,
                        onExpandedChange = { categoryExpanded = it }
                    ) {
                        OutlinedTextField(
                            value = selectedCategory.displayName,
                            onValueChange = { },
                            readOnly = true,
                            label = { Text("Category") },
                            trailingIcon = {
                                ExposedDropdownMenuDefaults.TrailingIcon(expanded = categoryExpanded)
                            },
                            modifier = Modifier
                                .fillMaxWidth()
                                .menuAnchor(),
                            leadingIcon = {
                                Icon(selectedCategory.icon, contentDescription = null)
                            }
                        )
                        
                        ExposedDropdownMenu(
                            expanded = categoryExpanded,
                            onDismissRequest = { categoryExpanded = false }
                        ) {
                            EventCategory.values().forEach { category ->
                                DropdownMenuItem(
                                    text = {
                                        Row(verticalAlignment = Alignment.CenterVertically) {
                                            Icon(
                                                category.icon,
                                                contentDescription = null,
                                                tint = category.color,
                                                modifier = Modifier.size(20.dp)
                                            )
                                            Spacer(modifier = Modifier.width(8.dp))
                                            Text(category.displayName)
                                        }
                                    },
                                    onClick = {
                                        selectedCategory = category
                                        categoryExpanded = false
                                    }
                                )
                            }
                        }
                    }
                    
                    // Location
                    OutlinedTextField(
                        value = location,
                        onValueChange = { location = it },
                        label = { Text("Location") },
                        modifier = Modifier.fillMaxWidth(),
                        leadingIcon = {
                            Icon(Icons.Default.LocationOn, contentDescription = null)
                        }
                    )
                    
                    // Organizer
                    OutlinedTextField(
                        value = organizer,
                        onValueChange = { organizer = it },
                        label = { Text("Organizer") },
                        modifier = Modifier.fillMaxWidth(),
                        leadingIcon = {
                            Icon(Icons.Default.Person, contentDescription = null)
                        }
                    )
                    
                    // Date Selection
                    OutlinedTextField(
                        value = SimpleDateFormat("MMM dd, yyyy HH:mm", Locale.getDefault()).format(selectedDate),
                        onValueChange = { },
                        readOnly = true,
                        label = { Text("Event Date & Time") },
                        modifier = Modifier
                            .fillMaxWidth(),
                        leadingIcon = {
                            Icon(Icons.Default.Schedule, contentDescription = null)
                        },
                        trailingIcon = {
                            IconButton(onClick = { showDatePicker = true }) {
                                Icon(Icons.Default.DateRange, contentDescription = null)
                            }
                        }
                    )
                    
                    // Toggles
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text("Important Event")
                        Switch(
                            checked = isImportant,
                            onCheckedChange = { isImportant = it }
                        )
                    }
                    
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text("Requires Registration")
                        Switch(
                            checked = requiresRegistration,
                            onCheckedChange = { requiresRegistration = it }
                        )
                    }
                    
                    // Max Attendees (if registration required)
                    if (requiresRegistration) {
                        OutlinedTextField(
                            value = maxAttendees,
                            onValueChange = { maxAttendees = it },
                            label = { Text("Max Attendees") },
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                            modifier = Modifier.fillMaxWidth(),
                            leadingIcon = {
                                Icon(Icons.Default.People, contentDescription = null)
                            }
                        )
                    }
                }
                
                Spacer(modifier = Modifier.height(16.dp))
                
                // Action Buttons
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    OutlinedButton(
                        onClick = onDismiss,
                        modifier = Modifier.weight(1f)
                    ) {
                        Text("Cancel")
                    }
                    
                    Button(
                        onClick = {
                            val request = CreateEventRequest(
                                title = title,
                                description = description,
                                startDate = selectedDate,
                                category = selectedCategory,
                                location = location,
                                organizer = organizer,
                                isImportant = isImportant,
                                maxAttendees = if (requiresRegistration && maxAttendees.isNotBlank()) {
                                    maxAttendees.toIntOrNull()
                                } else null,
                                requiresRegistration = requiresRegistration
                            )
                            onCreateEvent(request, adminToken)
                        },
                        modifier = Modifier.weight(1f),
                        enabled = isFormValid && !isCreating
                    ) {
                        if (isCreating) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(16.dp),
                                strokeWidth = 2.dp
                            )
                        } else {
                            Text("Create Event")
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Event Detail Dialog
@Composable
fun EventDetailDialog(
    event: MosqueEvent,
    onDismiss: () -> Unit,
    onRegister: () -> Unit
) {
    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false)
    ) {
        Surface(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            shape = MaterialTheme.shapes.large
        ) {
            Column(
                modifier = Modifier.padding(24.dp)
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
                            fontWeight = FontWeight.Bold
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
                    
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Default.Close, contentDescription = "Close")
                    }
                }
                
                Spacer(modifier = Modifier.height(16.dp))
                
                // Event Details
                Column(
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    EventDetailRow(
                        icon = Icons.Default.Schedule,
                        label = "Date & Time",
                        value = formatDate(event.startDate)
                    )
                    
                    EventDetailRow(
                        icon = Icons.Default.LocationOn,
                        label = "Location",
                        value = event.location
                    )
                    
                    EventDetailRow(
                        icon = Icons.Default.Person,
                        label = "Organizer",
                        value = event.organizer
                    )
                    
                    if (event.requiresRegistration) {
                        EventDetailRow(
                            icon = Icons.Default.People,
                            label = "Attendees",
                            value = "${event.currentAttendees}/${event.maxAttendees ?: "∞"}"
                        )
                    }
                }
                
                Spacer(modifier = Modifier.height(16.dp))
                
                HorizontalDivider()
                
                Spacer(modifier = Modifier.height(16.dp))
                
                // Description
                Text(
                    text = "Description",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
                
                Spacer(modifier = Modifier.height(8.dp))
                
                Text(
                    text = event.description,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                
                Spacer(modifier = Modifier.height(24.dp))
                
                // Action Buttons
                if (event.requiresRegistration) {
                    if (isEventFull(event)) {
                        Text(
                            text = "This event is fully booked.",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.error,
                            textAlign = TextAlign.Center,
                            modifier = Modifier.fillMaxWidth()
                        )
                    } else {
                        Button(
                            onClick = {
                                onRegister()
                                onDismiss()
                            },
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text("Register for Event")
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun EventDetailRow(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String,
    value: String
) {
    Row(
        verticalAlignment = Alignment.Top,
        modifier = Modifier.fillMaxWidth()
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            modifier = Modifier.size(20.dp),
            tint = MaterialTheme.colorScheme.primary
        )
        
        Spacer(modifier = Modifier.width(12.dp))
        
        Column {
            Text(
                text = label,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Text(
                text = value,
                style = MaterialTheme.typography.bodyMedium
            )
        }
    }
}

// Helper functions
private fun getCategoryDescription(category: EventCategory): String {
    return when (category) {
        EventCategory.LECTURE -> "Islamic talks and educational sessions"
        EventCategory.FUNDRAISING -> "Charity drives and fundraising events"
        EventCategory.COMMUNITY -> "Community gatherings and social events"
        EventCategory.EDUCATION -> "Classes and educational programs"
        EventCategory.RELIGIOUS -> "Special prayers and religious observances"
        EventCategory.YOUTH -> "Youth activities and programs"
        EventCategory.CHARITY -> "Charitable work and volunteer opportunities"
        EventCategory.ANNOUNCEMENT -> "Important mosque announcements"
    }
}

private fun formatNotificationTime(minutes: Int): String {
    return when {
        minutes < 60 -> "$minutes minutes"
        minutes < 1440 -> "${minutes / 60} hour${if (minutes / 60 > 1) "s" else ""}"
        else -> "${minutes / 1440} day${if (minutes / 1440 > 1) "s" else ""}"
    }
}

// MARK: - Preview
@Preview(showBackground = true)
@Composable
fun EventSubscriptionSheetPreview() {
    MaterialTheme {
        EventSubscriptionSheet(
            currentSubscription = null,
            onSubscriptionUpdate = { },
            onDismiss = { }
        )
    }
}