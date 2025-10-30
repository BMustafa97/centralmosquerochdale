#!/bin/bash

# Script to create transparent logo PNGs with proper centering

LOGO_DIR="iOS/CentralMosqueRochdale/Assets.xcassets/MosqueLogo.imageset"

echo "Creating transparent logo assets..."

# Create square transparent logos with the mosque centered
magick cmr-icon.svg -background none -gravity center -extent 1:1 -resize 120x120 "$LOGO_DIR/MosqueLogo@1x.png"
magick cmr-icon.svg -background none -gravity center -extent 1:1 -resize 240x240 "$LOGO_DIR/MosqueLogo@2x.png"
magick cmr-icon.svg -background none -gravity center -extent 1:1 -resize 360x360 "$LOGO_DIR/MosqueLogo@3x.png"

echo "✓ Transparent logo assets created!"
echo ""
echo "Verifying transparency:"
file "$LOGO_DIR/MosqueLogo@1x.png"
file "$LOGO_DIR/MosqueLogo@2x.png"
file "$LOGO_DIR/MosqueLogo@3x.png"
