package com.talktranslate.talktranslate

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val FOREGROUND_CHANNEL = "talktranslate/foreground"
    private val SERVICE_CHANNEL = "talktranslate/foreground_service"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 悬浮窗 → 回到前台
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FOREGROUND_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "bringToForeground" -> {
                        val intent = packageManager.getLaunchIntentForPackage(packageName)
                        intent?.flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                                Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
                        startActivity(intent)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        // 前台服务 → 防杀保活
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SERVICE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startService" -> {
                        val peer = call.argument<String>("peer") ?: "通话中"
                        val intent = Intent(this, CallForegroundService::class.java).apply {
                            action = CallForegroundService.ACTION_START
                            putExtra(CallForegroundService.EXTRA_PEER, peer)
                        }
                        startForegroundService(intent)
                        result.success(true)
                    }
                    "updateNotification" -> {
                        val peer = call.argument<String>("peer") ?: "通话中"
                        val duration = call.argument<String>("duration") ?: "00:00"
                        val intent = Intent(this, CallForegroundService::class.java).apply {
                            action = CallForegroundService.ACTION_UPDATE
                            putExtra(CallForegroundService.EXTRA_PEER, peer)
                            putExtra(CallForegroundService.EXTRA_DURATION, duration)
                        }
                        startService(intent)
                        result.success(true)
                    }
                    "stopService" -> {
                        val intent = Intent(this, CallForegroundService::class.java).apply {
                            action = CallForegroundService.ACTION_STOP
                        }
                        startService(intent)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
