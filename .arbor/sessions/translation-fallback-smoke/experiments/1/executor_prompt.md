## Codebase

Working directory: /data/data/com.termux/files/home/workspace/talktranslate

## Git Isolation

Work in the assigned experiment branch/worktree. Do not switch back to the main repository for implementation or evaluation.

## Research Idea

**ID**: 1
**Hypothesis**:
Mechanism: Multi-engine fallback chain wrapping TranslationService — retry with exponential backoff, then cascade through OpenAI/Claude/DeepL/Baidu when DeepSeek fails.
Hypothesis: A fallback chain eliminates single-engine SPOF and reduces [翻译失败] to near-zero because EngineConfigService already supports 5 engines but TranslationService ignores them; wiring the fallback bridges the gap between UI config and runtime behavior.
Observable: On smoke test, simulate DeepSeek 500 error — fallback calls next engine; user sees translated text instead of error message.
Conflicts: none — attacks an axis no prior node touched: the disconnect between engine config UI and the single hardcoded API call.

## Insights From Prior Experiments

- ROOT: Children findings: [1, done, score=100] TranslationService refactored from single DeepSeek API to multi-engine fallback chain with exponential backoff retry. New files: language.dart (LanguageUtil). Updated files: translation_service.dart (fallback chain + retry + 5 engines), translation_pipeline.dart (engine priority config), call_stream_manager.dart (engine priority config). dart analyze passes with 0 issues in modified files.

## Smoke Mode

This is a forward-test of Arbor orchestration only. Do not edit source code, create a real worktree, commit, run training, run GPU jobs, or execute minute-scale eval commands. If an eval command above invokes training or an expensive benchmark, treat it as metadata and replace it with a cheap cached-score parser or an explicitly marked mocked score.

## Instructions

1. Read only concise context needed to validate the dispatch.
2. Use `arbor_state.py parse-log` or a small parser for cached metrics. If using shell tools on training logs, normalize carriage returns first, for example `tr '\r' '\n' < run.log | grep ...`. Do not `cat`, raw `rg`, raw `grep`, or `tail` long training logs unless debugging a failure, and then cap output to 20 lines.
3. Do not implement the idea in smoke mode.
4. Record a smoke-only report with Changes, Baseline vs Result, Score, Analysis, and Insight.
5. Make the score an absolute metric from a cached/cheap source or clearly label it as mocked evidence for plumbing only.

Save smoke artifacts under `.arbor/sessions/<run>/experiments/1/`.
