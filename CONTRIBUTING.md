# Development Workflow

Use `main` as the stable branch. Do not commit packaged apps, DMGs, APKs, local audit captures, build caches, credentials, or downloaded media.

## Local verification

```bash
swift test
./script/build_and_run.sh --verify
```

The Android build instructions are in `android-app/README.md`.

## Submit a change

Create a topic branch and open a pull request:

```bash
git switch -c feature/short-description
git commit -m "Describe the change"
git push -u origin feature/short-description
```

Review the staged diff before committing. Contributions must be compatible with GPL-3.0-only, and changes to bundled tools must update their exact version, checksum, source, and license notice.
