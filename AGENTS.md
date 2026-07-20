# Codex release contract

For every task that changes shipped behavior, Codex must complete the release workflow before reporting the task finished:

1. Bump the semantic version in `VERSION` and increment `BUILD_NUMBER`; the macOS and Android builds both read these files.
2. Add user-facing notes to `CHANGELOG.md` and replace `RELEASE_NOTES.md` with the notes for that version.
3. Run `swift test`, the Android verification appropriate to the change, credential/path scanning, and third-party license checks.
4. Build and verify the macOS DMG with `script/package_dmg.sh` and any applicable Android artifact. Do not bundle or publish third-party executables without satisfying their exact license and source obligations.
5. Commit all reviewed source and documentation changes. The local post-commit hook pushes the commit to GitHub automatically.
6. Create and push an annotated `v<VERSION>` tag. `.github/workflows/release.yml` then creates the public GitHub Release from `RELEASE_NOTES.md`.
7. Verify the remote commit, public Release page, version, notes, and source archives. Attach only locally validated, legally distributable packages.

Do not publish a release if tests, secret scanning, licensing checks, or packaging verification fail. Never commit downloaded media, credentials, local audit captures, or third-party tool binaries.
