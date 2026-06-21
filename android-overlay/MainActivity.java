package com.example.talktranslate;

import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;
import android.provider.Settings;
import androidx.core.content.ContextCompat;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "talktranslate/overlay";

    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
            .setMethodCallHandler((call, result) -> {
                switch (call.method) {
                    case "hasPermission":
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            result.success(Settings.canDrawOverlays(this));
                        } else {
                            result.success(true);
                        }
                        break;

                    case "requestPermission":
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            Intent intent = new Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                android.net.Uri.parse("package:" + getPackageName())
                            );
                            startActivity(intent);
                        }
                        result.success(true);
                        break;

                    case "startService":
                        Intent svc = new Intent(this, TalkTranslateOverlayService.class);
                        ContextCompat.startForegroundService(this, svc);
                        result.success(true);
                        break;

                    case "show":
                        String original = call.argument("original");
                        String translated = call.argument("translated");
                        Intent showIntent = new Intent(this, TalkTranslateOverlayService.class);
                        showIntent.putExtra("action", "show");
                        showIntent.putExtra("original", original);
                        showIntent.putExtra("translated", translated);
                        startService(showIntent);
                        result.success(true);
                        break;

                    case "hide":
                        Intent hideIntent = new Intent(this, TalkTranslateOverlayService.class);
                        hideIntent.putExtra("action", "hide");
                        startService(hideIntent);
                        result.success(true);
                        break;

                    case "stopService":
                        stopService(new Intent(this, TalkTranslateOverlayService.class));
                        result.success(true);
                        break;

                    default:
                        result.notImplemented();
                }
            });
    }
}
