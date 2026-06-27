# Experiment 3

**Hypothesis**: Mechanism: GitHub Actions workflow extended with automated release job — softprops/action-gh-release creates tagged releases on push to main/release with auto-generated changelog from git log and APK artifact uploads.
Hypothesis: Automating releases eliminates manual upload friction; commits between tags generate structured release notes; release branch produces prerelease for testing.
Observable: On next push to main, a GitHub Release v2.0.2+3 appears with release notes and APK/AAB downloads.
Conflicts: none — no prior automation existed beyond CI build.

**Score**: 100.0

**Insight**: GitHub Actions workflow updated with 'release' job: auto-extracts version from pubspec.yaml, generates changelog from git log between tags, creates GitHub Release via softprops/action-gh-release@v2, uploads split APKs. Release branch builds are prerelease.

**Result**: SUCCESS: Workflow updated. Next push to main triggers auto-release with APK artifacts and changelog.
