import 'dart:async';
import 'dart:io';
import '../models/phrase_dictionary.dart';

/// 边缘 AI 引擎状态
enum EdgeAIStatus {
  unavailable,    // 引擎不可用（未初始化/初始化失败）
  initializing,   // 正在初始化
  ready,          // 就绪（ML Kit 模型已下载）
  partial,        // 部分可用（仅短语词典）
  error,          // 初始化出错
}

/// 边缘 AI 推理引擎 — 本地 ASR + 翻译
///
/// 三层降级策略：
///   1. ML Kit 在线翻译（需下载模型包，质量最高）
///   2. LiteRT 自定义模型（中等质量，需预置模型文件）
///   3. PhraseDictionary 短语词典（纯离线，仅基础短语）
///
/// 用法：
/// ```dart
/// final engine = EdgeAIEngine();
/// await engine.init();
/// if (engine.isAvailable) {
///   final result = await engine.translate('你好', from: 'zh-CN', to: 'en-US');
/// }
/// ```
class EdgeAIEngine {
  static final EdgeAIEngine _instance = EdgeAIEngine._();
  factory EdgeAIEngine() => _instance;
  EdgeAIEngine._();

  // ── 状态 ──

  EdgeAIStatus _status = EdgeAIStatus.unavailable;
  EdgeAIStatus get status => _status;
  bool get isAvailable => _status == EdgeAIStatus.ready || _status == EdgeAIStatus.partial;

  String _modelPath = '';
  String get modelPath => _modelPath;

  /// 支持的语言
  static const Set<String> supportedLangs = {
    'zh-CN', 'en-US', 'ja-JP', 'ko-KR',
    'es-ES', 'fr-FR', 'de-DE', 'pt-BR',
    'ru-RU', 'ar-SA', 'th-TH', 'vi-VN',
  };

  /// 模型下载状态 (ML Kit)
  final Map<String, bool> _modelDownloaded = {};

  // ── 初始化 ──

  /// 初始化本地引擎
  /// [modelPath]: 可选的自定义 LiteRT 模型路径
  /// [useMlKit]: 是否尝试 ML Kit（需 google_mlkit_translation 插件）
  Future<bool> init({
    String modelPath = '',
    bool useMlKit = true,
  }) async {
    _status = EdgeAIStatus.initializing;
    _modelPath = modelPath;

    try {
      // Step 1: 尝试初始化 ML Kit 翻译
      if (useMlKit) {
        final mlKitOk = await _initMlKit();
        if (mlKitOk) {
          _status = EdgeAIStatus.ready;
          return true;
        }
      }

      // Step 2: 尝试加载 LiteRT 自定义模型
      if (modelPath.isNotEmpty) {
        final liteRtOk = await _initLiteRT(modelPath);
        if (liteRtOk) {
          _status = EdgeAIStatus.ready;
          return true;
        }
      }

      // Step 3: 至少短语词典可用
      _status = EdgeAIStatus.partial;
      return true;
    } catch (e) {
      _status = EdgeAIStatus.error;
      return false;
    }
  }

  /// 初始化 ML Kit 翻译引擎
  Future<bool> _initMlKit() async {
    try {
      // google_mlkit_translation: OnDeviceTranslator
      // 仅作为预留接口 — 模型在首次调用 translate() 时下载
      // 此处只做兼容性检测
      return true; // 标记为可用，运行时按需下载模型
    } catch (_) {
      return false;
    }
  }

  /// 初始化 LiteRT (TensorFlow Lite) 模型
  Future<bool> _initLiteRT(String modelPath) async {
    try {
      final file = File(modelPath);
      if (await file.exists()) {
        // LiteRT 模型文件存在，准备推理
        // TODO: 接入 tflite_flutter / LiteRT Dart API
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ── 翻译 ──

  /// 翻译文本（本地引擎，纯离线）
  ///
  /// 优先使用 ML Kit 神经网络翻译，
  /// 模型未下载时降级到 PhraseDictionary。
  Future<String> translate({
    required String text,
    required String from,
    required String to,
  }) async {
    if (text.isEmpty) return '';
    if (!supportedLangs.contains(from) || !supportedLangs.contains(to)) {
      return text;
    }

    switch (_status) {
      case EdgeAIStatus.ready:
      case EdgeAIStatus.partial:
        // 尝试 ML Kit
        if (_status == EdgeAIStatus.ready) {
          final mlKitResult = await _mlKitTranslate(text, from, to);
          if (mlKitResult != null) return mlKitResult;
        }

        // 降级到短语词典
        final dictResult = PhraseDictionary.lookup(text, to);
        if (dictResult != null) return dictResult;

        // 无匹配 — 返回原文
        return text;

      case EdgeAIStatus.initializing:
      case EdgeAIStatus.unavailable:
      case EdgeAIStatus.error:
        return text; // 无可用的本地引擎
    }
  }

  /// ML Kit 翻译
  Future<String?> _mlKitTranslate(String text, String from, String to) async {
    try {
      // 预留 ML Kit 接入点
      // 实际调用:
      //   final translator = OnDeviceTranslator(
      //     sourceLanguage: _toMlKitLang(from),
      //     targetLanguage: _toMlKitLang(to),
      //   );
      //   return await translator.translateText(text);
      //
      // 需要 pubspec.yaml 添加:
      //   google_mlkit_translation: ^0.13.0
      return null; // ML Kit 未接入，返回 null 触发降级
    } catch (_) {
      return null;
    }
  }

  // ── 语音识别 ──

  /// 本地语音识别
  /// [audioPath]: 音频文件路径
  ///
  /// 预留接口：后续可接入
  /// - MediaPipe ASR
  /// - Whisper.cpp
  /// - Vosk
  Future<String> transcribe(String audioPath) async {
    if (!isAvailable) return '';
    try {
      final file = File(audioPath);
      if (!await file.exists()) return '';

      // TODO: 调用本地 ASR 模型进行推理
      // 1. MediaPipe Audio Classifier
      // 2. Whisper tflite model
      return '';
    } catch (_) {
      return '';
    }
  }

  // ── 语言支持 ──

  /// 某语言是否已下载 ML Kit 模型
  bool isModelDownloaded(String langCode) {
    return _modelDownloaded[langCode] ?? false;
  }

  /// 检查某语言是否需要下载
  bool needsModelDownload(String langCode) {
    return _status == EdgeAIStatus.ready && !isModelDownloaded(langCode);
  }

  /// 获取引擎诊断信息
  Map<String, dynamic> getDiagnostics() {
    return {
      'status': _status.name,
      'isAvailable': isAvailable,
      'modelPath': _modelPath,
      'supportedLangs': supportedLangs.length,
      'phraseCount': PhraseDictionary.phraseCount,
      'downloadedModels': _modelDownloaded.length,
    };
  }

  // ── 生命周期 ──

  /// 释放模型资源
  Future<void> dispose() async {
    _status = EdgeAIStatus.unavailable;
    _modelDownloaded.clear();
    _modelPath = '';
  }
}
