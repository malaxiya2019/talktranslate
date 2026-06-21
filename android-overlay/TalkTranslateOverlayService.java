package com.example.talktranslate;

import android.app.Service;
import android.content.Intent;
import android.graphics.PixelFormat;
import android.graphics.Typeface;
import android.os.Build;
import android.os.IBinder;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.WindowManager;
import android.widget.LinearLayout;
import android.widget.TextView;

/**
 * 悬浮窗翻译服务
 * 在通话界面之上显示实时翻译字幕
 */
public class TalkTranslateOverlayService extends Service {

    private WindowManager windowManager;
    private LinearLayout overlayView;
    private TextView originalText;
    private TextView translatedText;
    private int originalY = 200;
    private int prevY;

    @Override
    public IBinder onBind(Intent intent) { return null; }

    @Override
    public void onCreate() {
        super.onCreate();
        windowManager = (WindowManager) getSystemService(WINDOW_SERVICE);
        createOverlay();
    }

    private void createOverlay() {
        LayoutInflater inflater = LayoutInflater.from(this);
        overlayView = new LinearLayout(this);
        overlayView.setOrientation(LinearLayout.VERTICAL);
        overlayView.setBackgroundColor(0xBB000000);
        overlayView.setPadding(24, 16, 24, 16);

        // 原文 (你的话)
        originalText = new TextView(this);
        originalText.setTextSize(20);
        originalText.setTextColor(0xFFFFFFFF);
        originalText.setTypeface(null, Typeface.NORMAL);
        originalText.setAlpha(0.9f);
        originalText.setShadowLayer(4, 0, 2, 0xFF000000);

        // 分隔线
        View divider = new View(this);
        divider.setLayoutParams(new LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, 1));
        divider.setBackgroundColor(0x44FFFFFF);
        divider.setAlpha(0.3f);

        // 翻译 (对方语言)
        translatedText = new TextView(this);
        translatedText.setTextSize(22);
        translatedText.setTextColor(0xFF00FFAA);
        translatedText.setTypeface(null, Typeface.BOLD);
        translatedText.setShadowLayer(4, 0, 2, 0xFF000000);

        overlayView.addView(originalText);
        overlayView.addView(divider);
        overlayView.addView(translatedText);

        // 宽度: 屏幕宽度 - 32dp
        int width = (int) (getResources().getDisplayMetrics().widthPixels * 0.92);

        WindowManager.LayoutParams params;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            params = new WindowManager.LayoutParams(
                width,
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                    | WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN
                    | WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                PixelFormat.TRANSLUCENT);
        } else {
            params = new WindowManager.LayoutParams(
                width,
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.TYPE_PRIORITY_PHONE,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
                PixelFormat.TRANSLUCENT);
        }

        params.gravity = Gravity.TOP | Gravity.CENTER_HORIZONTAL;
        params.y = originalY;

        // 拖动
        overlayView.setOnTouchListener((v, event) -> {
            switch (event.getAction()) {
                case MotionEvent.ACTION_DOWN:
                    prevY = (int) event.getRawY();
                    return true;
                case MotionEvent.ACTION_MOVE:
                    params.y += (int) (event.getRawY() - prevY);
                    originalY = params.y;
                    prevY = (int) event.getRawY();
                    windowManager.updateViewLayout(overlayView, params);
                    return true;
            }
            return false;
        });

        overlayView.setVisibility(View.GONE);
        windowManager.addView(overlayView, params);
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent != null) {
            String action = intent.getStringExtra("action");
            if ("show".equals(action)) {
                String original = intent.getStringExtra("original");
                String translated = intent.getStringExtra("translated");
                showOverlay(original, translated);
            } else if ("hide".equals(action)) {
                hideOverlay();
            }
        }
        return START_STICKY;
    }

    public void showOverlay(String original, String translated) {
        if (overlayView != null) {
            originalText.setText(original != null ? original : "");
            translatedText.setText(translated != null ? translated : "翻译中...");
            overlayView.setVisibility(View.VISIBLE);
        }
    }

    public void hideOverlay() {
        if (overlayView != null) {
            overlayView.setVisibility(View.GONE);
        }
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        if (overlayView != null) {
            windowManager.removeView(overlayView);
            overlayView = null;
        }
    }
}
