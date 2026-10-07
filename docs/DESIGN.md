# AMAGENT Design Specification

## 1. Core Philosophy
Minimalist, task-focused UI. No decorative elements. High contrast voice-visual feedback.

## 2. Desktop Design (Server UI - Brief Popup Overlay)

### Main Window
- **Type**: Borderless, Always-on-top overlay
- **Trigger**: `Tray Icon` (System Tray → Right Click → Show Window)
- **Size**: 320dp x 180dp
- **Theme**: Dark (matches system)
- **Elements**:
  - QR Code (Top-left) - Scan to pair
  - Status Text: "Connected" / "Pair with Mobile" (Center)
  - Disconnect Button (Bottom-right, red icon)
- **Animation**: Fade in/out using `pyautogui` center click to dismiss

### Voice Feedback Overlay
- Floating text bubble showing last command
- Position: Bottom-center
- Auto-dismiss: 3 seconds
- Font: Large, bold

## 3. Mobile Design (Android/iOS - Flutter UI)

### Screen 1: Pair Screen
```
┌─────────────────────────────────┐
│ [AMAGENT Logo]                  │
│                                 │
│ ┌─────────────────────────────┐ │
│ │  Laptop IP (Text Field)     │ │
│ ├─────────────────────────────┤ │
│ │  Master Password (Secret)   │ │
│ └─────────────────────────────┘ │
│                                 │
│ [PAIR DEVICE]  [QR SCANNER ⚙]  │
│                                 │
│ Status: • READY                 │
└─────────────────────────────────┘
```

### Screen 2: Control Screen
```
┌─────────────────────────────────┐
│ AMAGENT    [⚙ SETTINGS]         │
├─────────────────────────────────┤
│                                 │
│    [ Microphone Icon ]         │
│    "Go to slide 6"              │
│    (command shown in bold)      │
│                                 │
│    [ RECORD ]  [ STOP ]         │
│                                 │
│  Voice | Text                   │
└─────────────────────────────────┘
```

### Design Tokens
- **Primary Color**: #007AFF (iOS Blue) → System accent
- **Error Color**: #FF3B30 (iOS red) for Unauthorized
- **Font**: System default (San Francisco / Roboto)
- **Button Shapes**: Rounded corners (8dp)
- **Icons**: Feather icons (mic, settings, qr-scan)

### Accessibility (per anti-slop guidelines)
- Minimum touch target: 48dp
- Contrast ratio: > 4.5:1
- Voice indicator: Pulsing animation when listening
- Error messages in red with icon

## 4. Command Language (Bahasa Indonesia + English)

| Voice/Text Command | Action |
|-------------------|--------|
| "Go to page 6" / "Saya mau ke halaman 6" | Goto Slide 6 |
| "Next slide" / "Berikutnya" | Next Slide |
| "Zoom in" / "Perbesar" | Zoom +10% |
| "Underline this sentence" | Underline selection |
| "Switch to Chrome" / "Buka Chrome" | Activate Chrome |
| "Open Word" / "Buka Word" | Activate Word |
| "Disconnect" | Clear single-device lock |

## 5. Security UI
- Password: 8-32 chars, hashed with bcrypt
- QR: Generated only when `/qr` endpoint called
- Error: Red banner: "LOCKED: Another device is connected"

## 6. Platform Adaptation

### Windows
- Uses `pywin32` for Office automation
- Tray app via `pystray` (add to installer)
- Executable: `amagent.exe` → Auto-start on login option

### Android
- Full permissions: MICROPHONE, CAMERA, WRITE_EXTERNAL_STORAGE
- Target SDK: 34
- Min SDK: 24
- Build: `flutter build apk --split-per-abi`

### iOS (Future)
- Xcode build, App Store connect metadata not included
- Permissions: Microphone, Camera, Local Network

### macOS / Linux (Future)
- Electron wrapper or Python + Qt5 for cross-platform tray app
- File picker UI for session file selection