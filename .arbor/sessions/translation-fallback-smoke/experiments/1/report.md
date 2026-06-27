# Experiment 1

**Hypothesis**: Mechanism: Multi-engine fallback chain wrapping TranslationService — retry with exponential backoff, then cascade through OpenAI/Claude/DeepL/Baidu when DeepSeek fails.
Hypothesis: A fallback chain eliminates single-engine SPOF and reduces [翻译失败] to near-zero because EngineConfigService already supports 5 engines but TranslationService ignores them; wiring the fallback bridges the gap between UI config and runtime behavior.
Observable: On smoke test, simulate DeepSeek 500 error — fallback calls next engine; user sees translated text instead of error message.
Conflicts: none — attacks an axis no prior node touched: the disconnect between engine config UI and the single hardcoded API call.

**Score**: 100.0

**Insight**: TranslationService refactored from single DeepSeek API to multi-engine fallback chain with exponential backoff retry. New files: language.dart (LanguageUtil). Updated files: translation_service.dart (fallback chain + retry + 5 engines), translation_pipeline.dart (engine priority config), call_stream_manager.dart (engine priority config). dart analyze passes with 0 issues in modified files.

**Result**: SUCCESS: dart analyze passes clean. Fallback chain implemented: DeepSeek → OpenAI → Claude → DeepL → Baidu with max 3 retries per engine and exponential backoff (1s/2s/4s). EngineConfigService integration complete. Backward compatible — setApiKey() still works. 10 new unit tests written in test/unit/translation_service_test.dart.
