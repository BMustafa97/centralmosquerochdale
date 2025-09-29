# 🚀 Quick Run Guide - Central Mosque Rochdale App

This is a simplified guide to get the apps running quickly for UI testing.

## Prerequisites ✅
Make sure you've run the setup script first:
```bash
chmod +x setup-local.sh
./setup-local.sh
```

---

## 📱 iOS App - Quick Start

### Option 1: Xcode (Recommended for UI Testing)
```bash
# Navigate to project directory
cd /Users/bilal.mustafa/personal/centralmosquerochdale

# Open project in Xcode
open iOS/CentralMosqueRochdale.xcodeproj

# In Xcode:
# 1. Select iPhone 15 simulator from the device menu
# 2. Press Cmd+R (or click the Play button)
# 3. The app will build and launch in simulator
```

### Option 2: Command Line
```bash
cd /Users/bilal.mustafa/personal/centralmosquerochdale/iOS

# List available simulators to find the right one
xcrun simctl list devices available | grep iPhone

# Pick any available iPhone simulator (example output will show available ones)
# Boot a simulator (replace with an available iPhone from the list above)
xcrun simctl boot "iPhone 14"  # or whatever iPhone is available

# Build with generic iOS Simulator destination (works with any available simulator)
xcodebuild -project CentralMosqueRochdale.xcodeproj -scheme CentralMosqueRochdale -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build

# Alternative: Build for any available iPhone simulator
xcodebuild -project CentralMosqueRochdale.xcodeproj -scheme CentralMosqueRochdale -sdk iphonesimulator build
```

---

## 🤖 Android App - Quick Start

### Option 1: Android Studio (Recommended for UI Testing)
```bash
# Navigate to project directory
cd /Users/bilal.mustafa/personal/centralmosquerochdale

# Open project in Android Studio
open -a "Android Studio" Android/

# In Android Studio:
# 1. Wait for Gradle sync to complete
# 2. Select an emulator or connect a device
# 3. Click the green Run button (or press Ctrl+R)
# 4. The app will build and launch
```

### Option 2: Command Line
```bash
cd /Users/bilal.mustafa/personal/centralmosquerochdale/Android

# Start an emulator (in background)
$ANDROID_HOME/emulator/emulator -avd Pixel_7_API_34 &

# Wait for emulator to boot (30-60 seconds)
adb wait-for-device

# Build and install the app
./gradlew installDebug

# Launch the app
adb shell am start -n com.centralmosque.rochdale/.MainActivity
```

---

## 🎯 What You'll See - App Features

### 📱 iOS App Features:
- **Prayer Times Tab**: Table showing 5 daily prayers with times
- **Qibla Tab**: Compass pointing to Mecca
- **Events Tab**: Mosque events and announcements
- **Settings Tab**: Notification preferences

### 🤖 Android App Features:
- **Prayer Times Screen**: Material Design prayer schedule
- **Qibla Compass**: Interactive compass with Qibla direction
- **Events Screen**: Community events with subscription options
- **Notification Settings**: Push notification toggles

---

## 🔧 Quick Troubleshooting

### iOS Issues:
```bash
# If "device not found" error occurs:
# 1. List available simulators first
xcrun simctl list devices available | grep iPhone

# 2. Use any available simulator from the list
xcrun simctl boot "iPhone 14"  # or whatever is available

# 3. Build without specifying exact device
xcodebuild -project CentralMosqueRochdale.xcodeproj -scheme CentralMosqueRochdale -sdk iphonesimulator build

# If build fails due to iOS version mismatch:
# Open Xcode, go to Settings > Components and install the required iOS simulator

# If simulator doesn't appear
xcrun simctl list devices | grep Booted

# If app doesn't launch
# Check if simulator is running, restart if needed
```

### Android Issues:
```bash
# If emulator won't start
$ANDROID_HOME/emulator/emulator -list-avds
# Use one of the listed AVDs

# If build fails
cd Android
./gradlew clean
./gradlew build

# If app won't install
adb uninstall com.centralmosque.rochdale
./gradlew installDebug
```

---

## 📝 UI Testing Checklist

Once the apps are running, test these features:

### ✅ iOS Testing:
- [ ] Tap between tabs (Prayer Times, Qibla, Events, Settings)
- [ ] Scroll through prayer times table
- [ ] Test Qibla compass rotation (if on device)
- [ ] Browse events list and tap details
- [ ] Toggle notification settings

### ✅ Android Testing:
- [ ] Navigate between screens using bottom navigation
- [ ] Test prayer times scrolling and refresh
- [ ] Interact with Qibla compass
- [ ] Browse events and test subscription toggles
- [ ] Test notification settings switches

---

## ⚡ Super Quick Commands

### Start iOS App (30 seconds):
```bash
cd /Users/bilal.mustafa/personal/centralmosquerochdale
open iOS/CentralMosqueRochdale.xcodeproj
# Then press Cmd+R in Xcode
```

### Start Android App (60 seconds):
```bash
cd /Users/bilal.mustafa/personal/centralmosquerochdale
open -a "Android Studio" Android/
# Then click Run button in Android Studio
```

---

## 📱 Expected UI Overview

Both apps feature:
- **Modern Design**: SwiftUI (iOS) and Material Design 3 (Android)
- **Navigation**: Tab-based (iOS) and bottom navigation (Android)
- **Prayer Times**: Clean table/list with Islamic prayer schedule
- **Qibla Compass**: Visual compass for prayer direction
- **Events System**: Community events with admin controls
- **Notifications**: Push notification management

The apps should look professional and ready for production use! 🚀

---

## 🆘 Need Help?

- **Quick fixes**: See troubleshooting section above
- **Detailed setup**: Check `LOCAL_DEVELOPMENT.md`
- **Code issues**: Open the project in respective IDEs for detailed error messages

Happy testing! 🕌