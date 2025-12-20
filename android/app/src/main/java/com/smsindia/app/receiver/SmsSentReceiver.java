package com.smsindia.app.receiver;

import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.telephony.SmsManager;
import android.util.Log;
import com.smsindia.app.service.MiningService;

public class SmsSentReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        String taskId = intent.getStringExtra("task_id");
        if (taskId == null) return;

        String status = "failed";
        switch (getResultCode()) {
            case Activity.RESULT_OK:
                status = "sent";
                break;
            case SmsManager.RESULT_ERROR_GENERIC_FAILURE:
            case SmsManager.RESULT_ERROR_NO_SERVICE:
                status = "failed";
                break;
        }

        Log.d("WinMate", "SMS Result for " + taskId + ": " + status);
        
        // Notify Service to update DB
        MiningService.updateTaskStatus(taskId, status);
    }
}
