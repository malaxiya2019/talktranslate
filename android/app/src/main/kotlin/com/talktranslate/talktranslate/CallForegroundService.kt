package com.talktranslate.talktranslate

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

/**
 * 通话前台服务 — 防止 Android 杀后台通话进程
 *
 * ── 保活策略 ──
 * 1. startForeground() 持久通知（Android 8+ 必须）
 * 2. START_STICKY 重启（被杀死后自动重建）
 * 3. foregroundServiceType="microphone|communication"（Android 14+ 合规）
 * 4. onTaskRemoved() + onDestroy() 双重清理保障
 *
 * ── 生命周期 ──
 * CallState.inCall  → ACTION_START  → startForeground()
 * 每秒 tick         → ACTION_UPDATE → manager.notify()
 * CallState.idle    → ACTION_STOP   → stopForeground() + stopSelf()
 */
class CallForegroundService : Service() {

    companion object {
        const val CHANNEL_ID = "talktranslate_call"
        const val NOTIFICATION_ID = 1001
        const val ACTION_START = "ACTION_START"
        const val ACTION_STOP = "ACTION_STOP"
        const val ACTION_UPDATE = "ACTION_UPDATE"
        const val EXTRA_PEER = "extra_peer"
        const val EXTRA_DURATION = "extra_duration"
        const val EXTRA_STATUS = "extra_status"
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                val peer = intent.getStringExtra(EXTRA_PEER) ?: "通话中"
                startForeground(NOTIFICATION_ID, buildNotification(peer, "00:00", "已连接"))
            }
            ACTION_UPDATE -> {
                val peer = intent.getStringExtra(EXTRA_PEER) ?: "通话中"
                val duration = intent.getStringExtra(EXTRA_DURATION) ?: "00:00"
                val status = intent.getStringExtra(EXTRA_STATUS) ?: "通话中"
                val notification = buildNotification(peer, duration, status)
                val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
                manager.notify(NOTIFICATION_ID, notification)
            }
            ACTION_STOP -> {
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
        }
        // START_STICKY: 被系统杀死后自动重建（但不保留 Intent）
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    /**
     * 用户滑动杀掉任务时，通知 Flutter 层重新启动服务
     */
    override fun onTaskRemoved(rootIntent: Intent?) {
        // 重启服务的 Intent
        val restartIntent = Intent(this, CallForegroundService::class.java).apply {
            action = ACTION_START
            putExtra(EXTRA_PEER, "重新连接中")
        }
        // Android 14+ 需要 FLAG_IMMUTABLE
        val pendingIntent = PendingIntent.getService(
            this, 0, restartIntent,
            PendingIntent.FLAG_ONE_SHOT or PendingIntent.FLAG_IMMUTABLE
        )
        pendingIntent.send()
        super.onTaskRemoved(rootIntent)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "通话服务",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "TalkTranslate 通话进行中通知"
                setShowBadge(false)
            }
            val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(peer: String, duration: String, status: String): Notification {
        // 点击通知回到 App（使用 launchIntent 确保 Activity 恢复而非重建）
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
        }
        val openPendingIntent = PendingIntent.getActivity(
            this, 0, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("TalkTranslate · $peer")
            .setContentText("📞 通话中 $duration")
            .setSubText(status)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .setContentIntent(openPendingIntent)
            .setSilent(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }
}
