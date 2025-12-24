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
import java.util.ArrayList;

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
    private int retryCount = 0;
    private static final int MAX_RETRIES = 3;
    
    // 3-second delay tracking
    private boolean delayActive = false;
    private long delayStartTime = 0;
    private static final long DELAY_DURATION = 3000; // 3 seconds

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
                .setContentTitle("SMSindia Mining Active")
                .setContentText("3-second delay between SMS tasks")
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentIntent(pendingIntent)
                .setOngoing(true) // Prevent user from dismissing
                .build();
        startForeground(1, notification);

        // 2. Acquire WakeLock (Optimized for Battery)
        PowerManager pm = (PowerManager) getSystemService(POWER_SERVICE);
        wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "SMSindia:MiningLock");
        wakeLock.acquire(10 * 60 * 1000L /*10 mins*/);

        // 3. Start Loop
        runMiningLoop();
    }

    private void runMiningLoop() {
        if (!isRunning) return;

        // Check if delay is still active
        if (delayActive) {
            long timeSinceDelayStart = System.currentTimeMillis() - delayStartTime;
            if (timeSinceDelayStart >= DELAY_DURATION) {
                delayActive = false;
                Log.d("SMSindia", "3-second delay completed");
            } else {
                long remaining = DELAY_DURATION - timeSinceDelayStart;
                Log.d("SMSindia", "Delay active, " + remaining + "ms remaining");
                
                // Check again after remaining time
                handler.postDelayed(this::runMiningLoop, Math.min(remaining, 1000));
                return;
            }
        }

        fetchAndExecuteTask();

        // Adjust delay dynamically based on network conditions
        long delay = (retryCount > 0) ? 30000 : 10000; // 30s if retrying, else 10s
        handler.postDelayed(this::runMiningLoop, delay);
    }

    private void fetchAndExecuteTask() {
        if (userId == null) return;
        
        RequestBody body = RequestBody.create(
            "{\"p_user_id\": \"" + userId + "\", \"p_sim_slot\": " + selectedSimSlot + "}",
            MediaType.parse("application/json; charset=utf-8")
        );

        Request request = new Request.Builder()
                .url(SUPABASE_URL + "/rest/v1/rpc/fetch_mining_task")
                .addHeader("apikey", SUPABASE_KEY)
                .addHeader("Authorization", "Bearer " + SUPABASE_KEY)
                .post(body)
                .build();

        client.newCall(request).enqueue(new Callback() {
            @Override
            public void onFailure(Call call, IOException e) {
                Log.e("SMSindia", "Network Error: " + e.getMessage());
                retryCount = Math.min(retryCount + 1, MAX_RETRIES);
            }

            @Override
            public void onResponse(Call call, Response response) throws IOException {
                if (response.isSuccessful()) {
                    retryCount = 0; // Reset retry counter on success
                    try {
                        String responseBody = response.body().string();
                        Log.d("SMSindia", "Response: " + responseBody);
                        
                        JSONObject json = new JSONObject(responseBody);
                        
                        // Check if delay is active from server
                        if (json.has("delay_active")) {
                            Log.d("SMSindia", "3-second delay active from server");
                            delayActive = true;
                            delayStartTime = System.currentTimeMillis();
                            return;
                        }
                        
                        // Check if task exists
                        if (!json.isNull("id")) {
                            String taskId = json.getString("id");
                            String phone = json.getString("phone");
                            String msg = json.getString("message");
                            
                            Log.d("SMSindia", "Task found: " + taskId);
                            sendSms(taskId, phone, msg);
                            
                            // Start 3-second delay after successful task fetch
                            delayActive = true;
                            delayStartTime = System.currentTimeMillis();
                            Log.d("SMSindia", "3-second delay started");
                        } else {
                            Log.d("SMSindia", "No task available");
                        }
                    } catch (Exception e) {
                        Log.e("SMSindia", "Parse Error: " + e.getMessage());
                        retryCount = Math.min(retryCount + 1, MAX_RETRIES);
                    }
                } else {
                    Log.e("SMSindia", "Fetch failed - Status: " + response.code());
                    retryCount = Math.min(retryCount + 1, MAX_RETRIES);
                }
            }
        });
    }

    private void sendSms(String taskId, String phone, String msg) {
        try {
            // Update task status to processing
            updateTaskStatus(taskId, "processing");
            
            int subId = SimUtil.getSubscriptionId(this, selectedSimSlot);
            SmsManager smsManager = (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) ?
                getSystemService(SmsManager.class).createForSubscriptionId(subId) :
                SmsManager.getSmsManagerForSubscriptionId(subId);

            // PendingIntents for tracking
            Intent sentIntent = new Intent(this, SmsSentReceiver.class);
            sentIntent.putExtra("task_id", taskId);
            sentIntent.putExtra("phone", phone);
            sentIntent.putExtra("message", msg);
            PendingIntent sentPI = PendingIntent.getBroadcast(this, 0, sentIntent, 
                PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT);

            Intent deliveredIntent = new Intent(this, SmsDeliveredReceiver.class);
            deliveredIntent.putExtra("task_id", taskId);
            PendingIntent deliverPI = PendingIntent.getBroadcast(this, 0, deliveredIntent, 
                PendingIntent.FLAG_IMMUTABLE);

            // Support for long SMS (concatenation)
            ArrayList<String> parts = smsManager.divideMessage(msg);
            if (parts.size() > 1) {
                ArrayList<PendingIntent> sentIntents = new ArrayList<>();
                ArrayList<PendingIntent> deliveryIntents = new ArrayList<>();
                for (int i = 0; i < parts.size(); i++) {
                    sentIntents.add(sentPI);
                    deliveryIntents.add(deliverPI);
                }
                smsManager.sendMultipartTextMessage(phone, null, parts, sentIntents, deliveryIntents);
                Log.d("SMSindia", "Sent multipart SMS: " + taskId);
            } else {
                smsManager.sendTextMessage(phone, null, msg, sentPI, deliverPI);
                Log.d("SMSindia", "Sent SMS: " + taskId);
            }

        } catch (Exception e) {
            Log.e("SMSindia", "SMS Send Failed: " + e.getMessage());
            updateTaskStatus(taskId, "failed");
        }
    }

    public static void updateTaskStatus(String taskId, String status) {
        RequestBody body = RequestBody.create(
            "{\"status\": \"" + status + "\"}",
            MediaType.parse("application/json; charset=utf-8")
        );

        Request request = new Request.Builder()
                .url(SUPABASE_URL + "/rest/v1/sms_tasks?id=eq." + taskId)
                .addHeader("apikey", SUPABASE_KEY)
                .addHeader("Authorization", "Bearer " + SUPABASE_KEY)
                .addHeader("Prefer", "return=minimal")
                .patch(body)
                .build();

        client.newCall(request).enqueue(new Callback() {
            @Override
            public void onFailure(Call call, IOException e) {
                Log.e("SMSindia", "Failed to update task status: " + e.getMessage());
            }
            @Override
            public void onResponse(Call call, Response response) {
                Log.d("SMSindia", "Task " + taskId + " marked as " + status);
            }
        });
    }

    private void stopMining() {
        isRunning = false;
        delayActive = false;
        handler.removeCallbacksAndMessages(null);
        if (wakeLock != null && wakeLock.isHeld()) wakeLock.release();
        stopForeground(true);
        stopSelf();
        
        Log.d("SMSindia", "Mining service stopped");
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                "MiningChannel",
                "Mining Service",
                NotificationManager.IMPORTANCE_LOW
            );
            channel.setDescription("Background SMS mining with 3-second delay");
            getSystemService(NotificationManager.class).createNotificationChannel(channel);
        }
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }
}
