# Hennessy Architecture

> Last verified from repository structure: 2026-07-30

## System Shape

```text
SwiftUI views -> observable stores -> media/library services
                                      |-> yt-dlp / FFmpeg
                                      |-> local media and metadata
                                      |-> playback and quality policies

Android UI -> Android media/download implementation
```

## Module Boundaries

- `Sources/Hennessy/App`: application entry and lifecycle.
- `Sources/Hennessy/Views`: macOS user interface.
- `Sources/Hennessy/Stores`: observable application state.
- `Sources/Hennessy/Services`: download, playback, metadata, artwork, lyrics, and persistence behavior.
- `Sources/Hennessy/Models`: domain and transfer models.
- `Sources/Hennessy/Support`: design system and platform helpers.
- `Tests/HennessyTests`: policy and core behavior tests.
- `android-app`: separately built Android companion.
- `script` and `Assets/Tools`: build, packaging, and external-tool preparation.

## Data And Security Boundaries

Media files and local library state belong on the user device and must not enter source history. Tool execution must use validated paths and arguments. Credentials, audit captures, release artifacts, and private repository history must not cross into the public mirror.

## Architectural Decisions

- Native implementations are retained on both platforms.
- The macOS window appearance is a persisted user preference. Desktop transparency changes background materials rather than whole-window opacity, retains readable dark controls, and falls back to the classic background when Reduce Transparency is enabled.
- Large third-party executables are prepared outside Git.
- Quality replacement is guarded by measurable improvement and recoverable backup.
- Stable decisions belong here; task-specific status belongs in `CURRENT_HANDOFF.md`.
