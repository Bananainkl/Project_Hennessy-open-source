# Packaged Tool Resources

Hennessy can bundle `ffmpeg` and `yt-dlp` inside the macOS app. Their executable files are intentionally excluded from Git because they are large third-party release artifacts.

For local development, install the tools with Homebrew:

```bash
brew install ffmpeg yt-dlp
```

For a self-contained packaged build, place executable macOS arm64 copies at:

```text
Assets/Tools/ffmpeg
Assets/Tools/yt-dlp
```

Then verify their versions, licenses, checksums, architecture, and executable permissions before running the packaging script. Keep `THIRD_PARTY_NOTICES.txt` synchronized with the exact distributed versions.
