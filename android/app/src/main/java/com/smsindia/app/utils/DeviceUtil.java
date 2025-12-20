package com.smsindia.app.utils; // Change to your package name

import android.content.Context;
import android.provider.Settings;

public class DeviceUtil {
    public static String getDeviceId(Context context) {
        return Settings.Secure.getString(context.getContentResolver(), Settings.Secure.ANDROID_ID);
    }
}
