# Hennessy 1.7.12

This release adds evidence-based audio-quality inspection and a recoverable way to improve older low-quality downloads.

## Highlights

- Every local audio file is inspected automatically and labelled with its real codec and effective bitrate.
- Audio below 120 kbps is marked as needing improvement; MP3 is identified as a lossy compatibility conversion.
- **Safe Re-download Low-Quality Files** confirms the batch before starting and skips the currently playing file.
- A candidate replaces the original only when it reaches at least 120 kbps and improves by at least 20% or 16 kbps.
- Originals are moved to timestamped `Hennessy Quality Backups` folders so replacements remain recoverable.
- Download logs now show the selected source format and verify the resulting local file.

Use **Best Audio** when sound quality matters. Converting an existing lossy source to MP3 or FLAC cannot restore missing detail.
