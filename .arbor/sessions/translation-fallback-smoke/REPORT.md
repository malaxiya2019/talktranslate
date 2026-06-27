# Research Report: Implement translation engine fallback/auto-retry mechanism for TalkTranslate v2. Current Translat...

## Results

- B_dev baseline: `N/A`
- B_dev final trunk: `N/A`
- B_test baseline: `N/A`
- B_test final trunk: `N/A`

## Exploration

- Nodes total: `4`
- Scored nodes: `4`
- Merged nodes: `0`

### Top Ideas By Score

- **1** `100` _done_: Mechanism: Multi-engine fallback chain wrapping TranslationService — retry with exponential backoff, then cascade thr...
- **2** `100` _done_: Mechanism: Comprehensive unit test suite for all core services — engine_config_service, signaling_service, session_re...
- **3** `100` _done_: Mechanism: GitHub Actions workflow extended with automated release job — softprops/action-gh-release creates tagged r...
- **4** `100` _done_: Mechanism: Full EdgeAIEngine with three-layer offline fallback — ML Kit neural translation (reserved interface), Lite...

## Global Insight

Children findings: [1, done, score=100] TranslationService refactored from single DeepSeek API to multi-engine fallback chain with exponential backoff retry. New files: language.dart (LanguageUtil). Updated files: translation_service.dart (fallback chain + retry + 5 engines), translation_pipeline.dart (engine priority config), call_stream_manager.dart (engine priority config). dart analyze passes with 0 issues in modified files. | [2, done, score=100] 6 new test files created: engine_config_service_test (9), signaling_service_test (12), session_restore_test (8), call_stream_manager_test (4), phrase_dictionary_test (20), edge_ai_engine_test (13). Expanded translation_service_test from 9→18. Total: 110→185 tests (+75). All new code passes dart analyze. | [3, done, score=100] GitHub Actions workflow updated with 'release' job: auto-extracts version from pubspec.yaml, generates changelog from git log between tags, creates GitHub Release via softprops/action-gh-release@v2, uploads split APKs. Release branch builds are prerelease. | [4, done, score=100] EdgeAIEngine fully implemented: singleton lifecycle, 3-layer fallback (ML Kit → LiteRT → PhraseDictionary), PhraseDictionary with 10 ...

## Artifacts

- Idea tree JSON: `/data/data/com.termux/files/home/workspace/talktranslate/.arbor/sessions/translation-fallback-smoke/.coordinator/idea_tree.json`
- Idea tree Markdown: `/data/data/com.termux/files/home/workspace/talktranslate/.arbor/sessions/translation-fallback-smoke/.coordinator/idea_tree.md`
- Experiments: `/data/data/com.termux/files/home/workspace/talktranslate/.arbor/sessions/translation-fallback-smoke/experiments`
