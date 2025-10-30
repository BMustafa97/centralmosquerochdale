#!/bin/bash

# Script to convert SVG to PNG and make white background transparent

LOGO_DIR="iOS/CentralMosqueRochdale/Assets.xcassets/MosqueLogo.imageset"

echo "Converting SVG to PNG and removing white background..."

# Convert and make white pixels transparent
magick cmr-icon.svg -background none -resize 120x120 -fuzz 10% -transparent white "$LOGO_DIR/MosqueLogo@1x.png"
magick cmr-icon.svg -background none -resize 240x240 -fuzz 10% -transparent white "$LOGO_DIR/MosqueLogo@2x.png"
magick cmr-icon.svg -background none -resize 360x360 -fuzz 10% -transparent white "$LOGO_DIR/MosqueLogo@3x.png"

echo "✓ Transparent logo assets created!"
echo ""
echo "Verifying files:"
ls -lh "$LOGO_DIR"/MosqueLogo*.png
echo ""
echo "Testing transparency (should show 'RGBA' with alpha channel):"
file "$LOGO_DIR/MosqueLogo@1x.png"
