const admin = require('firebase-admin');
const apn = require('apn');

class NotificationService {
  constructor() {
    this.initializeFirebase();
    this.initializeAPNS();
  }

  initializeFirebase() {
    try {
      if (!admin.apps.length) {
        admin.initializeApp({
          credential: admin.credential.cert({
            projectId: process.env.FIREBASE_PROJECT_ID,
            privateKeyId: process.env.FIREBASE_PRIVATE_KEY_ID,
            privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
            clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
            clientId: process.env.FIREBASE_CLIENT_ID,
            authUri: process.env.FIREBASE_AUTH_URI,
            tokenUri: process.env.FIREBASE_TOKEN_URI
          })
        });
      }
      console.log('Firebase Admin initialized successfully');
    } catch (error) {
      console.error('Failed to initialize Firebase Admin:', error.message);
    }
  }

  initializeAPNS() {
    try {
      if (process.env.APNS_PRIVATE_KEY_PATH) {
        this.apnProvider = new apn.Provider({
          token: {
            key: process.env.APNS_PRIVATE_KEY_PATH,
            keyId: process.env.APNS_KEY_ID,
            teamId: process.env.APNS_TEAM_ID
          },
          production: process.env.APNS_ENVIRONMENT === 'production'
        });
        console.log('APNS Provider initialized successfully');
      }
    } catch (error) {
      console.error('Failed to initialize APNS Provider:', error.message);
    }
  }

  // Send prayer time notification
  async sendPrayerNotification(userPreferences, prayer, prayerTime) {
    try {
      const { notifications, deviceTokens, preferences } = userPreferences;
      
      if (!notifications[prayer]?.enabled) {
        return { success: false, message: 'Notification disabled for this prayer' };
      }

      const message = this.createPrayerMessage(prayer, prayerTime, preferences.language);
      const results = [];

      // Send to Android device
      if (deviceTokens.android) {
        const androidResult = await this.sendAndroidNotification(deviceTokens.android, message);
        results.push({ platform: 'android', ...androidResult });
      }

      // Send to iOS device
      if (deviceTokens.ios) {
        const iosResult = await this.sendIOSNotification(deviceTokens.ios, message);
        results.push({ platform: 'ios', ...iosResult });
      }

      return {
        success: true,
        message: 'Notifications sent',
        results
      };
    } catch (error) {
      console.error('Error sending prayer notification:', error);
      return {
        success: false,
        message: 'Failed to send notification',
        error: error.message
      };
    }
  }

  // Send event notification
  async sendEventNotification(userPreferences, event) {
    try {
      const { eventNotifications, deviceTokens, preferences } = userPreferences;
      
      if (!eventNotifications.enabled || !eventNotifications.categories[event.category]) {
        return { success: false, message: 'Event notifications disabled' };
      }

      const message = this.createEventMessage(event, preferences.language);
      const results = [];

      // Send to Android device
      if (deviceTokens.android) {
        const androidResult = await this.sendAndroidNotification(deviceTokens.android, message);
        results.push({ platform: 'android', ...androidResult });
      }

      // Send to iOS device
      if (deviceTokens.ios) {
        const iosResult = await this.sendIOSNotification(deviceTokens.ios, message);
        results.push({ platform: 'ios', ...iosResult });
      }

      return {
        success: true,
        message: 'Event notifications sent',
        results
      };
    } catch (error) {
      console.error('Error sending event notification:', error);
      return {
        success: false,
        message: 'Failed to send event notification',
        error: error.message
      };
    }
  }

  // Send Android notification via Firebase
  async sendAndroidNotification(token, message) {
    try {
      const payload = {
        notification: {
          title: message.title,
          body: message.body
        },
        data: {
          type: message.type,
          prayer: message.prayer || '',
          eventId: message.eventId || '',
          clickAction: message.clickAction || 'FLUTTER_NOTIFICATION_CLICK'
        },
        android: {
          notification: {
            icon: 'ic_mosque',
            color: '#4CAF50',
            sound: message.sound || 'default',
            channelId: message.channelId || 'prayer_notifications'
          },
          priority: 'high'
        },
        token
      };

      const response = await admin.messaging().send(payload);
      return {
        success: true,
        messageId: response,
        token: token.substring(0, 10) + '...'
      };
    } catch (error) {
      console.error('Android notification error:', error);
      return {
        success: false,
        error: error.message
      };
    }
  }

  // Send iOS notification via APNS
  async sendIOSNotification(token, message) {
    try {
      if (!this.apnProvider) {
        throw new Error('APNS Provider not initialized');
      }

      const notification = new apn.Notification();
      notification.alert = {
        title: message.title,
        body: message.body
      };
      notification.badge = 1;
      notification.sound = message.sound || 'default';
      notification.topic = process.env.APNS_BUNDLE_ID;
      notification.payload = {
        type: message.type,
        prayer: message.prayer || '',
        eventId: message.eventId || ''
      };

      const result = await this.apnProvider.send(notification, token);
      
      return {
        success: result.sent.length > 0,
        sent: result.sent.length,
        failed: result.failed.length,
        errors: result.failed.map(f => f.error)
      };
    } catch (error) {
      console.error('iOS notification error:', error);
      return {
        success: false,
        error: error.message
      };
    }
  }

  // Create prayer notification message
  createPrayerMessage(prayer, prayerTime, language = 'en') {
    const messages = {
      en: {
        fajr: { title: '🌅 Fajr Prayer Time', body: `Fajr prayer time is at ${prayerTime}. Prepare for prayer.` },
        dhuhr: { title: '☀️ Dhuhr Prayer Time', body: `Dhuhr prayer time is at ${prayerTime}. Time for midday prayer.` },
        asr: { title: '🌤️ Asr Prayer Time', body: `Asr prayer time is at ${prayerTime}. Afternoon prayer time.` },
        maghrib: { title: '🌅 Maghrib Prayer Time', body: `Maghrib prayer time is at ${prayerTime}. Sunset prayer time.` },
        isha: { title: '🌙 Isha Prayer Time', body: `Isha prayer time is at ${prayerTime}. Night prayer time.` },
        jumma: { title: '🕌 Jumma Prayer', body: `Jumma prayer is at ${prayerTime}. Don't miss the Friday congregation.` }
      },
      ar: {
        fajr: { title: '🌅 صلاة الفجر', body: `وقت صلاة الفجر ${prayerTime}. استعد للصلاة.` },
        dhuhr: { title: '☀️ صلاة الظهر', body: `وقت صلاة الظهر ${prayerTime}. وقت صلاة الظهيرة.` },
        asr: { title: '🌤️ صلاة العصر', body: `وقت صلاة العصر ${prayerTime}. وقت صلاة بعد الظهر.` },
        maghrib: { title: '🌅 صلاة المغرب', body: `وقت صلاة المغرب ${prayerTime}. وقت صلاة الغروب.` },
        isha: { title: '🌙 صلاة العشاء', body: `وقت صلاة العشاء ${prayerTime}. وقت صلاة الليل.` },
        jumma: { title: '🕌 صلاة الجمعة', body: `صلاة الجمعة ${prayerTime}. لا تفوت جماعة الجمعة.` }
      }
    };

    const prayerMessages = messages[language] || messages.en;
    const prayerMessage = prayerMessages[prayer] || prayerMessages.fajr;

    return {
      title: prayerMessage.title,
      body: prayerMessage.body,
      type: 'prayer_notification',
      prayer,
      sound: 'default',
      channelId: 'prayer_notifications',
      clickAction: 'OPEN_PRAYER_TIMES'
    };
  }

  // Create event notification message
  createEventMessage(event, language = 'en') {
    const eventMessages = {
      en: {
        title: `🕌 ${event.title}`,
        body: `${event.description}. ${event.date ? `Date: ${event.date}` : ''}`
      },
      ar: {
        title: `🕌 ${event.title}`,
        body: `${event.description}. ${event.date ? `التاريخ: ${event.date}` : ''}`
      }
    };

    const message = eventMessages[language] || eventMessages.en;

    return {
      title: message.title,
      body: message.body,
      type: 'event_notification',
      eventId: event._id,
      sound: 'default',
      channelId: 'event_notifications',
      clickAction: 'OPEN_EVENTS'
    };
  }

  // Send test notification
  async sendTestNotification(userPreferences, prayer = 'fajr') {
    const testMessage = {
      title: '🧪 Test Notification',
      body: 'This is a test notification from Central Mosque Rochdale app.',
      type: 'test_notification',
      prayer,
      sound: 'default',
      channelId: 'prayer_notifications',
      clickAction: 'OPEN_APP'
    };

    const results = [];
    const { deviceTokens } = userPreferences;

    // Send to Android device
    if (deviceTokens.android) {
      const androidResult = await this.sendAndroidNotification(deviceTokens.android, testMessage);
      results.push({ platform: 'android', ...androidResult });
    }

    // Send to iOS device
    if (deviceTokens.ios) {
      const iosResult = await this.sendIOSNotification(deviceTokens.ios, testMessage);
      results.push({ platform: 'ios', ...iosResult });
    }

    return {
      success: results.some(r => r.success),
      message: 'Test notification sent',
      results
    };
  }

  // Bulk send notifications to multiple users
  async sendBulkNotifications(userPreferencesList, message) {
    const results = [];
    
    for (const userPreferences of userPreferencesList) {
      try {
        const result = await this.sendEventNotification(userPreferences, message);
        results.push({
          userId: userPreferences.userId,
          ...result
        });
      } catch (error) {
        results.push({
          userId: userPreferences.userId,
          success: false,
          error: error.message
        });
      }
    }

    return {
      success: true,
      totalSent: results.filter(r => r.success).length,
      totalFailed: results.filter(r => !r.success).length,
      results
    };
  }
}

module.exports = new NotificationService();