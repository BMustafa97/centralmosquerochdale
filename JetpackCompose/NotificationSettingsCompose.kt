package com.centralmosque.rochdale.ui.notifications

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.NotificationsOff
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.work.*
import com.google.firebase.messaging.FirebaseMessaging
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.TimeUnit

// MARK: - Data Models
data class PrayerNotificationSettings(
    val fajrEnabled: Boolean = true,
    val dhuhrEnabled: Boolean = true,
    val asrEnabled: Boolean = true,
    val maghribEnabled: Boolean = true,
    val ishaEnabled: Boolean = true,
    val reminderMinutes: Int = 10 // 5, 10, or 15 minutes before
) {
    fun isEnabledFor(prayer: String): Boolean {
        return when (prayer.lowercase()) {
            "fajr" -> fajrEnabled
            "dhuhr" -> dhuhrEnabled
            "asr" -> asrEnabled
            "maghrib" -> maghribEnabled
            "isha" -> ishaEnabled
            else -> false
        }
    }
    
    fun setEnabled(prayer: String, enabled: Boolean): PrayerNotificationSettings {
        return when (prayer.lowercase()) {
            "fajr" -> copy(fajrEnabled = enabled)
            "dhuhr" -> copy(dhuhrEnabled = enabled)
            "asr" -> copy(asrEnabled = enabled)
            "maghrib" -> copy(maghribEnabled = enabled)
            "isha" -> copy(ishaEnabled = enabled)
            else -> this
        }
    }
}

data class NotificationState(
    val settings: PrayerNotificationSettings = PrayerNotificationSettings(),
    val hasNotificationPermission: Boolean = false,
    val fcmToken: String? = null,
    val isLoading: Boolean = false,
    val errorMessage: String? = null
)

// MARK: - Firebase Messaging Service
class PrayerFirebaseMessagingService : FirebaseMessagingService() {
    
    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        
        // Handle FCM messages for prayer notifications
        remoteMessage.notification?.let { notification ->
            showNotification(
                title = notification.title ?: "Prayer Reminder",
                body = notification.body ?: "It's time for prayer",
                data = remoteMessage.data
            )
        }
    }
    
    override fun onNewToken(token: String) {
        super.onNewToken(token)
        // Send token to your server for targeted notifications
        sendTokenToServer(token)
    }
    
    private fun showNotification(title: String, body: String, data: Map<String, String>) {
        val channelId = "prayer_notifications"
        val notificationId = System.currentTimeMillis().toInt()
        
        createNotificationChannel()
        
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra("prayer", data["prayer"])
        }
        
        val pendingIntent = PendingIntent.getActivity(
            this, 
            notificationId, 
            intent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val notification = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(R.drawable.ic_mosque) // Add your mosque icon
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()
        
        NotificationManagerCompat.from(this).notify(notificationId, notification)
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "prayer_notifications",
                "Prayer Notifications",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications for prayer times and reminders"
                enableVibration(true)
                setShowBadge(true)
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun sendTokenToServer(token: String) {
        // TODO: Send FCM token to your backend server
        // This allows your server to send targeted push notifications
    }
}

// MARK: - Work Manager for Local Notifications
class PrayerNotificationWorker(
    context: Context,
    params: WorkerParameters
) : Worker(context, params) {
    
    override fun doWork(): Result {
        val prayerName = inputData.getString("prayer_name") ?: return Result.failure()
        val jamaaahTime = inputData.getString("jamaah_time") ?: return Result.failure()
        val reminderMinutes = inputData.getInt("reminder_minutes", 10)
        
        showLocalNotification(prayerName, jamaaahTime, reminderMinutes)
        
        return Result.success()
    }
    
    private fun showLocalNotification(prayerName: String, jamaaahTime: String, reminderMinutes: Int) {
        val channelId = "prayer_notifications"
        createNotificationChannel()
        
        val intent = Intent(applicationContext, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra("prayer", prayerName)
        }
        
        val pendingIntent = PendingIntent.getActivity(
            applicationContext,
            prayerName.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val notification = NotificationCompat.Builder(applicationContext, channelId)
            .setSmallIcon(R.drawable.ic_mosque)
            .setContentTitle("Prayer Reminder")
            .setContentText("$prayerName Jamaa'ah is in $reminderMinutes minutes")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setVibrate(longArrayOf(0, 1000, 500, 1000))
            .build()
        
        NotificationManagerCompat.from(applicationContext)
            .notify(prayerName.hashCode(), notification)
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "prayer_notifications",
                "Prayer Notifications",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications for prayer times and reminders"
                enableVibration(true)
                setShowBadge(true)
            }
            
            val notificationManager = applicationContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
}

// MARK: - Notification Manager
class PrayerNotificationManager(private val context: Context) {
    private val workManager = WorkManager.getInstance(context)
    private val sharedPrefs = context.getSharedPreferences("prayer_notifications", Context.MODE_PRIVATE)
    
    fun saveSettings(settings: PrayerNotificationSettings) {
        with(sharedPrefs.edit()) {
            putBoolean("fajr_enabled", settings.fajrEnabled)
            putBoolean("dhuhr_enabled", settings.dhuhrEnabled)
            putBoolean("asr_enabled", settings.asrEnabled)
            putBoolean("maghrib_enabled", settings.maghribEnabled)
            putBoolean("isha_enabled", settings.ishaEnabled)
            putInt("reminder_minutes", settings.reminderMinutes)
            apply()
        }
    }
    
    fun loadSettings(): PrayerNotificationSettings {
        return PrayerNotificationSettings(
            fajrEnabled = sharedPrefs.getBoolean("fajr_enabled", true),
            dhuhrEnabled = sharedPrefs.getBoolean("dhuhr_enabled", true),
            asrEnabled = sharedPrefs.getBoolean("asr_enabled", true),
            maghribEnabled = sharedPrefs.getBoolean("maghrib_enabled", true),
            ishaEnabled = sharedPrefs.getBoolean("isha_enabled", true),
            reminderMinutes = sharedPrefs.getInt("reminder_minutes", 10)
        )
    }
    
    fun scheduleAllNotifications(prayers: List<Prayer>, settings: PrayerNotificationSettings) {
        // Cancel existing work
        workManager.cancelAllWorkByTag("prayer_notifications")
        
        prayers.forEach { prayer ->
            if (settings.isEnabledFor(prayer.name)) {
                scheduleNotification(prayer, settings.reminderMinutes)
            }
        }
    }
    
    private fun scheduleNotification(prayer: Prayer, reminderMinutes: Int) {
        val jamaaahTime = parseTime(prayer.jamaaahTime) ?: return
        val notificationTime = jamaaahTime.time - (reminderMinutes * 60 * 1000)
        val currentTime = System.currentTimeMillis()
        
        // Don't schedule past notifications
        if (notificationTime <= currentTime) return
        
        val delay = notificationTime - currentTime
        
        val inputData = Data.Builder()
            .putString("prayer_name", prayer.name)
            .putString("jamaah_time", prayer.jamaaahTime)
            .putInt("reminder_minutes", reminderMinutes)
            .build()
        
        val workRequest = OneTimeWorkRequestBuilder<PrayerNotificationWorker>()
            .setInitialDelay(delay, TimeUnit.MILLISECONDS)
            .setInputData(inputData)
            .addTag("prayer_notifications")
            .addTag("prayer_${prayer.name.lowercase()}")
            .build()
        
        workManager.enqueue(workRequest)
    }
    
    private fun parseTime(timeString: String): Date? {
        val format = SimpleDateFormat("HH:mm", Locale.getDefault())
        val time = format.parse(timeString) ?: return null
        
        val calendar = Calendar.getInstance()
        val timeCalendar = Calendar.getInstance().apply {
            this.time = time
        }
        
        calendar.set(Calendar.HOUR_OF_DAY, timeCalendar.get(Calendar.HOUR_OF_DAY))
        calendar.set(Calendar.MINUTE, timeCalendar.get(Calendar.MINUTE))
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        
        return calendar.time
    }
    
    suspend fun getFCMToken(): String? {
        return try {
            FirebaseMessaging.getInstance().token.await()
        } catch (e: Exception) {
            null
        }
    }
}

// MARK: - ViewModel
class NotificationSettingsViewModel(private val context: Context) : ViewModel() {
    private val notificationManager = PrayerNotificationManager(context)
    
    private val _state = MutableStateFlow(NotificationState())
    val state: StateFlow<NotificationState> = _state.asStateFlow()
    
    init {
        loadSettings()
        checkNotificationPermission()
        getFCMToken()
    }
    
    private fun loadSettings() {
        val settings = notificationManager.loadSettings()
        _state.value = _state.value.copy(settings = settings)
    }
    
    private fun checkNotificationPermission() {
        val hasPermission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            NotificationManagerCompat.from(context).areNotificationsEnabled()
        }
        
        _state.value = _state.value.copy(hasNotificationPermission = hasPermission)
    }
    
    private fun getFCMToken() {
        viewModelScope.launch {
            try {
                val token = notificationManager.getFCMToken()
                _state.value = _state.value.copy(fcmToken = token)
            } catch (e: Exception) {
                _state.value = _state.value.copy(
                    errorMessage = "Failed to get FCM token: ${e.message}"
                )
            }
        }
    }
    
    fun togglePrayerNotification(prayer: String) {
        val currentSettings = _state.value.settings
        val newSettings = currentSettings.setEnabled(prayer, !currentSettings.isEnabledFor(prayer))
        
        _state.value = _state.value.copy(settings = newSettings)
        notificationManager.saveSettings(newSettings)
        scheduleNotifications()
    }
    
    fun updateReminderTime(minutes: Int) {
        val newSettings = _state.value.settings.copy(reminderMinutes = minutes)
        _state.value = _state.value.copy(settings = newSettings)
        notificationManager.saveSettings(newSettings)
        scheduleNotifications()
    }
    
    fun onPermissionResult(granted: Boolean) {
        _state.value = _state.value.copy(hasNotificationPermission = granted)
        if (granted) {
            scheduleNotifications()
        }
    }
    
    private fun scheduleNotifications() {
        // Mock prayer data - replace with actual prayer times from your service
        val prayers = listOf(
            Prayer("Fajr", "05:30", "05:45"),
            Prayer("Dhuhr", "12:45", "13:00"),
            Prayer("Asr", "16:15", "16:30"),
            Prayer("Maghrib", "18:45", "18:50"),
            Prayer("Isha", "20:30", "20:45")
        )
        
        notificationManager.scheduleAllNotifications(prayers, _state.value.settings)
    }
}

// MARK: - Composables
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NotificationSettingsScreen(
    viewModel: NotificationSettingsViewModel = viewModel { 
        NotificationSettingsViewModel(LocalContext.current) 
    }
) {
    val context = LocalContext.current
    val state by viewModel.state.collectAsState()
    
    val permissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission()
    ) { granted ->
        viewModel.onPermissionResult(granted)
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Notification Settings") }
            )
        }
    ) { paddingValues ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            item {
                if (!state.hasNotificationPermission) {
                    NotificationPermissionCard(
                        onRequestPermission = {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                permissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                            }
                        }
                    )
                } else {
                    NotificationToggleSection(
                        settings = state.settings,
                        onToggleChanged = viewModel::togglePrayerNotification
                    )
                }
            }
            
            if (state.hasNotificationPermission) {
                item {
                    ReminderTimeSection(
                        selectedTime = state.settings.reminderMinutes,
                        onTimeChanged = viewModel::updateReminderTime
                    )
                }
            }
            
            state.errorMessage?.let { error ->
                item {
                    ErrorCard(message = error)
                }
            }
            
            item {
                InfoSection()
            }
        }
    }
}

@Composable
fun NotificationPermissionCard(onRequestPermission: () -> Unit) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.errorContainer
        )
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                imageVector = Icons.Default.NotificationsOff,
                contentDescription = "Notifications Disabled",
                tint = MaterialTheme.colorScheme.onErrorContainer,
                modifier = Modifier.size(48.dp)
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Text(
                text = "Notifications Disabled",
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onErrorContainer
            )
            
            Spacer(modifier = Modifier.height(4.dp))
            
            Text(
                text = "Enable notifications to receive prayer reminders",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onErrorContainer,
                textAlign = TextAlign.Center
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Button(
                onClick = onRequestPermission,
                colors = ButtonDefaults.buttonColors(
                    containerColor = MaterialTheme.colorScheme.primary
                )
            ) {
                Icon(
                    imageVector = Icons.Default.Notifications,
                    contentDescription = null,
                    modifier = Modifier.size(16.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text("Enable Notifications")
            }
        }
    }
}

@Composable
fun NotificationToggleSection(
    settings: PrayerNotificationSettings,
    onToggleChanged: (String) -> Unit
) {
    val prayers = listOf("Fajr", "Dhuhr", "Asr", "Maghrib", "Isha")
    
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = "Prayer Notifications",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Text(
                text = "Choose which prayers you'd like to be reminded about",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            prayers.forEach { prayer ->
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 8.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column {
                        Text(
                            text = prayer,
                            style = MaterialTheme.typography.bodyLarge,
                            fontWeight = FontWeight.Medium
                        )
                        Text(
                            text = "Jamaa'ah reminder",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    
                    Switch(
                        checked = settings.isEnabledFor(prayer),
                        onCheckedChange = { onToggleChanged(prayer) }
                    )
                }
                
                if (prayer != prayers.last()) {
                    HorizontalDivider(
                        modifier = Modifier.padding(vertical = 4.dp),
                        color = MaterialTheme.colorScheme.outline.copy(alpha = 0.12f)
                    )
                }
            }
        }
    }
}

@Composable
fun ReminderTimeSection(
    selectedTime: Int,
    onTimeChanged: (Int) -> Unit
) {
    val reminderOptions = listOf(5, 10, 15)
    
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = "Reminder Time",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Text(
                text = "How many minutes before Jamaa'ah would you like to be reminded?",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                reminderOptions.forEach { minutes ->
                    FilterChip(
                        selected = selectedTime == minutes,
                        onClick = { onTimeChanged(minutes) },
                        label = { Text("$minutes min") },
                        modifier = Modifier.weight(1f)
                    )
                }
            }
        }
    }
}

@Composable
fun ErrorCard(message: String) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.errorContainer
        )
    ) {
        Text(
            text = message,
            modifier = Modifier.padding(16.dp),
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onErrorContainer
        )
    }
}

@Composable
fun InfoSection() {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = "About Prayer Notifications",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Text(
                text = "• Notifications will remind you before Jamaa'ah time at Central Mosque Rochdale\n" +
                      "• Make sure to keep notifications enabled in your device settings\n" +
                      "• Notifications are scheduled locally and will work without internet connection",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

// MARK: - Preview
@Preview(showBackground = true)
@Composable
fun NotificationSettingsScreenPreview() {
    MaterialTheme {
        NotificationSettingsScreen()
    }
}