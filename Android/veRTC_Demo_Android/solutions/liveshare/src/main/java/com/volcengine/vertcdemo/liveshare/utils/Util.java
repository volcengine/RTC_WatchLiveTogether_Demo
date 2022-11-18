package com.volcengine.vertcdemo.liveshare.utils;

import android.app.Activity;
import android.content.Context;
import android.content.ContextWrapper;
import android.content.res.Resources;
import android.util.TypedValue;

import androidx.annotation.StringRes;

import com.ss.video.rtc.demo.basic_module.utils.Utilities;

public class Util {
    public static String getString(@StringRes int stringResId) {
        return Utilities.getApplicationContext().getString(stringResId);
    }

    public static int dp2px(final float dpValue) {
        final float scale = Resources.getSystem().getDisplayMetrics().density;
        return (int) (dpValue * scale + 0.5f);
    }

    public static float sp2px(Context context, float sp) {
        if (context != null) {
            return TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_SP, sp,
                    context.getResources().getDisplayMetrics());
        }
        return 0;
    }

    public static Activity scanForActivity(Context context) {
        if (context == null) return null;
        if (context instanceof Activity) {
            return (Activity) context;
        } else if (context instanceof ContextWrapper) {
            return scanForActivity(((ContextWrapper) context).getBaseContext());
        }
        return null;
    }
}
