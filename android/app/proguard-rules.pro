# TalkTranslate ProGuard Rules

# Flutter / Dart
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# WebRTC
-keep class org.webrtc.** { *; }

# flutter_overlay_window
-keep class com.xiaohao.overlay_window.** { *; }

# JSON 序列化 (CallSnapshot / CallRecord)
-keepclassmembers class com.talktranslate.talktranslate.** {
    <fields>;
    <methods>;
}

# Keep MethodChannel 回调
-keep class * extends io.flutter.plugin.common.MethodCallHandler { *; }

# Keep 前台服务
-keep class com.talktranslate.talktranslate.CallForegroundService { *; }

# SharedPreferences
-dontwarn com.google.common.**
-dontwarn okhttp3.**

# Flutter 引擎
-keep class * implements io.flutter.embedding.engine.plugins.FlutterPlugin { *; }
-keep class * implements io.flutter.plugin.common.PluginRegistry.Registrar { *; }
