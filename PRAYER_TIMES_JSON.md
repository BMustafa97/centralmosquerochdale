# Prayer Times JSON Guide

## Overview
The app now loads prayer times from a JSON file containing the entire year's prayer times. It automatically finds and displays today's prayer times.

## How It Works

### 1. JSON File Structure
Located at: `iOS/CentralMosqueRochdale/Resources/PrayerTimes2025.json`

```json
{
  "year": 2025,
  "mosque": "Central Mosque Rochdale",
  "location": {
    "latitude": 53.6097,
    "longitude": -2.1561
  },
  "prayerTimes": [
    {
      "date": "2025-11-12",
      "fajr": { "adhan": "05:30", "jamaah": "05:45" },
      "sunrise": "07:25",
      "dhuhr": { "adhan": "12:05", "jamaah": "12:45" },
      "asr": { "adhan": "14:15", "jamaah": "14:30" },
      "maghrib": { "adhan": "16:30", "jamaah": "16:35" },
      "isha": { "adhan": "18:15", "jamaah": "18:30" },
      "jummah": "13:00"
    }
  ]
}
```

### 2. Finding Today's Prayer Times

The `PrayerTimesService` class:

```swift
// Get today's date
let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "yyyy-MM-dd"
let todayString = dateFormatter.string(from: Date())

// Load JSON file
let url = Bundle.main.url(forResource: "PrayerTimes2025", withExtension: "json")
let data = try Data(contentsOf: url)
let yearlyData = try decoder.decode(YearlyPrayerTimes.self, from: data)

// Find today's entry
if let todaysPrayers = yearlyData.prayerTimes.first(where: { $0.date == todayString }) {
    // Convert to Prayer array and display
    self.prayers = convertToPrayerArray(todaysPrayers)
}
```

### 3. Key Functions

**`fetchPrayerTimes()`**
- Gets today's date in `yyyy-MM-dd` format
- Calls `loadPrayerTimesFromJSON()` to find matching entry

**`loadPrayerTimesFromJSON(for:)`**
- Loads the JSON file from bundle
- Decodes into `YearlyPrayerTimes` struct
- Uses `.first(where:)` to find matching date
- Falls back to mock data if date not found

**`convertToPrayerArray()`**
- Converts the day's prayer times into a `[Prayer]` array
- Maps adhan and jamaah times to the Prayer model

### 4. Adding More Dates

To add the full year's prayer times:

1. Generate or obtain prayer times for all 365 days
2. Format each day as:
```json
{
  "date": "2025-MM-DD",
  "fajr": { "adhan": "HH:MM", "jamaah": "HH:MM" },
  "sunrise": "HH:MM",
  "dhuhr": { "adhan": "HH:MM", "jamaah": "HH:MM" },
  "asr": { "adhan": "HH:MM", "jamaah": "HH:MM" },
  "maghrib": { "adhan": "HH:MM", "jamaah": "HH:MM" },
  "isha": { "adhan": "HH:MM", "jamaah": "HH:MM" },
  "jummah": "HH:MM"
}
```
3. Add to the `prayerTimes` array in the JSON file

### 5. Adding to Xcode Project

**IMPORTANT:** The JSON file must be added to the Xcode project:

1. Drag `PrayerTimes2025.json` into the Xcode project navigator
2. In the dialog, ensure:
   - ✅ "Copy items if needed" is checked
   - ✅ "Add to targets" has your app target selected
   - ✅ File appears in your bundle
3. Verify by checking Build Phases → Copy Bundle Resources

### 6. Benefits

✅ **Offline-first**: Works without internet connection
✅ **Fast**: No API calls needed
✅ **Accurate**: Pre-calculated times for your exact location
✅ **Predictable**: Always shows correct times for the date
✅ **Fallback**: Uses mock data if date not found

### 7. Future Enhancements

- Generate JSON from prayer time calculation APIs
- Support multiple years (e.g., PrayerTimes2025.json, PrayerTimes2026.json)
- Add hijri date alongside gregorian date
- Cache mechanism for faster subsequent loads
- Manual refresh to update times if needed

### 8. Testing

To test with different dates:
```swift
// In PrayerTimesService, temporarily change:
let todayString = "2025-11-12" // Test specific date
```

Or use the simulator's date settings to change the system date.
