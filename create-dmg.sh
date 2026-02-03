#!/bin/bash

# Configuration
APP_NAME="Overlay"
DMG_NAME="Overlay"
DMG_TEMP="dmg_temp"
DMG_RW="temp_rw.dmg"
VOLUME_NAME="Overlay"
SOURCE_APP="$1"

# Window settings
WINDOW_WIDTH=540
WINDOW_HEIGHT=380
ICON_SIZE=128
APP_X=140
APP_Y=180
APPLICATIONS_X=400
APPLICATIONS_Y=180

if [ -z "$SOURCE_APP" ]; then
    echo "Usage: ./create-dmg.sh /path/to/Overlay.app"
    exit 1
fi

if [ ! -d "$SOURCE_APP" ]; then
    echo "Error: $SOURCE_APP not found"
    exit 1
fi

echo "Creating polished DMG..."

# Cleanup previous builds
rm -rf "$DMG_TEMP"
rm -f "$DMG_RW"
rm -f "${DMG_NAME}.dmg"

# Create temp directory
mkdir -p "$DMG_TEMP"

# Copy app
cp -R "$SOURCE_APP" "$DMG_TEMP/"

# Create Applications symlink
ln -s /Applications "$DMG_TEMP/Applications"

# Calculate DMG size (app size + 10MB buffer)
SIZE=$(du -sm "$DMG_TEMP" | cut -f1)
SIZE=$((SIZE + 10))

# Create read-write DMG
hdiutil create -srcfolder "$DMG_TEMP" -volname "$VOLUME_NAME" -fs HFS+ \
    -fsargs "-c c=64,a=16,e=16" -format UDRW -size ${SIZE}m "$DMG_RW"

# Mount the DMG
DEVICE=$(hdiutil attach -readwrite -noverify -noautoopen "$DMG_RW" | \
    egrep '^/dev/' | sed 1q | awk '{print $1}')
MOUNT_POINT="/Volumes/$VOLUME_NAME"

echo "Mounted at $MOUNT_POINT"

# Wait for mount
sleep 2

# Use AppleScript to set window properties and icon positions
echo "Setting up Finder window..."
osascript << EOF
tell application "Finder"
    tell disk "$VOLUME_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {100, 100, 640, 480}

        set theViewOptions to icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to $ICON_SIZE
        set background color of theViewOptions to {60000, 60000, 60000}

        update without registering applications
        delay 1
    end tell
end tell
EOF

# Set icon positions using Finder's built-in commands via osascript
# This method is more reliable for symlinks
osascript -e "tell application \"Finder\" to set position of item \"${APP_NAME}.app\" of disk \"${VOLUME_NAME}\" to {${APP_X}, ${APP_Y}}"
osascript -e "tell application \"Finder\" to set position of item \"Applications\" of disk \"${VOLUME_NAME}\" to {${APPLICATIONS_X}, ${APPLICATIONS_Y}}" 2>/dev/null || \
osascript -e "tell application \"Finder\" to set position of alias file \"Applications\" of disk \"${VOLUME_NAME}\" to {${APPLICATIONS_X}, ${APPLICATIONS_Y}}" 2>/dev/null || \
echo "Note: Could not position Applications folder (visual only, DMG still works)"

# Close and reopen to save .DS_Store
osascript << EOF
tell application "Finder"
    tell disk "$VOLUME_NAME"
        close
        open
        delay 2
        close
    end tell
end tell
EOF

# Sync and wait
sync
sleep 3

# Unmount
echo "Unmounting..."
hdiutil detach "$DEVICE"

# Convert to compressed read-only DMG
echo "Creating final compressed DMG..."
hdiutil convert "$DMG_RW" -format UDZO -imagekey zlib-level=9 -o "${DMG_NAME}.dmg"

# Cleanup
rm -rf "$DMG_TEMP"
rm -f "$DMG_RW"

echo ""
echo "✓ Created ${DMG_NAME}.dmg"
echo "  - Window size: ${WINDOW_WIDTH}x${WINDOW_HEIGHT}"
echo "  - App on left, Applications on right"
echo "  - Icon size: ${ICON_SIZE}px"
