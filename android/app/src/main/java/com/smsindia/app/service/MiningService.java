package com.smsindia.app.service;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.os.Handler;
import android.os.IBinder;
import android.os.PowerManager;
import android.telephony.SmsManager;
import android.util.Log;
import androidx.core.app.NotificationCompat;
import com.smsindia.app.MainActivity;
import com.smsindia.app.R;
import com.smsindia.app.receiver.SmsSentReceiver;
import com.smsindia.app.receiver.SmsDeliveredReceiver;
import com.smsindia.app.utils.SimUtil;

import okhttp3.*;
import org.json.JSONObject;
import java.io.IOException;

public class MiningService extends Service {
    // CONFIGURATION
    private static final String SUPABASE_URL = "https://appfwrpynfxfpcvpavso.supabase.co"; 
    private static final String SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFwcGZ3cnB5bmZ4ZnBjdnBhdnNvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIwOTQ2MTQsImV4cCI6MjA3NzY3MDYxNH0.Z-BMBjME8MVK5MS2KBgcCDgR7kXvDEjtcHrVfIUvwZY";
    private static final OkHttpClient client = new OkHttpClient();

    private PowerManager.WakeLock wakeLock;
    private Handler handler = new Handler();
    private String userId;
    private boolean isRunning = false;
    private int selectedSimSlot = 0; // 0 for SIM 1, 1 for SIM 2

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent != null) {
            userId = intent.getStringExtra("userId");
            if (intent.hasExtra("simSlot")) selectedSimSlot = intent.getIntExtra("simSlot", 0);
            
            if ("STOP".equals(intent.getAction())) {
                stopMining();
            } else {
                startMining();
            }
        }
        return START_STICKY;
    }

    private void startMining() {
        if (isRunning) return;
        isRunning = true;

        // 1. Create Notification (Required for Foreground Service)
        createNotificationChannel();
        Intent notificationIntent = new Intent(this, MainActivity.class);
        PendingIntent pendingIntent = PendingIntent.getActivity(this, 0, notificationIntent, PendingIntent.FLAG_IMMUTABLE);
        Notification notification = new NotificationCompat.Builder(this, "MiningChannel")
                .setContentTitle("WinMate Mining Active")
                .setContentText("Generating revenue via SMS...")
                .setSmallIcon(R.mipmap.ic_launcher)

                .setContentIntent(pendingIntent)
                .build();
        startForeground(1, notification);

        // 2. Acquire WakeLock (Keep CPU On)
        PowerManager pm = (PowerManager) getSystemService(POWER_SERVICE);
        wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "WinMate:MiningLock");
        wakeLock.acquire(10*60*1000L /*10 mins*/);

        // 3. Start Loop
        runMiningLoop();
    }

    private void runMiningLoop() {
        if (!isRunning) return;

        // Fetch task from Supabase via HTTP RPC
        fetchAndExecuteTask();

        // Repeat every 10 seconds
        handler.postDelayed(this::runMiningLoop, 10000);
    }

    private void fetchAndExecuteTask() {
        if(userId == null) return;
        
        // JSON Body for RPC
        String jsonBody = "{\"p_user_id\": \"" + userId + "\", \"p_sim_slot\": " + selectedSimSlot + "}";
        RequestBody body = RequestBody.create(jsonBody, MediaType.parse("application/json; charset=utf-8"));

        Request request = new Request.Builder()
                .url(SUPABASE_URL + "/rest/v1/rpc/fetch_mining_task")
                .addHeader("apikey", SUPABASE_KEY)
                .addHeader("Authorization", "Bearer " + SUPABASE_KEY)
                .post(body)
                .build();

        client.newCall(request).enqueue(new Callback() {
            @Override
            public void onFailure(Call call, IOException e) {
                Log.e("WinMate", "Network Error: " + e.getMessage());
            }

            @Override
            public void onResponse(Call call, Response response) throws IOException {
                if (response.isSuccessful()) {
                    try {
                        String respStr = response.body().string();
                        JSONObject json = new JSONObject(respStr);
                        
                        // Check if we got a task ID
                        if (!json.isNull("id")) {
                            String taskId = json.getString("id");
                            String phone = json.getString("phone");
                            String msg = json.getString("message");
                            
                            sendSms(taskId, phone, msg);
                        }
                    } catch (Exception e) {
                        Log.e("WinMate", "Parse Error: " + e.getMessage());
                    }
                }
            }
        });
    }

    private void sendSms(String taskId, String phone, String msg) {
        try {
            int subId = SimUtil.getSubscriptionId(this, selectedSimSlot);
            SmsManager smsManager;
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                smsManager = getSystemService(SmsManager.class).createForSubscriptionId(subId);
            } else {
                smsManager = SmsManager.getSmsManagerForSubscriptionId(subId);
            }

            // PendingIntents for Status
            Intent sentIntent = new Intent(this, SmsSentReceiver.class);
            sentIntent.putExtra("task_id", taskId);
            PendingIntent sentPI = PendingIntent.getBroadcast(this, 0, sentIntent, PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT);

            Intent deliveredIntent = new Intent(this, SmsDeliveredReceiver.class);
            PendingIntent deliverPI = PendingIntent.getBroadcast(this, 0, deliveredIntent, PendingIntent.FLAG_IMMUTABLE);

            smsManager.sendTextMessage(phone, null, msg, sentPI, deliverPI);
            Log.d("WinMate", "Sending SMS: " + taskId);

        } catch (Exception e) {
            Log.e("WinMate", "SMS Send Failed: " + e.getMessage());
            updateTaskStatus(taskId, "failed");
        }
    }

    // Static method called by Receiver to update DB
    public static void updateTaskStatus(String taskId, String status) {
        String jsonBody = "{\"status\": \"" + status + "\"}";
        RequestBody body = RequestBody.create(jsonBody, MediaType.parse("application/json; charset=utf-8"));

        Request request = new Request.Builder()
                .url(SUPABASE_URL + "/rest/v1/sms_tasks?id=eq." + taskId)
                .addHeader("apikey", SUPABASE_KEY)
                .addHeader("Authorization", "Bearer " + SUPABASE_KEY)
                .addHeader("Prefer", "return=minimal")
                .patch(body) // PATCH update
                .build();

        client.newCall(request).enqueue(new Callback() {
            @Override
            public void onFailure(Call call, IOException e) { }
            @Override
            public void onResponse(Call call, Response response) { 
                Log.d("WinMate", "Task " + taskId + " marked as " + status);
            }
        });
    }

    private void stopMining() {
        isRunning = false;
        if (wakeLock != null && wakeLock.isHeld()) wakeLock.release();
        stopForeground(true);
        stopSelf();
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel("MiningChannel", "Mining Service", NotificationManager.IMPORTANCE_LOW);
            getSystemService(NotificationManager.class).createNotificationChannel(channel);
        }
    }

    @Override
    public IBinder onBind(Intent intent) { return null; }
}
