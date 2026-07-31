# Changelog

## 1.7.19 (189) - 2026-07-31

- Kept the native macOS window controls at the same position when entering and leaving the full player.
- Vertically aligned the full-player down button with the native close, minimize, and zoom controls.

## 1.7.18 (188) - 2026-07-31

- Kept the native macOS close, minimize, and zoom controls visible in the full player while hiding the standard app toolbar.
- Replaced the duplicated full-player navigation capsule with a single down button positioned beside the native window controls.

## 1.7.17 (187) - 2026-07-31

- Made the macOS sidebar width adjustable by dragging its trailing edge, with persistence across launches and an accessible adjustment action.
- Set the default sidebar width to 195 points, added a wider 188-360 point adjustment range, and made double-click restore the default.
- Removed the permanent sidebar separator while retaining a subtle resize indicator on hover.
- Increased the full-width bottom player height from 72 to 84 points for more comfortable spacing.
- Restored a visible frosted-glass treatment to the bottom player in Desktop Transparency mode.
- Removed the persistent blue focus outline from sidebar rows and improved sidebar brand contrast in Desktop Transparency mode.

## 1.7.16 (186) - 2026-07-31

- Replaced the macOS 26 floating navigation sidebar with a flush, inline sidebar that connects directly to the window edges and bottom player.
- Added an explicit toolbar control for showing and hiding the sidebar without changing navigation behavior.
- Refined sidebar branding, grouping, width, and Desktop Transparency contrast while keeping the wallpaper visible.
- Extended the bottom player across the full window instead of limiting it to the detail pane.

## 1.7.15 (185) - 2026-07-31

- Refined the macOS interface with denser navigation, flatter translucent panels, and calmer visual hierarchy.
- Rebuilt the mini player as a full-width bottom control bar with track details on the left, transport controls in the center, and playback tools on the right.
- Preserved Classic Glass, Desktop Transparency, accessibility labels, and existing download and playback behavior.

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
