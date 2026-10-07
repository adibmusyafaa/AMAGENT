#!/bin/bash
echo "--- AMAGENT Android Build Start ---"
cd client
flutter pub get
flutter build apk --release
echo "--- Build Finished! Check client/build/app/outputs/flutter-apk/app-release.apk ---"
read -p "Press enter to exit"
