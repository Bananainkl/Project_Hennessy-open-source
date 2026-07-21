# Changelog

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
