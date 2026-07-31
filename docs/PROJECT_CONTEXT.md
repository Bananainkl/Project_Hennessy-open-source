# Hennessy Project Context

> Last verified from repository documentation: 2026-07-30

## Purpose

Hennessy is a native macOS media downloader, local library, and player with an experimental native Android companion. This sanitized public repository is maintained from a separate private working repository without copying private history or local artifacts.

## Technology And Entry Points

- macOS: Swift 6, SwiftUI, Swift Package Manager under `Sources/Hennessy/`.
- Android: native project under `android-app/`.
- External tools: `yt-dlp` and FFmpeg, prepared separately and not committed as large binaries.
- Primary commands: `swift test`, `./script/build_and_run.sh --verify`, and `./script/package_dmg.sh`.

## Stable Product Boundaries

- Downloaded media stays outside Git and defaults to `~/Downloads/Media`.
- Low-quality replacement must be measurably better and preserve a recoverable backup.
- Releases must keep macOS and Android version metadata aligned.
- Public synchronization must exclude private history, credentials, downloaded media, audit artifacts, and unreviewed third-party binaries.

## Current State And Risks

The main download, library, playback, metadata, lyrics, duplicate detection, quality-audit, and user-selectable window appearance workflows are implemented. Distribution remains dependent on separately prepared third-party tools and their license obligations. Read `docs/CURRENT_HANDOFF.md` for the latest task state and verification evidence.

## Maintenance

Update this file when the product boundary, supported platforms, build entry points, public/private repository relationship, or long-term risks change.
