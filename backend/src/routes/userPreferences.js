const express = require('express');
const { body, param, validationResult } = require('express-validator');
const UserPreferences = require('../models/UserPreferences');
const NotificationService = require('../services/NotificationService');
const PrayerTimesService = require('../services/PrayerTimesService');

const router = express.Router();

// Validation middleware
const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      message: 'Validation errors',
      errors: errors.array()
    });
  }
  next();
};

// Get user preferences
router.get('/:userId/preferences', [
  param('userId').isString().notEmpty().withMessage('User ID is required')
], handleValidationErrors, async (req, res) => {
  try {
    const { userId } = req.params;
    
    let preferences = await UserPreferences.findByUserId(userId);
    
    // Create default preferences if user doesn't exist
    if (!preferences) {
      preferences = new UserPreferences({
        userId,
        location: {
          latitude: 53.6158, // Rochdale coordinates
          longitude: -2.1561,
          city: 'Rochdale',
          country: 'UK',
          timezone: 'Europe/London'
        }
      });
      await preferences.save();
    }
    
    res.json({
      success: true,
      data: preferences
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch user preferences',
      error: error.message
    });
  }
});

// Update user preferences
router.put('/:userId/preferences', [
  param('userId').isString().notEmpty().withMessage('User ID is required'),
  body('notifications').optional().isObject().withMessage('Notifications must be an object'),
  body('location').optional().isObject().withMessage('Location must be an object'),
  body('preferences').optional().isObject().withMessage('Preferences must be an object'),
  body('eventNotifications').optional().isObject().withMessage('Event notifications must be an object')
], handleValidationErrors, async (req, res) => {
  try {
    const { userId } = req.params;
    const updateData = req.body;
    
    let preferences = await UserPreferences.findByUserId(userId);
    
    if (!preferences) {
      // Create new preferences if user doesn't exist
      preferences = new UserPreferences({
        userId,
        ...updateData,
        location: updateData.location || {
          latitude: 53.6158,
          longitude: -2.1561,
          city: 'Rochdale',
          country: 'UK',
          timezone: 'Europe/London'
        }
      });
    } else {
      // Update existing preferences
      Object.keys(updateData).forEach(key => {
        if (key === 'location' && updateData[key]) {
          preferences.location = { ...preferences.location, ...updateData[key] };
        } else if (updateData[key] !== undefined) {
          preferences[key] = updateData[key];
        }
      });
    }
    
    await preferences.save();
    
    res.json({
      success: true,
      message: 'Preferences updated successfully',
      data: preferences
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to update preferences',
      error: error.message
    });
  }
});

// Update notification settings
router.put('/:userId/notifications', [
  param('userId').isString().notEmpty().withMessage('User ID is required'),
  body('prayer').optional().isIn(['fajr', 'dhuhr', 'asr', 'maghrib', 'isha', 'jumma']).withMessage('Invalid prayer name'),
  body('enabled').optional().isBoolean().withMessage('Enabled must be boolean'),
  body('alertMinutes').optional().isInt({ min: 0, max: 120 }).withMessage('Alert minutes must be between 0 and 120')
], handleValidationErrors, async (req, res) => {
  try {
    const { userId } = req.params;
    const { prayer, enabled, alertMinutes, notifications } = req.body;
    
    const preferences = await UserPreferences.findByUserId(userId);
    if (!preferences) {
      return res.status(404).json({
        success: false,
        message: 'User preferences not found'
      });
    }
    
    if (notifications) {
      // Bulk update notifications
      preferences.notifications = { ...preferences.notifications, ...notifications };
    } else if (prayer) {
      // Update specific prayer notification
      if (enabled !== undefined) {
        preferences.notifications[prayer].enabled = enabled;
      }
      if (alertMinutes !== undefined) {
        preferences.notifications[prayer].alertMinutes = alertMinutes;
      }
    }
    
    await preferences.save();
    
    res.json({
      success: true,
      message: 'Notification settings updated',
      data: preferences.notifications
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to update notification settings',
      error: error.message
    });
  }
});

// Update user location
router.put('/:userId/location', [
  param('userId').isString().notEmpty().withMessage('User ID is required'),
  body('latitude').isFloat({ min: -90, max: 90 }).withMessage('Valid latitude required'),
  body('longitude').isFloat({ min: -180, max: 180 }).withMessage('Valid longitude required'),
  body('city').optional().isString().withMessage('City must be a string'),
  body('country').optional().isString().withMessage('Country must be a string'),
  body('timezone').optional().isString().withMessage('Timezone must be a string')
], handleValidationErrors, async (req, res) => {
  try {
    const { userId } = req.params;
    const { latitude, longitude, city, country, timezone } = req.body;
    
    const preferences = await UserPreferences.findByUserId(userId);
    if (!preferences) {
      return res.status(404).json({
        success: false,
        message: 'User preferences not found'
      });
    }
    
    await preferences.updateLocation(latitude, longitude, city, country, timezone);
    
    res.json({
      success: true,
      message: 'Location updated successfully',
      data: preferences.location
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to update location',
      error: error.message
    });
  }
});

// Get prayer times for user location
router.get('/:userId/prayer-times', [
  param('userId').isString().notEmpty().withMessage('User ID is required')
], handleValidationErrors, async (req, res) => {
  try {
    const { userId } = req.params;
    const { date } = req.query;
    
    const preferences = await UserPreferences.findByUserId(userId);
    if (!preferences) {
      return res.status(404).json({
        success: false,
        message: 'User preferences not found'
      });
    }
    
    const prayerTimes = await PrayerTimesService.getPrayerTimes(
      preferences.location.latitude,
      preferences.location.longitude,
      date || new Date(),
      preferences.preferences.prayerTimeCalculationMethod
    );
    
    res.json({
      success: true,
      data: {
        location: preferences.location,
        prayerTimes,
        calculationMethod: preferences.preferences.prayerTimeCalculationMethod
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch prayer times',
      error: error.message
    });
  }
});

// Update device token for push notifications
router.put('/:userId/device-token', [
  param('userId').isString().notEmpty().withMessage('User ID is required'),
  body('platform').isIn(['ios', 'android']).withMessage('Platform must be ios or android'),
  body('token').isString().notEmpty().withMessage('Device token is required')
], handleValidationErrors, async (req, res) => {
  try {
    const { userId } = req.params;
    const { platform, token } = req.body;
    
    const preferences = await UserPreferences.findByUserId(userId);
    if (!preferences) {
      return res.status(404).json({
        success: false,
        message: 'User preferences not found'
      });
    }
    
    preferences.deviceTokens[platform] = token;
    await preferences.save();
    
    res.json({
      success: true,
      message: 'Device token updated successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to update device token',
      error: error.message
    });
  }
});

// Send test notification
router.post('/:userId/test-notification', [
  param('userId').isString().notEmpty().withMessage('User ID is required'),
  body('prayer').optional().isIn(['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']).withMessage('Invalid prayer name')
], handleValidationErrors, async (req, res) => {
  try {
    const { userId } = req.params;
    const { prayer = 'fajr' } = req.body;
    
    const preferences = await UserPreferences.findByUserId(userId);
    if (!preferences) {
      return res.status(404).json({
        success: false,
        message: 'User preferences not found'
      });
    }
    
    const result = await NotificationService.sendTestNotification(preferences, prayer);
    
    res.json({
      success: true,
      message: 'Test notification sent',
      data: result
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to send test notification',
      error: error.message
    });
  }
});

// Delete user preferences (GDPR compliance)
router.delete('/:userId/preferences', [
  param('userId').isString().notEmpty().withMessage('User ID is required')
], handleValidationErrors, async (req, res) => {
  try {
    const { userId } = req.params;
    
    const preferences = await UserPreferences.findByUserId(userId);
    if (!preferences) {
      return res.status(404).json({
        success: false,
        message: 'User preferences not found'
      });
    }
    
    preferences.isActive = false;
    await preferences.save();
    
    res.json({
      success: true,
      message: 'User preferences deleted successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to delete preferences',
      error: error.message
    });
  }
});

module.exports = router;