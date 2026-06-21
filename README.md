<div align="center">

# 🗣️ TalkTranslate

**实时双语翻译通话 App — Real-time bilingual translation calling app**

[![Build APK](https://github.com/malaxiya2019/talktranslate/actions/workflows/build-apk.yml/badge.svg)](https://github.com/malaxiya2019/talktranslate/actions/workflows/build-apk.yml)

</div>

---

## What / 这是什么

**Real-time voice translation during phone calls.**  
Speak your language, the other person hears it in theirs.

**通话中实时语音翻译。** 你说中文，对方听到英文；对方说英文，你听到中文。

## How it works / 工作原理

```
[You: 中文] → STT → LLM翻译 → TTS → [Peer: English]
[Peer: English] → STT → LLM翻译 → TTS → [You: 中文]
```

## Supported Languages / 支持语言

🇨🇳 Chinese / 中文 · 🇺🇸 English · 🇯🇵 Japanese · 🇰🇷 Korean  
🇪🇸 Spanish · 🇫🇷 French · 🇩🇪 German · 🇧🇷 Portuguese  
🇸🇦 Arabic · 🇹🇭 Thai · 🇻🇳 Vietnamese · 🇷🇺 Russian

## Download APK / 下载 APK

No dev machine needed — GitHub Actions builds the APK for you:

1. Go to **[Actions → Build APK](https://github.com/malaxiya2019/talktranslate/actions/workflows/build-apk.yml)**
2. Click the latest successful workflow run
3. Scroll down to **Artifacts**
4. Download your architecture:
   - `talktranslate-arm64-v8a` — Most Android phones (recommended)
   - `talktranslate-armeabi-v7a` — Older devices
   - `talktranslate-x86_64` — Emulators / Chromebooks

## Setup / 配置

### 1. Get an API Key / 获取 API Key

The app uses DeepSeek or OpenAI for translation.  
Get a key from [platform.deepseek.com](https://platform.deepseek.com) or [platform.openai.com](https://platform.openai.com).

### 2. Enter the key in Settings / 在设置中输入 Key

Open the app → tap ⚙️ → paste your API Key → save.

## Tech Stack / 技术栈

| Layer | Library |
|-------|---------|
| UI | Flutter + Material 3 |
| Call | WebRTC (`flutter_webrtc`) |
| Speech-to-Text | `speech_to_text` |
| Text-to-Speech | `flutter_tts` |
| Translation | DeepSeek API (OpenAI-compatible) |
| State | Provider |

## Project Structure / 项目结构

```
talktranslate/
├── lib/
│   ├── main.dart
│   ├── models/
│   │   ├── language.dart
│   │   └── call.dart
│   ├── services/
│   │   ├── translation_service.dart  — LLM translation
│   │   ├── stt_service.dart          — Speech recognition
│   │   ├── tts_service.dart          — Voice synthesis
│   │   ├── call_service.dart         — WebRTC calling
│   │   └── translation_engine.dart   — STT→Translate→TTS pipeline
│   ├── providers/
│   │   └── app_provider.dart
│   └── screens/
│       ├── home_screen.dart
│       ├── call_screen.dart
│       └── settings_screen.dart
└── pubspec.yaml
```

## License / 许可证

MIT
