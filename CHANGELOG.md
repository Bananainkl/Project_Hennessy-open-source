# Changelog

## 1.7.14 (184) - 2026-07-31

- Extended the Desktop Transparency skin to the full player while preserving readable artwork, queue, and playback controls.
- Kept the original opaque player backdrop for Classic Glass and when macOS Reduce Transparency is enabled.

## 1.7.13 (183) - 2026-07-31

- Added a user-selectable Desktop Transparency window skin alongside the existing Classic Glass appearance.
- Made appearance changes apply immediately and persist across launches.
- Preserved readable dark controls while allowing the desktop to show through the main content and sidebar.
- Added an automatic Classic Glass fallback when macOS Reduce Transparency is enabled.
- Added regression coverage for persisted appearance identifiers and user-facing appearance metadata.

## 1.7.12 (182) - 2026-07-21

- Added automatic local audio-quality auditing with codec and effective-bitrate badges.
- Added a confirmed, recoverable low-quality re-download workflow that replaces files only after measurable improvement and moves originals into timestamped backup folders.
- Added source-format and post-download quality details to the activity log.
- Reclassified MP3 as a lossy compatibility conversion instead of implying that a larger MP3 is higher quality.
- Added regression coverage for 48 kbps HE-AAC, Opus, AAC, MP3, yt-dlp metadata, local-library inspection, and recoverable replacement behavior.

## 1.7.11 (181) - 2026-07-20

- Published the initial open-source macOS and Android source release.
- Added GPL-3.0 licensing and third-party dependency notices.
- Kept downloaded media and redistributable tool binaries outside source history.
