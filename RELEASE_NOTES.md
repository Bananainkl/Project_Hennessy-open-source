# Hennessy 1.7.20

This release restores downloadable installers on GitHub Releases.

## Highlights

- Download the macOS DMG directly from the release assets.
- Download the Android arm64 APK directly from the release assets.
- Use `SHA256SUMS.txt` to verify either package after downloading.
- Future tagged releases build, test, validate, and upload both installers automatically.

## Signing notice

- The macOS DMG contains an ad-hoc signed app and is not Apple-notarized. macOS may require explicit approval in Privacy & Security on first launch.
- The Android arm64 package uses the standard Debug signing key and is intended for direct testing rather than Play Store distribution.
- The macOS package does not bundle `yt-dlp` or FFmpeg executables; downloading media still requires separately installed compatible tools.

Application behavior is unchanged from 1.7.19.
