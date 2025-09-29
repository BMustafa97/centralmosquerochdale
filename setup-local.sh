#!/bin/bash

# Central Mosque Rochdale - Local Development Setup Script
# This script checks and installs all prerequisites for iOS and Android development

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
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

# Check if running on macOS
check_macos() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "This script is designed for macOS only."
        exit 1
    fi
    log_success "Running on macOS"
}

# Check if Homebrew is installed
check_homebrew() {
    log_info "Checking Homebrew installation..."
    if ! command -v brew &> /dev/null; then
        log_warning "Homebrew not found. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
        
        log_success "Homebrew installed successfully"
    else
        log_success "Homebrew is already installed"
        brew update
    fi
}

# Check and install Xcode Command Line Tools
check_xcode_tools() {
    log_info "Checking Xcode Command Line Tools..."
    if ! xcode-select -p &> /dev/null || ! command -v xcrun &> /dev/null; then
        log_warning "Xcode Command Line Tools not found or incomplete. Installing..."
        
        # Force installation even if partially installed
        sudo rm -rf /Library/Developer/CommandLineTools &> /dev/null || true
        xcode-select --install
        
        # Wait for installation to complete
        echo "Please complete the Xcode Command Line Tools installation in the popup window."
        echo "This may take several minutes. Press any key ONLY after the installation is complete..."
        read -n 1 -s
        
        # Verify installation with multiple checks
        if xcode-select -p &> /dev/null && command -v xcrun &> /dev/null && command -v simctl &> /dev/null; then
            log_success "Xcode Command Line Tools installed successfully"
        else
            log_warning "Xcode Command Line Tools may not be fully installed."
            log_info "Trying to set developer directory..."
            
            # Try to set the developer directory manually
            if [[ -d "/Applications/Xcode.app/Contents/Developer" ]]; then
                sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
                log_info "Set developer directory to Xcode.app"
            elif [[ -d "/Library/Developer/CommandLineTools" ]]; then
                sudo xcode-select -s /Library/Developer/CommandLineTools
                log_info "Set developer directory to CommandLineTools"
            fi
            
            # Final verification
            if command -v xcrun &> /dev/null && xcrun simctl help &> /dev/null; then
                log_success "Xcode Command Line Tools are now working"
            else
                log_error "Xcode Command Line Tools installation failed"
                log_error "Please install Xcode from the App Store and try again"
                exit 1
            fi
        fi
    else
        log_success "Xcode Command Line Tools are already installed"
        
        # Verify simctl is working
        if ! xcrun simctl help &> /dev/null; then
            log_warning "simctl not working properly. Trying to fix..."
            if [[ -d "/Applications/Xcode.app/Contents/Developer" ]]; then
                sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
            fi
        fi
    fi
}

# Check Xcode installation
check_xcode() {
    log_info "Checking Xcode installation..."
    
    if ! command -v xcodebuild &> /dev/null; then
        log_error "Xcode is not installed. Please install Xcode from the App Store."
        log_info "Opening App Store..."
        open "macappstore://itunes.apple.com/app/xcode/id497799835"
        echo "Press any key after Xcode installation is complete..."
        read -n 1 -s
    fi
    
    # Check Xcode version
    if command -v xcodebuild &> /dev/null; then
        XCODE_VERSION=$(xcodebuild -version | head -n 1)
        log_success "Xcode is installed: $XCODE_VERSION"
        
        # Accept Xcode license
        sudo xcodebuild -license accept &> /dev/null || true
    fi
}

# Check iOS Simulators
check_ios_simulators() {
    log_info "Checking iOS Simulators..."
    
    if command -v xcrun &> /dev/null && xcrun simctl help &> /dev/null; then
        # Check for any iPhone simulators
        SIMULATORS=$(xcrun simctl list devices available | grep -c "iPhone" || true)
        if [[ $SIMULATORS -gt 0 ]]; then
            log_success "iOS Simulators are available"
            # List available simulators
            log_info "Available simulators:"
            xcrun simctl list devices available | grep "iPhone" | head -3 || true
        else
            log_warning "No iPhone simulators found."
            log_info "Please open Xcode and install iOS simulators:"
            log_info "Xcode > Settings > Platforms > iOS"
        fi
    else
        log_warning "Cannot check simulators - xcrun simctl not available"
        log_info "Please ensure Xcode Command Line Tools are properly installed"
    fi
}

# Check and install Java (required for Android)
check_java() {
    log_info "Checking Java installation..."
    
    if ! command -v java &> /dev/null; then
        log_warning "Java not found. Installing OpenJDK 17..."
        brew install openjdk@17
        
        # Add Java to PATH
        echo 'export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"' >> ~/.zshrc
        export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"
        
        log_success "Java installed successfully"
    else
        JAVA_VERSION=$(java -version 2>&1 | head -n 1)
        log_success "Java is already installed: $JAVA_VERSION"
    fi
}

# Check and install Android Studio
check_android_studio() {
    log_info "Checking Android Studio installation..."
    
    if [[ ! -d "/Applications/Android Studio.app" ]]; then
        log_warning "Android Studio not found. Installing via Homebrew..."
        brew install --cask android-studio
        log_success "Android Studio installed successfully"
        
        log_info "Please open Android Studio and complete the initial setup"
        log_info "Make sure to install Android SDK and create a virtual device"
        open "/Applications/Android Studio.app"
        
        echo "Press any key after Android Studio setup is complete..."
        read -n 1 -s
    else
        log_success "Android Studio is already installed"
    fi
}

# Setup Android environment variables
setup_android_env() {
    log_info "Setting up Android environment variables..."
    
    # Default Android SDK path
    ANDROID_HOME="$HOME/Library/Android/sdk"
    
    # Check if Android SDK exists
    if [[ -d "$ANDROID_HOME" ]]; then
        # Add Android environment variables to shell profile
        cat >> ~/.zshrc << EOF

# Android SDK Environment Variables
export ANDROID_HOME=\$HOME/Library/Android/sdk
export PATH=\$PATH:\$ANDROID_HOME/emulator
export PATH=\$PATH:\$ANDROID_HOME/tools
export PATH=\$PATH:\$ANDROID_HOME/tools/bin
export PATH=\$PATH:\$ANDROID_HOME/platform-tools
EOF
        
        # Source the updated profile
        source ~/.zshrc &> /dev/null || true
        
        log_success "Android environment variables configured"
    else
        log_warning "Android SDK not found at $ANDROID_HOME"
        log_info "Please complete Android Studio setup and install Android SDK"
    fi
}

# Check ADB (Android Debug Bridge)
check_adb() {
    log_info "Checking ADB (Android Debug Bridge)..."
    
    # Try to find ADB in common locations
    ADB_PATHS=(
        "$HOME/Library/Android/sdk/platform-tools/adb"
        "/opt/homebrew/bin/adb"
        "/usr/local/bin/adb"
    )
    
    ADB_FOUND=false
    for path in "${ADB_PATHS[@]}"; do
        if [[ -f "$path" ]]; then
            ADB_FOUND=true
            log_success "ADB found at: $path"
            break
        fi
    done
    
    if ! $ADB_FOUND; then
        log_warning "ADB not found. Installing via Homebrew..."
        brew install --cask android-platform-tools
        log_success "ADB installed successfully"
    fi
}

# Check and install Node.js (for Firebase CLI)
check_nodejs() {
    log_info "Checking Node.js installation..."
    
    if ! command -v node &> /dev/null; then
        log_warning "Node.js not found. Installing via Homebrew..."
        brew install node
        log_success "Node.js installed successfully"
    else
        NODE_VERSION=$(node --version)
        log_success "Node.js is already installed: $NODE_VERSION"
    fi
}

# Check and install Firebase CLI
check_firebase_cli() {
    log_info "Checking Firebase CLI installation..."
    
    if ! command -v firebase &> /dev/null; then
        log_warning "Firebase CLI not found. Installing via npm..."
        npm install -g firebase-tools
        log_success "Firebase CLI installed successfully"
    else
        FIREBASE_VERSION=$(firebase --version)
        log_success "Firebase CLI is already installed: $FIREBASE_VERSION"
    fi
}

# Setup iOS project structure
setup_ios_project() {
    log_info "Setting up iOS project structure..."
    
    # Create required directories
    mkdir -p iOS/CentralMosqueRochdale/Views
    mkdir -p iOS/CentralMosqueRochdale/Models
    mkdir -p iOS/CentralMosqueRochdale/Services
    mkdir -p "iOS/CentralMosqueRochdale/Preview Content"
    mkdir -p "iOS/CentralMosqueRochdale/Assets.xcassets/AppIcon.appiconset"
    mkdir -p "iOS/CentralMosqueRochdale/Assets.xcassets/AccentColor.colorset"
    
    # Copy SwiftUI files to Views directory
    if [[ -d "SwiftUI" ]]; then
        cp SwiftUI/*.swift iOS/CentralMosqueRochdale/Views/ 2>/dev/null || true
    fi
    
    # Copy Info.plist
    if [[ -f "iOS/Info.plist" ]]; then
        cp iOS/Info.plist iOS/CentralMosqueRochdale/
    fi
    
    # Create basic Assets.xcassets structure
    cat > "iOS/CentralMosqueRochdale/Assets.xcassets/Contents.json" << 'EOF'
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

    cat > "iOS/CentralMosqueRochdale/Assets.xcassets/AppIcon.appiconset/Contents.json" << 'EOF'
{
  "images" : [
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "20x20"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "29x29"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "40x40"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "20x20"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "29x29"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "40x40"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "76x76"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "83.5x83.5"
    },
    {
      "idiom" : "ios-marketing",
      "scale" : "1x",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

    cat > "iOS/CentralMosqueRochdale/Assets.xcassets/AccentColor.colorset/Contents.json" << 'EOF'
{
  "colors" : [
    {
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

    # Create Preview Assets directory and file
    mkdir -p "iOS/CentralMosqueRochdale/Preview Content/Preview Assets.xcassets"
    cat > "iOS/CentralMosqueRochdale/Preview Content/Preview Assets.xcassets/Contents.json" << 'EOF'
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

    log_success "iOS project structure created"
}

# Setup Android project structure
setup_android_project() {
    log_info "Setting up Android project structure..."
    
    # Create Android project directories
    mkdir -p Android/app/src/main/java/com/centralmosque/rochdale/ui
    mkdir -p Android/app/src/main/res/values
    mkdir -p Android/app/src/main/res/layout
    mkdir -p Android/app/src/main/res/drawable
    mkdir -p Android/gradle/wrapper
    
    # Copy Kotlin files
    if [[ -d "JetpackCompose" ]]; then
        cp JetpackCompose/*.kt Android/app/src/main/java/com/centralmosque/rochdale/ui/ 2>/dev/null || true
    fi
    
    # Copy Android configuration files
    if [[ -f "Android/AndroidManifest.xml" ]]; then
        cp Android/AndroidManifest.xml Android/app/src/main/
    fi
    
    if [[ -f "Android/build.gradle" ]]; then
        cp Android/build.gradle Android/app/
    fi
    
    # Create gradle wrapper if it doesn't exist
    if [[ ! -f "Android/gradlew" ]]; then
        log_info "Creating Gradle wrapper..."
        cd Android
        gradle wrapper --gradle-version 8.4
        cd ..
    fi
    
    log_success "Android project structure created"
}

# Test iOS build
test_ios_build() {
    log_info "Testing iOS build..."
    
    if [[ -f "iOS/CentralMosqueRochdale.xcodeproj/project.pbxproj" ]]; then
        cd iOS
        
        # Try to build the project
        if xcodebuild -project CentralMosqueRochdale.xcodeproj -scheme CentralMosqueRochdale -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' build &> /dev/null; then
            log_success "iOS project builds successfully"
        else
            log_warning "iOS build failed. You may need to open the project in Xcode and resolve any issues."
        fi
        
        cd ..
    else
        log_warning "iOS project file not found. Skipping build test."
    fi
}

# Test Android build
test_android_build() {
    log_info "Testing Android build..."
    
    if [[ -f "Android/build.gradle" ]] && [[ -f "Android/gradlew" ]]; then
        cd Android
        
        # Make gradlew executable
        chmod +x gradlew
        
        # Try to build the project
        if ./gradlew assembleDebug &> /dev/null; then
            log_success "Android project builds successfully"
        else
            log_warning "Android build failed. You may need to open the project in Android Studio and resolve any issues."
        fi
        
        cd ..
    else
        log_warning "Android project files not found. Skipping build test."
    fi
}

# Create AVD (Android Virtual Device) if none exists
setup_android_avd() {
    log_info "Checking Android Virtual Devices..."
    
    if command -v avdmanager &> /dev/null; then
        # List existing AVDs
        EXISTING_AVDS=$(avdmanager list avd | grep -c "Name:" || true)
        
        if [[ $EXISTING_AVDS -eq 0 ]]; then
            log_info "No AVDs found. Creating default AVD..."
            
            # Install system image if not present
            sdkmanager "system-images;android-34;google_apis;arm64-v8a" &> /dev/null || true
            
            # Create AVD
            echo "no" | avdmanager create avd -n "Pixel_7_API_34" -k "system-images;android-34;google_apis;arm64-v8a" -d "pixel_7" &> /dev/null || true
            
            log_success "Android Virtual Device created"
        else
            log_success "Android Virtual Devices already exist"
        fi
    else
        log_warning "avdmanager not found. Please create an AVD through Android Studio"
    fi
}

# Display final instructions
display_final_instructions() {
    echo ""
    log_success "🎉 Setup completed successfully!"
    echo ""
    log_info "📱 iOS Development:"
    echo "   • Open: open iOS/CentralMosqueRochdale.xcodeproj"
    echo "   • Build and run using Xcode (⌘+R)"
    echo ""
    log_info "🤖 Android Development:"
    echo "   • Open: open -a 'Android Studio' Android/"
    echo "   • Or use command line: cd Android && ./gradlew installDebug"
    echo ""
    log_info "🔧 Useful Commands:"
    echo "   • List iOS simulators: xcrun simctl list devices"
    echo "   • List Android AVDs: avdmanager list avd"
    echo "   • Start Android emulator: emulator -avd Pixel_7_API_34"
    echo ""
    log_warning "📝 Next Steps:"
    echo "   1. Restart your terminal to apply environment changes"
    echo "   2. Open Xcode and accept any license agreements"
    echo "   3. Open Android Studio and complete any pending updates"
    echo "   4. Configure Firebase for push notifications (see LOCAL_DEVELOPMENT.md)"
    echo ""
    log_info "📖 For detailed instructions, see: LOCAL_DEVELOPMENT.md"
}

# Main execution
main() {
    echo "🕌 Central Mosque Rochdale - Development Environment Setup"
    echo "========================================================"
    echo ""
    
    # System checks
    check_macos
    
    # Install basic tools
    check_homebrew
    check_xcode_tools
    
    # iOS Development
    log_info "Setting up iOS development environment..."
    check_xcode
    check_ios_simulators
    setup_ios_project
    
    # Android Development
    log_info "Setting up Android development environment..."
    check_java
    check_android_studio
    setup_android_env
    check_adb
    setup_android_project
    setup_android_avd
    
    # Additional tools
    check_nodejs
    check_firebase_cli
    
    # Test builds
    test_ios_build
    test_android_build
    
    # Final instructions
    display_final_instructions
    
    log_success "Setup script completed! 🚀"
}

# Run main function
main "$@"