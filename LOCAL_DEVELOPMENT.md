# Local Development Setup - Central Mosque Rochdale App

This guide provides step-by-step instructions to run the Central Mosque Rochdale mobile app locally on both iOS and Android platforms.

## 🚀 Automated Setup (Recommended)

For a fully automated setup that checks and installs all prerequisites:

```bash
# Make the setup script executable and run it
chmod +x setup-local.sh
./setup-local.sh
```

This script will:
- ✅ Check and install Homebrew
- ✅ Install Xcode Command Line Tools
- ✅ Verify Xcode installation
- ✅ Install Java (for Android development)
- ✅ Install Android Studio
- ✅ Set up Android SDK environment variables
- ✅ Install Node.js and Firebase CLI
- ✅ Create proper iOS and Android project structures
- ✅ Test basic build functionality

**After running the script, restart your terminal and proceed to the Quick Start section below.**

### 🔧 Setup Script Troubleshooting

If the automated setup encounters issues:

```bash
# Make sure you have internet connection
ping google.com

# If "simctl not found" error occurs:
# 1. Install Xcode from App Store first:
open "macappstore://itunes.apple.com/app/xcode/id497799835"

# 2. After Xcode installation, install Command Line Tools:
sudo xcode-select --install

# 3. Set correct developer directory:
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

# 4. Verify simctl is working:
xcrun simctl help

# If Homebrew installation fails, install manually:
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# If Android Studio setup fails, install manually:
brew install --cask android-studio

# If path issues occur, try creating directories manually:
mkdir -p iOS/CentralMosqueRochdale/Views
mkdir -p "iOS/CentralMosqueRochdale/Preview Content"
mkdir -p Android/app/src/main/java/com/centralmosque/rochdale

# Re-run the setup script after fixing issues:
./setup-local.sh
```

---

## 📖 Manual Setup Instructions

If you prefer manual setup or need to troubleshoot specific issues, follow the detailed instructions below.

## 🍎 iOS Development Setup

### Prerequisites
```bash
# Check if Xcode is installed
xcode-select --version

# Check if Xcode Command Line Tools are installed
xcode-select --install

# Check Swift version
swift --version

# Check if iOS Simulator is available
xcrun simctl list devices
```

### Project Setup
```bash
# Navigate to the project directory
cd /Users/bilal.mustafa/personal/centralmosquerochdale

# Create iOS project structure
mkdir -p iOS/CentralMosqueRochdale.xcodeproj
mkdir -p iOS/CentralMosqueRochdale
mkdir -p iOS/CentralMosqueRochdale/Views
mkdir -p iOS/CentralMosqueRochdale/Models
mkdir -p iOS/CentralMosqueRochdale/Services

# Copy SwiftUI files to iOS project
cp SwiftUI/*.swift iOS/CentralMosqueRochdale/Views/
cp iOS/Info.plist iOS/CentralMosqueRochdale/
```

### Running on iOS Simulator
```bash
# Open Xcode project
open iOS/CentralMosqueRochdale.xcodeproj

# Alternative: Create and run via command line
cd iOS

# Create a new iOS project (if not already created)
# This would typically be done through Xcode GUI, but for reference:
# File -> New -> Project -> iOS -> App -> SwiftUI

# Build the project
xcodebuild -project CentralMosqueRochdale.xcodeproj -scheme CentralMosqueRochdale -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' build

# Run on simulator (recommended: use Xcode instead)
# First, make sure simctl is working:
xcrun simctl help

# If simctl error occurs, fix with:
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

# Build the project
xcodebuild -project CentralMosqueRochdale.xcodeproj -scheme CentralMosqueRochdale -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' build

# Note: For actual app installation and launch, it's easier to use Xcode:
# open iOS/CentralMosqueRochdale.xcodeproj
# Then press Cmd+R to build and run
```

### iOS Simulator Commands
```bash
# List available simulators
xcrun simctl list devices

# Boot a specific simulator
xcrun simctl boot "iPhone 15"

# Install app on simulator (after building)
xcrun simctl install booted path/to/your/app.app

# Launch app on simulator
xcrun simctl launch booted com.centralmosque.rochdale
```

## 🤖 Android Development Setup

### Prerequisites
```bash
# Check if Java is installed (Android requires Java 11+)
java -version

# Check if Android Studio is installed
which android-studio

# Check if Android SDK is installed
which adb
adb version

# Check available Android SDK platforms
$ANDROID_HOME/tools/bin/sdkmanager --list | grep "system-images"
```

### Environment Setup
```bash
# Set up Android environment variables (add to ~/.zshrc or ~/.bash_profile)
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools

# Reload shell configuration
source ~/.zshrc
```

### Project Setup
```bash
# Navigate to project directory
cd /Users/bilal.mustafa/personal/centralmosquerochdale

# Create Android project structure
mkdir -p Android/app/src/main/java/com/centralmosque/rochdale
mkdir -p Android/app/src/main/java/com/centralmosque/rochdale/ui/prayer
mkdir -p Android/app/src/main/java/com/centralmosque/rochdale/ui/qibla
mkdir -p Android/app/src/main/java/com/centralmosque/rochdale/ui/notifications
mkdir -p Android/app/src/main/java/com/centralmosque/rochdale/ui/events
mkdir -p Android/app/src/main/res/values
mkdir -p Android/app/src/main/res/layout

# Copy Android files
cp JetpackCompose/*.kt Android/app/src/main/java/com/centralmosque/rochdale/ui/
cp Android/AndroidManifest.xml Android/app/src/main/
cp Android/build.gradle Android/app/
```

### Create Android Project Files
```bash
# Create project-level build.gradle
cat > Android/build.gradle << 'EOF'
buildscript {
    ext {
        compose_version = '1.5.4'
        kotlin_version = '1.9.10'
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.1.2'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
        classpath 'com.google.gms:google-services:4.4.0'
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
EOF

# Create settings.gradle
cat > Android/settings.gradle << 'EOF'
rootProject.name = "Central Mosque Rochdale"
include ':app'
EOF

# Create gradle.properties
cat > Android/gradle.properties << 'EOF'
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
android.useAndroidX=true
android.enableJetifier=true
kotlin.code.style=official
android.nonTransitiveRClass=true
EOF
```

### Running on Android Emulator
```bash
# List available AVDs (Android Virtual Devices)
$ANDROID_HOME/emulator/emulator -list-avds

# Create a new AVD if none exist
$ANDROID_HOME/tools/bin/avdmanager create avd -n "Pixel_7_API_34" -k "system-images;android-34;google_apis;x86_64" -d "pixel_7"

# Start Android emulator
$ANDROID_HOME/emulator/emulator -avd Pixel_7_API_34 &

# Navigate to Android project directory
cd Android

# Clean and build the project
./gradlew clean
./gradlew build

# Install debug APK on emulator/device
./gradlew installDebug

# Run the app
./gradlew run

# Or build and install in one command
./gradlew installDebug && adb shell am start -n com.centralmosque.rochdale/.MainActivity
```

### Alternative Android Studio Commands
```bash
# Open project in Android Studio
open -a "Android Studio" Android/

# From Android Studio terminal, you can also run:
./gradlew assembleDebug
./gradlew connectedAndroidTest
```

## 🔥 Firebase Setup (Required for Android Notifications)

### Firebase Configuration
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in your project
cd Android
firebase init

# Select the following features when prompted:
# - Hosting
# - Cloud Messaging
# - Analytics (optional)

# Download google-services.json from Firebase Console
# Place it in Android/app/ directory
```

## 🛠️ Development Tools & Debugging

### iOS Debugging
```bash
# View iOS device logs
xcrun simctl spawn booted log stream --predicate 'subsystem contains "com.centralmosque.rochdale"'

# Debug with lldb
lldb
# Then attach to your app process

# Profile with Instruments
instruments -t "Time Profiler" -D trace_output.trace YourApp.app
```

### Android Debugging
```bash
# View Android logs
adb logcat | grep "CentralMosque"

# Monitor app performance
adb shell top | grep com.centralmosque.rochdale

# Debug with ADB
adb shell
# Then navigate to your app's data directory

# View installed packages
adb shell pm list packages | grep centralmosque
```

## 🧪 Testing Commands

### iOS Testing
```bash
# Run unit tests (if test target exists)
xcodebuild test -project iOS/CentralMosqueRochdale.xcodeproj -scheme CentralMosqueRochdale -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' || echo "No test targets configured"

# Build and run app instead of testing
xcodebuild -project iOS/CentralMosqueRochdale.xcodeproj -scheme CentralMosqueRochdale -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' build
```

### Android Testing
```bash
cd Android

# Run unit tests
./gradlew test

# Run instrumented tests
./gradlew connectedAndroidTest

# Run specific test class
./gradlew test --tests "com.centralmosque.rochdale.PrayerTimesTest"
```

## 🚀 Building for Release

### iOS Release Build
```bash
# Archive for App Store
xcodebuild archive -project iOS/CentralMosqueRochdale.xcodeproj -scheme CentralMosqueRochdale -destination generic/platform=iOS -archivePath build/CentralMosqueRochdale.xcarchive

# Export IPA
xcodebuild -exportArchive -archivePath build/CentralMosqueRochdale.xcarchive -exportPath build/ -exportOptionsPlist ExportOptions.plist
```

### Android Release Build
```bash
cd Android

# Generate signed APK
./gradlew assembleRelease

# Generate signed Bundle (recommended for Play Store)
./gradlew bundleRelease

# The outputs will be in:
# APK: app/build/outputs/apk/release/
# Bundle: app/build/outputs/bundle/release/
```

## 🔧 Troubleshooting

### Common iOS Issues
```bash
# Clean build folder
rm -rf ~/Library/Developer/Xcode/DerivedData/

# Reset iOS Simulator
xcrun simctl erase all

# Fix codesigning issues
security find-identity -v -p codesigning
```

### Common Android Issues
```bash
# Clean Gradle cache
cd Android
./gradlew clean
rm -rf ~/.gradle/caches/

# Reset ADB
adb kill-server
adb start-server

# Fix emulator issues
$ANDROID_HOME/emulator/emulator -avd YOUR_AVD_NAME -wipe-data
```

### Dependency Issues
```bash
# iOS: Update CocoaPods (if using)
cd iOS
pod install --repo-update

# Android: Refresh dependencies
cd Android
./gradlew --refresh-dependencies
```

## 📱 Quick Start Commands

### iOS Quick Start
```bash
# After running setup-local.sh:
cd /Users/bilal.mustafa/personal/centralmosquerochdale

# Option 1: Open in Xcode (Recommended)
open iOS/CentralMosqueRochdale.xcodeproj
# Then build and run from Xcode (Cmd+R)

# Option 2: Command line build
cd iOS
xcodebuild -project CentralMosqueRochdale.xcodeproj -scheme CentralMosqueRochdale -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' build
```

### Android Quick Start
```bash
# After running setup-local.sh:
cd /Users/bilal.mustafa/personal/centralmosquerochdale

# Option 1: Open in Android Studio (Recommended)
open -a "Android Studio" Android/
# Then build and run from Android Studio

# Option 2: Command line build
cd Android

# Start emulator in background (if not already running)
$ANDROID_HOME/emulator/emulator -avd Pixel_7_API_34 &

# Build and install
chmod +x gradlew
./gradlew installDebug

# Launch app
adb shell am start -n com.centralmosque.rochdale/.MainActivity
```

These commands will help you get the Central Mosque Rochdale app running locally on both iOS and Android platforms. Make sure to have the required development tools installed before proceeding.