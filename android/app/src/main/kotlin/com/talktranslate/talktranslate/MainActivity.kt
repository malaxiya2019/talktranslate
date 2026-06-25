package com.talktranslate.talktranslate

import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val FOREGROUND_CHANNEL = "talktranslate/foreground"
    private val SERVICE_CHANNEL = "talktranslate/foreground_service"
    private val AUDIO_FOCUS_CHANNEL = "talktranslate/audio_focus"
    private val NETWORK_CHANNEL = "talktranslate/network_state"
    private val PLATFORM_CHANNEL = "talktranslate/platform"

    private var audioFocusRequest: AudioFocusRequest? = null
    private lateinit var audioManager: AudioManager
    private lateinit var connectivityManager: ConnectivityManager
    private var networkCallback: ConnectivityManager.NetworkCallback? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        audioManager = getSystemService(AUDIO_SERVICE) as AudioManager
        connectivityManager = getSystemService(CONNECTIVITY_SERVICE) as ConnectivityManager

        // 悬浮窗 → 回到前台
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FOREGROUND_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "bringToForeground" -> {
                        bringAppToForeground()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        // 前台服务
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SERVICE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startService" -> handleStartService(call)
                    "updateNotification" -> handleUpdateNotification(call)
                    "stopService" -> handleStopService()
                    else -> result.notImplemented()
                }
                result.success(true)
            }

        // 音频焦点管理
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_FOCUS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestFocus" -> result.success(requestAudioFocus())
                    "abandonFocus" -> {
                        abandonAudioFocus()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        // 网络状态监听
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NETWORK_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startMonitoring" -> {
                        startNetworkMonitoring(flutterEngine)
                        result.success(true)
                    }
                    "stopMonitoring" -> {
                        stopNetworkMonitoring()
                        result.success(true)
                    }
                    "getCurrentNetworkType" -> {
                        result.success(getCurrentNetworkType())
                    }
                    else -> result.notImplemented()
                }
            }

        // ── 平台能力：权限 + 电池优化 ──
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PLATFORM_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestNotificationPermission" -> {
                        // Android 13+ 需要运行时请求 POST_NOTIFICATIONS
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 9001)
                        }
                        result.success(true)
                    }
                    "hasNotificationPermission" -> {
                        val granted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) ==
                                    android.content.pm.PackageManager.PERMISSION_GRANTED
                        } else {
                            true // Android 12- 无需运行时权限
                        }
                        result.success(granted)
                    }
                    "isIgnoringBatteryOptimizations" -> {
                        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                        result.success(pm.isIgnoringBatteryOptimizations(packageName))
                    }
                    "requestBatteryOptimizationWhitelist" -> {
                        val intent = Intent(
                            Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                            android.net.Uri.parse("package:$packageName")
                        )
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // ── Foreground Service Helpers ──

    private fun handleStartService(call: MethodCall) {
        val peer = call.argument<String>("peer") ?: "通话中"
        val intent = Intent(this, CallForegroundService::class.java).apply {
            action = CallForegroundService.ACTION_START
            putExtra(CallForegroundService.EXTRA_PEER, peer)
        }
        startForegroundService(intent)
    }

    private fun handleUpdateNotification(call: MethodCall) {
        val peer = call.argument<String>("peer") ?: "通话中"
        val duration = call.argument<String>("duration") ?: "00:00"
        val intent = Intent(this, CallForegroundService::class.java).apply {
            action = CallForegroundService.ACTION_UPDATE
            putExtra(CallForegroundService.EXTRA_PEER, peer)
            putExtra(CallForegroundService.EXTRA_DURATION, duration)
        }
        startService(intent)
    }

    private fun handleStopService() {
        val intent = Intent(this, CallForegroundService::class.java).apply {
            action = CallForegroundService.ACTION_STOP
        }
        startService(intent)
    }

    private fun bringAppToForeground() {
        // 使用 FLAG_ACTIVITY_REORDER_TO_FRONT：如果 Activity 已在栈中，直接提到前台
        // 避免 getLaunchIntentForPackage 重新创建实例
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
        }
        startActivity(intent)
    }

    // ── Audio Focus (Spec-compliant) ──

    private fun requestAudioFocus(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val attributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
                .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                .build()
            audioFocusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
                .setAudioAttributes(attributes)
                .setAcceptsDelayedFocusGain(true)
                .setOnAudioFocusChangeListener { focusChange ->
                    when (focusChange) {
                        AudioManager.AUDIOFOCUS_LOSS -> {
                            hasAudioFocus = false
                            // Notify Dart layer
                        }
                        AudioManager.AUDIOFOCUS_GAIN -> {
                            hasAudioFocus = true
                        }
                    }
                }
                .build()
            val result = audioManager.requestAudioFocus(audioFocusRequest!!)
            hasAudioFocus = result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        } else {
            @Suppress("DEPRECATION")
            val result = audioManager.requestAudioFocus(
                null, AudioManager.STREAM_VOICE_CALL, AudioManager.AUDIOFOCUS_GAIN
            )
            hasAudioFocus = result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        }
        return hasAudioFocus
    }

    private fun abandonAudioFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest?.let { audioManager.abandonAudioFocusRequest(it) }
        } else {
            @Suppress("DEPRECATION")
            audioManager.abandonAudioFocus(null)
        }
        audioFocusRequest = null
        hasAudioFocus = false
    }

    companion object {
        var hasAudioFocus = false
        var currentNetworkType = "unknown"
    }

    // ── Network Monitoring ──

    private fun startNetworkMonitoring(flutterEngine: FlutterEngine) {
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NETWORK_CHANNEL)
        val callback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                currentNetworkType = getCurrentNetworkType()
                Handler(Looper.getMainLooper()).post {
                    channel.invokeMethod("onNetworkAvailable", currentNetworkType)
                }
            }

            override fun onLost(network: Network) {
                currentNetworkType = "none"
                Handler(Looper.getMainLooper()).post {
                    channel.invokeMethod("onNetworkLost", null)
                }
            }

            override fun onCapabilitiesChanged(
                network: Network,
                capabilities: NetworkCapabilities
            ) {
                currentNetworkType = when {
                    capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "wifi"
                    capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "cellular"
                    capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "ethernet"
                    else -> "unknown"
                }
                Handler(Looper.getMainLooper()).post {
                    channel.invokeMethod("onNetworkChanged", currentNetworkType)
                }
            }
        }
        networkCallback = callback

        val request = NetworkRequest.Builder()
            .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .build()
        connectivityManager.registerNetworkCallback(request, callback)
    }

    private fun stopNetworkMonitoring() {
        networkCallback?.let { connectivityManager.unregisterNetworkCallback(it) }
        networkCallback = null
    }

    private fun getCurrentNetworkType(): String {
        val network = connectivityManager.activeNetwork ?: return "none"
        val caps = connectivityManager.getNetworkCapabilities(network) ?: return "unknown"
        return when {
            caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "wifi"
            caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "cellular"
            caps.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "ethernet"
            else -> "unknown"
        }
    }
}
