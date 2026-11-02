# Hennessy 1.7.21

This macOS release fixes playlist downloads, protects unreadable library data, and reports cancellation correctly. The Android companion app has been retired; future releases provide the macOS package only.

## Highlights

- Playlist downloads now retain and import each downloaded media file.
- Corrupt library JSON is preserved instead of being overwritten by an empty library.
- Cancelled downloads stop cleanly and are not recorded as failures.
- Search output is drained from stdout and stderr concurrently to prevent pipe deadlocks.
- GitHub Releases provide the macOS DMG with a SHA-256 checksum file.

## Signing notice

- The macOS DMG contains an ad-hoc signed app and is not Apple-notarized. macOS may require explicit approval in Privacy & Security on first launch.
- The macOS package does not bundle `yt-dlp` or FFmpeg executables; downloading media requires separately installed compatible tools.
