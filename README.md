# Twitch Chat Overlay for macOS

A lightweight macOS application that displays Twitch chat as a floating overlay window. Perfect for streamers and viewers who want to keep chat visible while gaming or using other fullscreen applications.

## Features

- **Floating Overlay** - Stays on top of other windows, including fullscreen windowed games
- **Glassmorphic Design** - Apple-style translucent glass card appearance
- **Minimal Chat Style** - Option to show only usernames and messages with transparent background
- **Adjustable Text Size** - Small, Medium, or Large text for minimal style
- **Opacity Controls** - Separate sliders for background and content opacity
- **Click-Through Mode** - Let clicks pass through to interact with applications underneath
- **Global Hotkey** - Toggle click-through with Ctrl+§ from anywhere
- **Resizable & Draggable** - Position and size the overlay to your preference
- **Persistent Settings** - Window position and settings are saved between sessions

## Requirements

- macOS 12.0 or later
- Xcode 14+ (for building)

## Building

1. Open `Overlay.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities
3. Build and run (Cmd+R)

## Usage

### Setting Up Chat

1. Open Twitch in your browser
2. Navigate to the channel whose chat you want to display
3. Click the chat settings gear icon and select "Popout Chat"
4. Copy the URL from the popout window (e.g., `https://www.twitch.tv/popout/channelname/chat`)
5. Open the Overlay settings and paste the URL
6. Click "Apply URL"

### Controls

| Action | Method |
|--------|--------|
| Move window | Drag the handle bar at the top |
| Resize window | Drag window edges or corners |
| Toggle click-through | Press **Ctrl+§** (global hotkey) |
| Open settings | Click status bar icon → Settings, or **Cmd+,** |
| Show/Hide overlay | Click status bar icon → Show/Hide Overlay |

### Settings

- **Twitch Chat URL** - The popout chat URL from Twitch
- **Minimal chat style** - Hides Twitch UI, shows only messages
- **Text Size** - Adjust message text size (minimal style only)
- **Background Opacity** - Transparency of the glass background
- **Content Opacity** - Transparency of the chat content
- **Click-Through Mode** - Enable to interact with windows underneath
- **Reset Window Position** - Centers the overlay with default size

## Game Compatibility

Works with any application using **fullscreen windowed** (borderless) mode:

- World of Warcraft
- League of Legends
- Valorant
- Final Fantasy XIV
- Most modern games with a "Fullscreen (Windowed)" or "Borderless" display option

**Note:** True exclusive fullscreen mode bypasses the window system and will hide the overlay. Use fullscreen windowed mode for best results.

## Troubleshooting

### Overlay not visible in game
- Ensure the game is using "Fullscreen Windowed" or "Borderless" mode, not exclusive fullscreen

### Global hotkey not working
- Grant Accessibility permissions: System Settings → Privacy & Security → Accessibility → Enable Overlay
- Restart the app after granting permissions

### Chat not loading
- Verify the URL is a valid Twitch popout chat URL
- Check your internet connection
- Try refreshing by re-applying the URL

### Window moved off-screen
- Use Settings → Reset Window Position to bring it back

## License

MIT License
