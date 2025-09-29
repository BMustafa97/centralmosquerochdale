#!/bin/bash

# Quick test script for Central Mosque Rochdale apps
# Usage: ./quick-test.sh [ios|android|both]

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}🚀 $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

run_ios() {
    log_info "Starting iOS app..."
    
    if [[ ! -f "iOS/CentralMosqueRochdale.xcodeproj/project.pbxproj" ]]; then
        log_error "iOS project not found. Run ./setup-local.sh first"
        exit 1
    fi
    
    log_info "Opening Xcode project..."
    open iOS/CentralMosqueRochdale.xcodeproj
    
    # Also try to boot a simulator in the background
    AVAILABLE_SIM=$(xcrun simctl list devices available | grep "iPhone" | head -1 | sed 's/.*(\([^)]*\)).*/\1/' | xargs)
    if [[ -n "$AVAILABLE_SIM" ]]; then
        log_info "Booting simulator: $AVAILABLE_SIM"
        xcrun simctl boot "$AVAILABLE_SIM" &> /dev/null || true
    fi
    
    log_success "iOS project opened in Xcode"
    echo "   → Press Cmd+R to build and run"
    echo "   → Simulator should boot automatically"
    echo "   → Or run: chmod +x ios-build.sh && ./ios-build.sh"
}

run_android() {
    log_info "Starting Android app..."
    
    if [[ ! -d "Android/app" ]]; then
        log_error "Android project not found. Run ./setup-local.sh first"
        exit 1
    fi
    
    log_info "Opening Android Studio..."
    open -a "Android Studio" Android/
    
    log_success "Android project opened in Android Studio"
    echo "   → Wait for Gradle sync to complete"
    echo "   → Click the green Run button"
    echo "   → Select an emulator or device"
}

start_android_emulator() {
    log_info "Starting Android emulator in background..."
    
    if command -v emulator &> /dev/null; then
        # Check if any emulator is already running
        if ! adb devices | grep -q "emulator"; then
            # Start emulator in background
            nohup $ANDROID_HOME/emulator/emulator -avd Pixel_7_API_34 > /dev/null 2>&1 &
            log_success "Android emulator starting..."
            echo "   → Emulator will take 30-60 seconds to boot"
        else
            log_success "Android emulator already running"
        fi
    else
        log_error "Emulator command not found. Check Android SDK installation"
    fi
}

# Main execution
case "${1:-both}" in
    "ios")
        run_ios
        ;;
    "android")
        start_android_emulator
        sleep 2
        run_android
        ;;
    "both")
        log_info "Starting both iOS and Android apps..."
        echo ""
        start_android_emulator
        sleep 2
        run_ios
        echo ""
        run_android
        echo ""
        log_success "Both apps starting!"
        echo "   📱 iOS: Xcode opened - press Cmd+R"
        echo "   🤖 Android: Android Studio opened - click Run"
        ;;
    *)
        echo "Usage: $0 [ios|android|both]"
        echo ""
        echo "Examples:"
        echo "  $0           # Start both apps (default)"
        echo "  $0 ios       # Start only iOS app"
        echo "  $0 android   # Start only Android app"
        exit 1
        ;;
esac