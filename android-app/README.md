# Hennessy Android

Native Android port of the macOS Hennessy downloader/player.

## Build APK

```bash
cd android-app
ANDROID_HOME=/opt/homebrew/share/android-commandlinetools gradle :app:assembleDebug
```

The debug APK is generated at:

```text
android-app/app/build/outputs/apk/debug/app-debug.apk
```

## Notes

- Target device profile: Samsung Galaxy S25 class devices, Android 15/16-era One UI.
- The downloader uses `io.github.junkfood02.youtubedl-android` with bundled yt-dlp and FFmpeg.
- The APK currently builds arm64-v8a only to keep the Samsung phone package smaller.
- Downloads are written to the app-specific external download directory under `Android/data/com.bluelion.hennessy/files/Download/Hennessy`, which works with modern Android scoped storage on Samsung devices.
