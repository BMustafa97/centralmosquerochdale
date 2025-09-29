#!/bin/bash

# iOS Build Helper Script - Automatically detects available simulators
# Usage: ./ios-build.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Change to iOS directory
cd iOS

log_info "Checking available iOS simulators..."

# Get list of available iPhone simulators
AVAILABLE_SIMULATORS=$(xcrun simctl list devices available | grep "iPhone" | head -5)

if [[ -z "$AVAILABLE_SIMULATORS" ]]; then
    log_error "No iPhone simulators found!"
    log_info "Please install iOS simulators through Xcode > Settings > Components"
    exit 1
fi

log_success "Available iPhone simulators:"
echo "$AVAILABLE_SIMULATORS"
echo ""

# Try to find a good simulator to use
SIMULATOR_NAME=$(xcrun simctl list devices available | grep "iPhone" | head -1 | sed 's/.*(\([^)]*\)).*/\1/' | xargs)

if [[ -n "$SIMULATOR_NAME" ]]; then
    log_info "Using simulator: $SIMULATOR_NAME"
    
    # Boot the simulator if not already running
    if ! xcrun simctl list devices | grep "$SIMULATOR_NAME" | grep -q "Booted"; then
        log_info "Booting simulator..."
        xcrun simctl boot "$SIMULATOR_NAME" || true
        sleep 3
    else
        log_success "Simulator already running"
    fi
else
    log_warning "Could not determine simulator name, using generic build"
fi

log_info "Building iOS project..."

# Try building with specific simulator first, fall back to generic
if [[ -n "$SIMULATOR_NAME" ]]; then
    if xcodebuild -project CentralMosqueRochdale.xcodeproj -scheme CentralMosqueRochdale -sdk iphonesimulator -destination "platform=iOS Simulator,name=$SIMULATOR_NAME" build; then
        log_success "Build completed successfully with $SIMULATOR_NAME"
    else
        log_warning "Build with specific simulator failed, trying generic build..."
        if xcodebuild -project CentralMosqueRochdale.xcodeproj -scheme CentralMosqueRochdale -sdk iphonesimulator build; then
            log_success "Generic build completed successfully"
        else
            log_error "Build failed. Please check the errors above."
            exit 1
        fi
    fi
else
    # Generic build
    if xcodebuild -project CentralMosqueRochdale.xcodeproj -scheme CentralMosqueRochdale -sdk iphonesimulator build; then
        log_success "Generic build completed successfully"
    else
        log_error "Build failed. Please check the errors above."
        exit 1
    fi
fi

log_success "🎉 iOS app built successfully!"
echo ""
log_info "📱 Next steps:"
echo "   1. Open iOS Simulator (if not already open)"
echo "   2. Or run: open iOS/CentralMosqueRochdale.xcodeproj"
echo "   3. Press Cmd+R in Xcode to run the app"
echo ""
log_info "Available simulators for reference:"
xcrun simctl list devices available | grep "iPhone" | head -3