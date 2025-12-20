package com.smsindia.app.utils; // Change to your package name

import android.Manifest;
import android.content.Context;
import android.content.pm.PackageManager;
import android.telephony.SubscriptionInfo;
import android.telephony.SubscriptionManager;
import androidx.core.app.ActivityCompat;
import java.util.List;

public class SimUtil {
    public static int getSubscriptionId(Context context, int slotIndex) {
        if (ActivityCompat.checkSelfPermission(context, Manifest.permission.READ_PHONE_STATE) != PackageManager.PERMISSION_GRANTED) {
            return -1;
        }
        SubscriptionManager sm = (SubscriptionManager) context.getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE);
        List<SubscriptionInfo> infoList = sm.getActiveSubscriptionInfoList();
        
        if (infoList != null) {
            for (SubscriptionInfo info : infoList) {
                if (info.getSimSlotIndex() == slotIndex) {
                    return info.getSubscriptionId();
                }
            }
        }
        return -1; // No SIM in this slot
    }
}
