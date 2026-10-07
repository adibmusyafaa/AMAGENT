# AMAGENT Build & Installer Guide

## 1. Desktop Application (Windows .exe)
To compile the Python backend and wrapper into a native `.exe`:
```bash
pip install pyinstaller flask flask-cors bcrypt pyautogui pywin32 qrcode pillow psutil
pyinstaller --noconsole --onefile server/main.py -n amagent-server
```
The output executable will be inside `dist/amagent-server.exe`.

## 2. Mobile Application (Android .apk & iOS .ipa)
Built using Flutter framework.
1. Navigate to `client/`:
   ```bash
   cd client
   flutter pub get
   ```
2. Build Android APK:
   ```bash
   flutter build apk --release
   ```
   Output: `client/build/app/outputs/flutter-apk/app-release.apk`
3. Build iOS (Mac required):
   ```bash
   flutter build ios --release
   ```

## 3. Security Mechanism
- **Single-Device Lock**: The server maintains an `active_client_id`. Once a phone pairs successfully with the Master Password, any subsequent connection attempt from a second phone is rejected with HTTP 403 (`LOCKED`).
- **Master Password**: Verified via `bcrypt` against a securely stored local hash (`config.json`).
- **QR Pairing**: Generates a dynamic QR code containing `AMAGENT|<IP>|8888` for frictionless pairing.
