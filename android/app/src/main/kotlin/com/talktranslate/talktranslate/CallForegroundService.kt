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
 * 通话前台服务 — 防止 Android 10+ 杀后台进程
 *
 * 通话中启动，挂断后停止。
 * 显示持久通知："TalkTranslate 通话中..."
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
                startForeground(NOTIFICATION_ID, buildNotification(peer, "00:00"))
            }
            ACTION_UPDATE -> {
                val peer = intent.getStringExtra(EXTRA_PEER) ?: "通话中"
                val duration = intent.getStringExtra(EXTRA_DURATION) ?: "00:00"
                val notification = buildNotification(peer, duration)
                val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
                manager.notify(NOTIFICATION_ID, notification)
            }
            ACTION_STOP -> {
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

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

    private fun buildNotification(peer: String, duration: String): Notification {
        val openIntent = packageManager.getLaunchIntentForPackage(packageName)
        val openPendingIntent = PendingIntent.getActivity(
            this, 0, openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val status = peer // 实际传入了 "已连接" 等状态文字
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("TalkTranslate")
            .setContentText("正在与 $peer 通话 · $duration")
            .setSubText("[$status]")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .setContentIntent(openPendingIntent)
            .setSilent(true)
            .build()
    }
}
