# ADG Media Player — Flutter Android

Same feature set as the desktop Electron version, rebuilt for Android with Flutter.

---

## Features

| Feature | Details |
|---|---|
| **YouTube** | youtube-nocookie embed, autoplay, same URL parser |
| **Vimeo** | Vimeo player embed |
| **Dailymotion** | Geo-player embed |
| **Facebook / Reels** | Plugin embed (may need FB login) |
| **Instagram** | Public post embed |
| **Direct URL** | MP4, WebM, MKV, MP3, AAC, FLAC via native player |
| **Local files** | Pick from device storage, full native player + Chewie controls |
| **Internet Radio** | Radio Browser API, top 40 + search, live streaming |
| **Queue** | Add, reorder (drag), shuffle, repeat (none / one / all) |
| **Settings** | Autoplay next toggle |
| **Share intent** | Share a YouTube/video link from your browser directly to ADG Player |

---

## Build from source

### Prerequisites

1. **Flutter 3.19+** — https://docs.flutter.dev/get-started/install/linux  
   After installing, run:
   ```bash
   flutter doctor
   ```
   Fix anything it flags (Android SDK, Android Studio or command-line tools).

2. **Android SDK** — install via Android Studio or sdkmanager:
   ```bash
   sdkmanager "platforms;android-34" "build-tools;34.0.0"
   ```

3. **Java 17** (bundled with Android Studio, or install separately).

---

### 1 — Clone / unzip this project

```bash
unzip ADG-Media-Player-Flutter.zip
cd adg_player
```

### 2 — Edit `android/local.properties`

Replace the placeholder paths with your actual paths:

```properties
sdk.dir=/home/YOU/Android/Sdk
flutter.sdk=/home/YOU/flutter
```

On **Windows** use forward slashes or double backslashes:
```properties
sdk.dir=C:\\Users\\YOU\\AppData\\Local\\Android\\Sdk
flutter.sdk=C:\\Users\\YOU\\flutter
```

### 3 — Get packages

```bash
flutter pub get
```

### 4 — Build the APK

**Debug APK** (fastest, install directly):
```bash
flutter build apk --debug
```

**Release APK** (optimised, unsigned — fine for sideloading):
```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### 5 — Install on your phone

Enable **Developer options** on your Android device (tap Build Number 7 times), turn on **USB Debugging**, then:

```bash
flutter install
# or
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## Project structure

```
lib/
├── main.dart                   # Entry point, HomeShell, AppBar
├── theme.dart                  # Colors, ThemeData (matches desktop palette)
├── models/
│   ├── queue_item.dart         # QueueItem + MediaType enum
│   └── radio_station.dart      # RadioStation model
├── services/
│   ├── url_parser.dart         # Extract IDs, build embed URLs
│   ├── radio_service.dart      # Radio Browser API calls
│   └── player_controller.dart  # ChangeNotifier state: queue, audio, radio
├── screens/
│   ├── player_screen.dart      # Top player area (embed or native)
│   ├── add_tab.dart            # Add media tab (7 platform sub-tabs)
│   ├── queue_tab.dart          # Draggable queue list
│   ├── radio_tab.dart          # Radio search + list
│   └── settings_tab.dart       # Settings + about
└── widgets/
    ├── embed_player.dart        # WebView wrapper for YT/Vimeo/etc
    ├── native_video_player.dart # video_player + Chewie for direct/local
    ├── mini_controls.dart       # Bottom play/pause/seek/repeat bar
    ├── platform_icon.dart       # Per-platform icon + colour
    └── toast.dart               # Snackbar helper
```

---

## Troubleshooting

**YouTube stuck / not playing**  
The app uses `youtube-nocookie.com` embeds via WebView, same approach as the desktop fix. On Android, `webview_flutter` uses the system WebView (Chrome). If YouTube still stalls, go to Play Store and update "Android System WebView".

**Radio not loading**  
Radio Browser API uses three fallback hosts (`de1`, `nl1`, `at1`). If all fail, check your internet connection.

**Local file won't play**  
Grant storage permissions when prompted. On Android 13+ the app requests `READ_MEDIA_VIDEO` and `READ_MEDIA_AUDIO` automatically.

**Build error: SDK not found**  
Make sure `android/local.properties` has the correct `sdk.dir` path.

---

## Permissions used

| Permission | Why |
|---|---|
| `INTERNET` | Video embeds, radio streaming, Radio Browser API |
| `READ_MEDIA_VIDEO` / `READ_MEDIA_AUDIO` | Local file playback (Android 13+) |
| `READ_EXTERNAL_STORAGE` | Local file playback (Android ≤12) |
| `FOREGROUND_SERVICE` | Keep audio playing when screen is off |
| `WAKE_LOCK` | Prevent CPU sleep during radio playback |
