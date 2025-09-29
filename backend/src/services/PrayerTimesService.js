const axios = require('axios');

class PrayerTimesService {
  constructor() {
    this.API_BASE_URL = 'https://api.aladhan.com/v1';
    this.DEFAULT_METHOD = 2; // Islamic Society of North America (ISNA)
    this.cache = new Map();
    this.CACHE_DURATION = 24 * 60 * 60 * 1000; // 24 hours in milliseconds
  }

  // Get prayer times for a specific date and location
  async getPrayerTimes(latitude, longitude, date = null, method = null, timezone = null) {
    try {
      const requestDate = date || this.getCurrentDate();
      const calculationMethod = method || this.DEFAULT_METHOD;
      const cacheKey = `${latitude}-${longitude}-${requestDate}-${calculationMethod}`;

      // Check cache first
      if (this.cache.has(cacheKey)) {
        const cached = this.cache.get(cacheKey);
        if (Date.now() - cached.timestamp < this.CACHE_DURATION) {
          return cached.data;
        }
        this.cache.delete(cacheKey);
      }

      const params = {
        latitude,
        longitude,
        method: calculationMethod,
        date: requestDate
      };

      if (timezone) {
        params.timezonestring = timezone;
      }

      const response = await axios.get(`${this.API_BASE_URL}/timings/${requestDate}`, {
        params,
        timeout: 10000
      });

      if (response.data.code !== 200) {
        throw new Error('Failed to fetch prayer times from API');
      }

      const prayerData = this.formatPrayerTimes(response.data.data);
      
      // Cache the result
      this.cache.set(cacheKey, {
        data: prayerData,
        timestamp: Date.now()
      });

      return prayerData;
    } catch (error) {
      console.error('Error fetching prayer times:', error.message);
      throw new Error(`Unable to fetch prayer times: ${error.message}`);
    }
  }

  // Get prayer times for current month
  async getMonthlyPrayerTimes(latitude, longitude, year = null, month = null, method = null) {
    try {
      const currentDate = new Date();
      const requestYear = year || currentDate.getFullYear();
      const requestMonth = month || (currentDate.getMonth() + 1);
      const calculationMethod = method || this.DEFAULT_METHOD;
      
      const cacheKey = `monthly-${latitude}-${longitude}-${requestYear}-${requestMonth}-${calculationMethod}`;

      // Check cache first
      if (this.cache.has(cacheKey)) {
        const cached = this.cache.get(cacheKey);
        if (Date.now() - cached.timestamp < this.CACHE_DURATION) {
          return cached.data;
        }
        this.cache.delete(cacheKey);
      }

      const response = await axios.get(`${this.API_BASE_URL}/calendar/${requestYear}/${requestMonth}`, {
        params: {
          latitude,
          longitude,
          method: calculationMethod
        },
        timeout: 15000
      });

      if (response.data.code !== 200) {
        throw new Error('Failed to fetch monthly prayer times from API');
      }

      const monthlyData = response.data.data.map(dayData => ({
        date: dayData.date.readable,
        gregorianDate: dayData.date.gregorian.date,
        hijriDate: dayData.date.hijri.date,
        prayers: this.formatPrayerTimes(dayData).prayers
      }));

      // Cache the result
      this.cache.set(cacheKey, {
        data: monthlyData,
        timestamp: Date.now()
      });

      return monthlyData;
    } catch (error) {
      console.error('Error fetching monthly prayer times:', error.message);
      throw new Error(`Unable to fetch monthly prayer times: ${error.message}`);
    }
  }

  // Get Qibla direction for given coordinates
  async getQiblaDirection(latitude, longitude) {
    try {
      const cacheKey = `qibla-${latitude}-${longitude}`;

      // Check cache first (Qibla direction doesn't change)
      if (this.cache.has(cacheKey)) {
        return this.cache.get(cacheKey).data;
      }

      const response = await axios.get(`${this.API_BASE_URL}/qibla/${latitude}/${longitude}`, {
        timeout: 10000
      });

      if (response.data.code !== 200) {
        throw new Error('Failed to fetch Qibla direction from API');
      }

      const qiblaData = {
        direction: response.data.data.direction,
        latitude: response.data.data.latitude,
        longitude: response.data.data.longitude
      };

      // Cache permanently (Qibla direction doesn't change)
      this.cache.set(cacheKey, {
        data: qiblaData,
        timestamp: Date.now()
      });

      return qiblaData;
    } catch (error) {
      console.error('Error fetching Qibla direction:', error.message);
      throw new Error(`Unable to fetch Qibla direction: ${error.message}`);
    }
  }

  // Get current Islamic date
  async getIslamicDate(latitude = 51.5074, longitude = -0.1278) {
    try {
      const cacheKey = `islamic-date-${this.getCurrentDate()}`;

      // Check cache first
      if (this.cache.has(cacheKey)) {
        const cached = this.cache.get(cacheKey);
        if (Date.now() - cached.timestamp < this.CACHE_DURATION) {
          return cached.data;
        }
        this.cache.delete(cacheKey);
      }

      const response = await axios.get(`${this.API_BASE_URL}/timings/${this.getCurrentDate()}`, {
        params: {
          latitude,
          longitude,
          method: this.DEFAULT_METHOD
        },
        timeout: 10000
      });

      if (response.data.code !== 200) {
        throw new Error('Failed to fetch Islamic date from API');
      }

      const islamicData = {
        hijri: response.data.data.date.hijri,
        gregorian: response.data.data.date.gregorian
      };

      // Cache the result
      this.cache.set(cacheKey, {
        data: islamicData,
        timestamp: Date.now()
      });

      return islamicData;
    } catch (error) {
      console.error('Error fetching Islamic date:', error.message);
      throw new Error(`Unable to fetch Islamic date: ${error.message}`);
    }
  }

  // Get next prayer time
  getNextPrayer(prayerTimes) {
    try {
      const now = new Date();
      const currentTime = now.toTimeString().slice(0, 5); // HH:MM format
      
      const prayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
      
      for (const prayer of prayers) {
        const prayerTime = prayerTimes.prayers[prayer];
        if (this.timeToMinutes(prayerTime) > this.timeToMinutes(currentTime)) {
          return {
            prayer,
            time: prayerTime,
            remaining: this.calculateTimeRemaining(currentTime, prayerTime)
          };
        }
      }

      // If no prayer found for today, return Fajr for tomorrow
      return {
        prayer: 'fajr',
        time: prayerTimes.prayers.fajr,
        remaining: 'Tomorrow',
        isTomorrow: true
      };
    } catch (error) {
      console.error('Error calculating next prayer:', error.message);
      return null;
    }
  }

  // Check if it's currently prayer time (within alert window)
  isPrayerTime(prayerTimes, alertMinutes = 5) {
    try {
      const now = new Date();
      const currentMinutes = this.timeToMinutes(now.toTimeString().slice(0, 5));
      
      const prayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
      
      for (const prayer of prayers) {
        const prayerMinutes = this.timeToMinutes(prayerTimes.prayers[prayer]);
        const diff = Math.abs(currentMinutes - prayerMinutes);
        
        if (diff <= alertMinutes) {
          return {
            isPrayerTime: true,
            prayer,
            time: prayerTimes.prayers[prayer],
            minutesUntil: prayerMinutes - currentMinutes
          };
        }
      }

      return { isPrayerTime: false };
    } catch (error) {
      console.error('Error checking prayer time:', error.message);
      return { isPrayerTime: false };
    }
  }

  // Format prayer times response
  formatPrayerTimes(data) {
    const timings = data.timings;
    
    return {
      date: {
        readable: data.date.readable,
        gregorian: data.date.gregorian,
        hijri: data.date.hijri
      },
      prayers: {
        fajr: this.formatTime(timings.Fajr),
        sunrise: this.formatTime(timings.Sunrise),
        dhuhr: this.formatTime(timings.Dhuhr),
        asr: this.formatTime(timings.Asr),
        maghrib: this.formatTime(timings.Maghrib),
        isha: this.formatTime(timings.Isha),
        jumma: this.formatTime(timings.Dhuhr) // Friday prayer at Dhuhr time
      },
      meta: data.meta || {}
    };
  }

  // Format time string (remove timezone info)
  formatTime(timeString) {
    return timeString.split(' ')[0]; // Remove timezone part
  }

  // Convert time to minutes for comparison
  timeToMinutes(timeString) {
    const [hours, minutes] = timeString.split(':').map(Number);
    return hours * 60 + minutes;
  }

  // Calculate time remaining between two times
  calculateTimeRemaining(currentTime, targetTime) {
    const currentMinutes = this.timeToMinutes(currentTime);
    const targetMinutes = this.timeToMinutes(targetTime);
    
    let diff = targetMinutes - currentMinutes;
    if (diff < 0) {
      diff += 24 * 60; // Add 24 hours if target is tomorrow
    }
    
    const hours = Math.floor(diff / 60);
    const minutes = diff % 60;
    
    if (hours > 0) {
      return `${hours}h ${minutes}m`;
    }
    return `${minutes}m`;
  }

  // Get current date in DD-MM-YYYY format
  getCurrentDate() {
    const now = new Date();
    const day = String(now.getDate()).padStart(2, '0');
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const year = now.getFullYear();
    return `${day}-${month}-${year}`;
  }

  // Get calculation methods
  getCalculationMethods() {
    return {
      1: 'University of Islamic Sciences, Karachi',
      2: 'Islamic Society of North America (ISNA)',
      3: 'Muslim World League',
      4: 'Umm Al-Qura University, Makkah',
      5: 'Egyptian General Authority of Survey',
      7: 'Institute of Geophysics, University of Tehran',
      8: 'Gulf Region',
      9: 'Kuwait',
      10: 'Qatar',
      11: 'Majlis Ugama Islam Singapura, Singapore',
      12: 'Union Organization Islamic de France',
      13: 'Diyanet İşleri Başkanlığı, Turkey',
      14: 'Spiritual Administration of Muslims of Russia'
    };
  }

  // Clear cache
  clearCache() {
    this.cache.clear();
    console.log('Prayer times cache cleared');
  }

  // Get cache stats
  getCacheStats() {
    return {
      totalEntries: this.cache.size,
      entries: Array.from(this.cache.keys())
    };
  }
}

module.exports = new PrayerTimesService();