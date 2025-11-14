# AWS S3 Prayer Times Integration

## Overview
The app now loads prayer times from AWS S3, allowing for dynamic updates without requiring an app update. The system prioritizes fresh data from S3 while maintaining offline capability through local caching.

## Architecture

### Data Flow Priority
1. **S3 First**: Always attempts to download fresh data from S3
2. **Cache Fallback**: If S3 fails, loads from local cache in Documents directory
3. **Bundle Fallback**: Uses bundled JSON if both S3 and cache are unavailable
4. **Auto-Cache**: Successful S3 downloads are automatically cached for offline use

### Components

#### PrayerTimesManager.swift
Location: `iOS/CentralMosqueRochdale/Services/PrayerTimesManager.swift`

**Key Features:**
- Singleton pattern for centralized management
- S3-first approach ensures fresh data
- Async data loading with completion handlers
- Automatic cache management
- Multi-layer fallback system
- Offline capability through caching

**Public Methods:**
```swift
// Load prayer times with automatic S3/cache management
func loadPrayerTimes(completion: @escaping (Result<YearlyPrayerTimes, Error>) -> Void)

// Clear cached data
func clearCache()
```

## S3 Configuration

### S3 Bucket Details
- **URL**: `https://central-mosque-prayer-times.s3.eu-west-1.amazonaws.com/PrayerTimes2025.json`
- **Region**: `eu-west-1` (Ireland)
- **Bucket Name**: `central-mosque-prayer-times`
- **File**: `PrayerTimes2025.json`
- **Access**: Public (read-only)

### Cache Location
- **Path**: `Documents/PrayerTimes2025_cached.json`
- **Persistence**: Survives app restarts
- **Updates**: Automatic background refresh

## How It Works

### Every Launch
1. App attempts to download from S3
2. If successful:
   - Shows latest prayer times
   - Saves to cache for offline use
3. If S3 fails (no internet/server down):
   - Loads from cache (if available)
   - Falls back to bundled JSON
   - User still sees prayer times

### First Launch (No Cache)
1. Downloads from S3
2. Saves to Documents directory
3. Shows prayer times
4. If S3 unavailable, uses bundled JSON

### Offline Mode
1. S3 download fails (no internet)
2. Loads from cache immediately
3. Works completely offline
4. No error shown to users (seamless fallback)

## Benefits

### ✅ For Users
- **Always Fresh**: Gets latest times from S3 on every launch
- **Offline Support**: Works without internet using cache
- **No Disruption**: Seamless fallback if S3 unavailable
- **Reliable**: Multiple fallback layers ensure app always works

### ✅ For Administrators
- **Easy Updates**: Just update S3 file
- **Immediate**: Users get updates on next app launch
- **No App Release**: Changes without App Store review
- **Version Control**: Can maintain yearly files (2025, 2026, etc.)
- **Monitoring**: S3 provides access logs

### ✅ For Developers
- **Clean Architecture**: Separation of concerns
- **Error Handling**: Multiple fallback layers
- **Testable**: Service layer is isolated
- **Maintainable**: Single source of truth
- **S3-First**: Always try to get fresh data

## Updating Prayer Times

### Process
1. Update `PrayerTimes2025.json` locally
2. Upload to S3 bucket
3. Users get updated times on next app launch
4. Cache automatically updates with fresh data

### S3 Upload Command
```bash
aws s3 cp PrayerTimes2025.json s3://central-mosque-prayer-times/ \
  --acl public-read \
  --region eu-west-1
```

### Verification
```bash
# Verify file is public and accessible
curl https://central-mosque-prayer-times.s3.eu-west-1.amazonaws.com/PrayerTimes2025.json

# Check file size
aws s3 ls s3://central-mosque-prayer-times/PrayerTimes2025.json --human-readable
```

## Console Logs

The manager provides helpful logging:

- `⬇️ Downloading prayer times from S3...` - S3 download started
- `✅ Successfully downloaded and cached prayer times from S3` - Download complete
- `💾 Prayer times cached to: [path]` - Cache saved
- `📱 Using cached prayer times as fallback` - S3 failed, using cache
- `📦 Using bundled prayer times as fallback` - S3 and cache failed, using bundle
- `✅ Loaded prayer times from cache` - Cache loaded successfully
- `✅ Loaded prayer times from bundle` - Bundle loaded successfully
- `❌ Error loading cached prayer times` - Cache corrupted, will try S3 or bundle

## Error Handling

### PrayerTimesError
```swift
enum PrayerTimesError: LocalizedError {
    case invalidURL        // S3 URL malformed
    case invalidResponse   // HTTP error (404, 500, etc.)
    case noData           // Empty response
    case noDataAvailable  // All sources failed
}
```

### Fallback Chain
1. S3 fails → Try cache
2. Cache fails → Use bundled JSON
3. Bundle fails → Show error to user

## Migration from Local JSON

### Before (Local Only)
```swift
guard let url = Bundle.main.url(forResource: "PrayerTimes2025", withExtension: "json") else {
    return
}
let data = try Data(contentsOf: url)
// Parse and display
```

### After (S3-First + Cache + Fallback)
```swift
PrayerTimesManager.shared.loadPrayerTimes { result in
    switch result {
    case .success(let data):
        // Parse and display - always fresh from S3 if available
    case .failure(let error):
        // Handle error - very rare (all sources failed)
    }
}
```

## Testing

### Test Scenarios

1. **Fresh Install (With Internet)**
   - Delete app
   - Reinstall
   - Verify S3 download
   - Check cache is created

2. **Fresh Install (No Internet)**
   - Enable Airplane Mode
   - Install app
   - Verify bundled JSON loads
   - No errors shown

3. **Launch with Internet**
   - Launch app
   - Verify S3 download
   - Check cache updated
   - Times displayed

4. **Launch Offline (With Cache)**
   - Turn off internet
   - Launch app
   - Verify cache loads
   - Times still display

5. **Corrupted Cache**
   - Manually corrupt cache file
   - Launch with internet
   - Verify S3 download works
   - Cache recreated

6. **S3 Unavailable (With Cache)**
   - Block S3 URL
   - Launch app
   - Verify cache loads
   - No error to user

### Debug Commands

```bash
# View cache file
cat ~/Library/Developer/CoreSimulator/Devices/[DEVICE]/data/Containers/Data/Application/[APP]/Documents/PrayerTimes2025_cached.json

# Delete cache for testing
rm ~/Library/Developer/CoreSimulator/Devices/[DEVICE]/data/Containers/Data/Application/[APP]/Documents/PrayerTimes2025_cached.json
```

## Future Enhancements

### Possible Improvements
- [ ] Add cache expiry time (e.g., 24 hours)
- [ ] Version checking (only download if newer)
- [ ] ETag support for conditional requests
- [ ] Compression (gzip)
- [ ] Multiple year support (2025, 2026, etc.)
- [ ] Analytics on S3 downloads
- [ ] Admin panel to update S3 directly

### Advanced Features
- [ ] CloudFront CDN for global distribution
- [ ] Lambda function for dynamic generation
- [ ] API Gateway for versioning
- [ ] User notification when times update
- [ ] Diff checking (only notify if times changed)

## Security

### Current Setup
- Public read-only access
- No authentication required
- HTTPS enforced

### Considerations
- Data is not sensitive (public prayer times)
- No PII (Personally Identifiable Information)
- Read-only prevents tampering
- Can add CloudFront for DDoS protection

## Cost Analysis

### AWS S3 Pricing (eu-west-1)
- **Storage**: ~0.023 USD per GB/month
- **Requests**: ~0.0004 USD per 1,000 GET requests
- **Data Transfer**: ~0.09 USD per GB (first 10TB)

### Estimated Monthly Cost
- File size: ~50 KB
- Users: 1,000 active
- Downloads per user: 30/month (daily background updates)
- Total requests: 30,000/month
- **Total Cost**: < $0.05/month (~5 cents)

### CloudFront (Optional)
- Could reduce to ~$0.01/month
- Better global performance
- DDoS protection included

## Monitoring

### S3 Metrics to Watch
- **Total Requests**: Track app usage
- **Error Rate**: 4xx, 5xx responses
- **Download Size**: Verify file integrity
- **Geographic Distribution**: Where users are

### Setting Up Alerts
1. Enable S3 Server Access Logging
2. Use CloudWatch for monitoring
3. Set alerts for high error rates
4. Track bandwidth usage

## Support

### Troubleshooting

**Prayer times not updating?**
- Check S3 file is uploaded
- Verify public-read permission
- Check app has internet permission
- Clear cache and relaunch

**App showing old times?**
- Cache might be stale
- Force close and relaunch app
- Background update will sync

**Can't download from S3?**
- Check S3 bucket permissions
- Verify URL is accessible
- App will use bundled fallback

### Contact
For issues with S3 integration, check:
1. Console logs in Xcode
2. S3 bucket permissions
3. Network connectivity
4. Cache file integrity
