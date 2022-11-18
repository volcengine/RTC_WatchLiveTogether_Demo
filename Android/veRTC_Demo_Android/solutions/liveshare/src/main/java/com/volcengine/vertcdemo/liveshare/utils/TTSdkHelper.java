package com.volcengine.vertcdemo.liveshare.utils;

import android.content.Context;
import android.util.Log;

import androidx.annotation.NonNull;

import com.pandora.common.env.Env;
import com.pandora.common.utils.TimeUtil;
import com.pandora.common.utils.Times;
import com.pandora.ttlicense2.License;
import com.pandora.ttlicense2.LicenseManager;
import com.ss.video.rtc.demo.basic_module.utils.Utilities;

public class TTSdkHelper {
    private static final String TAG = "TTSdkHelper";
    private static final String TT_VIDEO_PLAYER_APP_ID = "260323";
    private static final String TT_VIDEO_PLAYER_APP_NAME = "vertcdemo";

    public static void initTTVodSdk() {
        initEnv();
        initLicense();
    }

    private static void initEnv() {
        // 初始化 TTSDK 环境
        Env.setupSDKEnv(new Env.SdkContextEnv() {
            @Override
            public Context getApplicationContext() {
                return Utilities.getApplicationContext();
            }

            @Override
            public Thread.UncaughtExceptionHandler getUncaughtExceptionHandler() {
                return (t, e) -> {
                    Log.d(TAG, "getUncaughtException:" + t + "," + e.getMessage());
                };
            }

            @Override
            public String getAppID() {
                return TT_VIDEO_PLAYER_APP_ID;
            }

            @Override
            public String getAppName() {
                return TT_VIDEO_PLAYER_APP_NAME;
            }

            @Override
            public String getAppRegion() {
                return "cn-north-1";
            }
        });
    }

    private static void initLicense() {
        //初始化 License 模块
        //初始化 license 2.0 的 LicenseManager
        LicenseManager.init(Utilities.getApplicationContext());
        // 开启 License 模块 logcat 输出，排查问题可以开启，release 包不建议开启
        LicenseManager.turnOnLogcat(true);
        //license 2.0 的授权文件支持从 assets 文件夹中直接读取，无需拷贝到存储
        String assetsLicenseUri = "assets:///tt_license.lic";
        //将 license uri 添加到 LicenseManager 中即可完成授权文件添加
        LicenseManager.getInstance().addLicense(assetsLicenseUri, new LicenseManager.Callback() {
            @Override
            public void onLicenseLoadSuccess(@NonNull String s, @NonNull String s1) {
                Log.d(TAG, "onLicenseLoadSuccess");
            }

            @Override
            public void onLicenseLoadError(@NonNull String s, @NonNull Exception e, boolean b) {
                Log.d(TAG, "onLicenseLoadError:" + s + "," + e.getMessage() + "," + b);
            }

            @Override
            public void onLicenseLoadRetry(@NonNull String s) {
                Log.d(TAG, "onLicenseLoadRetry:" + s);
            }

            @Override
            public void onLicenseUpdateSuccess(@NonNull String s, @NonNull String s1) {
                Log.d(TAG, "onLicenseUpdateSuccess:" + s + "," + s1);
            }

            @Override
            public void onLicenseUpdateError(@NonNull String s, @NonNull Exception e, boolean b) {
                Log.d(TAG, "onLicenseUpdateError:" + s + "," + e.getMessage() + "," + b);
            }

            @Override
            public void onLicenseUpdateRetry(@NonNull String s) {
                Log.d(TAG, "onLicenseUpdateRetry:" + s);
            }
        });
        //License 信息获取
        License license = LicenseManager.getInstance().getLicense("100439");
        if (license != null) {
            StringBuilder builder = new StringBuilder();
            builder.append("License id:" + license.getId()).append("\n")
                    .append("License package:" + license.getPackageName()).append("\n")
                    .append("License test:" + license.getType()).append("\n")
                    .append("License version:" + license.getVersion()).append("\n");

            if (license.getModules() != null) {
                String names;
                for (License.Module module : license.getModules()) {
                    names = "module name:" + module.getName() + ", start time:" +
                            TimeUtil.format(module.getStartTime(), Times.YYYY_MM_DD_KK_MM_SS)
                            + ", expire time:" + TimeUtil.format(module.getExpireTime(), Times.YYYY_MM_DD_KK_MM_SS) + "\n";
                    builder.append("License modules:" + names);
                }
            }
            Log.d(TAG, "License info:" + builder);
        }
    }
}
