# Logo Setup Guide

## Converting SVG Logo to iOS App Icon

The Central Mosque Rochdale logo (`cmr-icon.svg`) needs to be converted to PNG format for iOS.

### Required Sizes for iOS App Icon

Create the following PNG sizes from the SVG logo:

- **20x20** @1x, 40x40 @2x, 60x60 @3x (iPhone Notification)
- **29x29** @1x, 58x58 @2x, 87x87 @3x (iPhone Settings)
- **40x40** @1x, 80x80 @2x, 120x120 @3x (iPhone Spotlight)
- **60x60** @1x, 120x120 @2x, 180x180 @3x (iPhone App)
- **1024x1024** (App Store)

### Conversion Methods

#### Option 1: Using Online Tools
1. Go to https://appicon.co or https://www.appicon.build
2. Upload `cmr-icon.svg`
3. Download the generated icon set
4. Copy files to `iOS/CentralMosqueRochdale/Assets.xcassets/AppIcon.appiconset/`

#### Option 2: Using Xcode
1. Open the project in Xcode
2. Navigate to Assets.xcassets
3. Click on AppIcon
4. Drag the 1024x1024 PNG into the "App Store" slot
5. Xcode will generate other sizes automatically (if using Xcode 14+)

#### Option 3: Using ImageMagick (Command Line)
```bash
# Install ImageMagick if not already installed
brew install imagemagick

# Convert SVG to various sizes
magick cmr-icon.svg -resize 1024x1024 AppIcon-1024.png
magick cmr-icon.svg -resize 180x180 AppIcon-180.png
magick cmr-icon.svg -resize 120x120 AppIcon-120.png
magick cmr-icon.svg -resize 87x87 AppIcon-87.png
magick cmr-icon.svg -resize 80x80 AppIcon-80.png
magick cmr-icon.svg -resize 60x60 AppIcon-60.png
magick cmr-icon.svg -resize 58x58 AppIcon-58.png
magick cmr-icon.svg -resize 40x40 AppIcon-40.png
magick cmr-icon.svg -resize 29x29 AppIcon-29.png
magick cmr-icon.svg -resize 20x20 AppIcon-20.png
```

### Brand Colors Applied

✅ **Primary Gold**: #B5A77D - Used for main UI elements, headers, navigation
✅ **Secondary Purple**: #564E58 - Used for secondary elements, text
✅ **Accent Rose**: #904E55 - Used for highlights, important actions
✅ **Light Background**: #F2EFE9 - Light mode background
✅ **Dark Background**: #252627 - Dark mode background

### Where Colors Are Applied

- **ContentView**: Header, feature cards, icons
- **PrayerTimesView**: Table headers, prayer times, Jummah section
- **QiblaCompassView**: Compass markings, direction indicators
- **SettingsView**: Toggle controls, text colors
- **ThemeManager**: Centralized color management for all views

All views now support both light and dark mode with Central Mosque Rochdale branding!
