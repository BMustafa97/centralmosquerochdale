const mongoose = require('mongoose');

// User Preferences Schema
const userPreferencesSchema = new mongoose.Schema({
  userId: {
    type: String,
    required: true,
    unique: true,
    index: true
  },
  
  // Prayer notification settings
  notifications: {
    fajr: {
      enabled: { type: Boolean, default: true },
      alertMinutes: { type: Number, default: 10, min: 0, max: 60 }
    },
    dhuhr: {
      enabled: { type: Boolean, default: true },
      alertMinutes: { type: Number, default: 15, min: 0, max: 60 }
    },
    asr: {
      enabled: { type: Boolean, default: false },
      alertMinutes: { type: Number, default: 5, min: 0, max: 60 }
    },
    maghrib: {
      enabled: { type: Boolean, default: true },
      alertMinutes: { type: Number, default: 10, min: 0, max: 60 }
    },
    isha: {
      enabled: { type: Boolean, default: true },
      alertMinutes: { type: Number, default: 15, min: 0, max: 60 }
    },
    jumma: {
      enabled: { type: Boolean, default: true },
      alertMinutes: { type: Number, default: 30, min: 0, max: 120 }
    }
  },
  
  // Event notification settings
  eventNotifications: {
    enabled: { type: Boolean, default: true },
    categories: {
      religious: { type: Boolean, default: true },
      community: { type: Boolean, default: true },
      educational: { type: Boolean, default: true },
      fundraising: { type: Boolean, default: false },
      announcements: { type: Boolean, default: true }
    }
  },
  
  // User location for prayer times
  location: {
    latitude: { type: Number, required: true },
    longitude: { type: Number, required: true },
    city: { type: String, default: 'Rochdale' },
    country: { type: String, default: 'UK' },
    timezone: { type: String, default: 'Europe/London' },
    lastUpdated: { type: Date, default: Date.now }
  },
  
  // Device tokens for push notifications
  deviceTokens: {
    ios: { type: String },
    android: { type: String }
  },
  
  // App preferences
  preferences: {
    language: { type: String, default: 'en', enum: ['en', 'ar', 'ur'] },
    theme: { type: String, default: 'light', enum: ['light', 'dark', 'auto'] },
    soundEnabled: { type: Boolean, default: true },
    vibrationEnabled: { type: Boolean, default: true },
    prayerTimeCalculationMethod: { type: Number, default: 2, min: 1, max: 12 },
    hijriDateAdjustment: { type: Number, default: 0, min: -2, max: 2 }
  },
  
  // Privacy settings
  privacy: {
    shareLocation: { type: Boolean, default: false },
    allowAnalytics: { type: Boolean, default: true },
    allowMarketing: { type: Boolean, default: false }
  },
  
  // Metadata
  isActive: { type: Boolean, default: true },
  lastLogin: { type: Date },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
}, {
  timestamps: true,
  collection: 'user_preferences'
});

// Indexes for better query performance
userPreferencesSchema.index({ userId: 1 });
userPreferencesSchema.index({ 'location.city': 1, 'location.country': 1 });
userPreferencesSchema.index({ isActive: 1 });
userPreferencesSchema.index({ createdAt: -1 });

// Pre-save middleware to update the updatedAt field
userPreferencesSchema.pre('save', function(next) {
  this.updatedAt = new Date();
  next();
});

// Instance methods
userPreferencesSchema.methods.getNotificationSettings = function() {
  return {
    prayers: this.notifications,
    events: this.eventNotifications,
    deviceTokens: this.deviceTokens
  };
};

userPreferencesSchema.methods.updateLocation = function(latitude, longitude, city, country, timezone) {
  this.location = {
    latitude,
    longitude,
    city: city || this.location.city,
    country: country || this.location.country,
    timezone: timezone || this.location.timezone,
    lastUpdated: new Date()
  };
  return this.save();
};

userPreferencesSchema.methods.togglePrayerNotification = function(prayer, enabled) {
  if (this.notifications[prayer]) {
    this.notifications[prayer].enabled = enabled;
    return this.save();
  }
  throw new Error(`Invalid prayer name: ${prayer}`);
};

userPreferencesSchema.methods.setPrayerAlertTiming = function(prayer, minutes) {
  if (this.notifications[prayer]) {
    this.notifications[prayer].alertMinutes = minutes;
    return this.save();
  }
  throw new Error(`Invalid prayer name: ${prayer}`);
};

// Static methods
userPreferencesSchema.statics.findByUserId = function(userId) {
  return this.findOne({ userId, isActive: true });
};

userPreferencesSchema.statics.getActiveUsers = function() {
  return this.find({ isActive: true });
};

userPreferencesSchema.statics.getUsersInLocation = function(city, country) {
  return this.find({ 
    'location.city': city, 
    'location.country': country,
    isActive: true 
  });
};

userPreferencesSchema.statics.getUsersWithNotificationsEnabled = function(prayer) {
  const query = {};
  query[`notifications.${prayer}.enabled`] = true;
  query.isActive = true;
  return this.find(query);
};

// Virtual for full name (if we add user profile later)
userPreferencesSchema.virtual('locationString').get(function() {
  return `${this.location.city}, ${this.location.country}`;
});

// Export the model
module.exports = mongoose.model('UserPreferences', userPreferencesSchema);