package com.smsindia.app; // <--- CHANGE THIS TO MATCH YOUR PACKAGE NAME

import android.content.Intent;
import android.os.Build;
import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import com.smsindia.app.service.MiningService; // Check this import path

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.smsindia.app/mining";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
            .setMethodCallHandler(
                (call, result) -> {
                    if (call.method.equals("START_MINING")) {
                        String userId = call.argument("userId");
                        int simSlot = call.argument("simSlot");
                        
                        Intent serviceIntent = new Intent(this, MiningService.class);
                        serviceIntent.putExtra("userId", userId);
                        serviceIntent.putExtra("simSlot", simSlot);
                        
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(serviceIntent);
                        } else {
                            startService(serviceIntent);
                        }
                        result.success("STARTED");
                        
                    } else if (call.method.equals("STOP_MINING")) {
                        Intent serviceIntent = new Intent(this, MiningService.class);
                        serviceIntent.setAction("STOP");
                        startService(serviceIntent);
                        result.success("STOPPED");
                        
                    } else {
                        result.notImplemented();
                    }
                }
            );
    }
}
