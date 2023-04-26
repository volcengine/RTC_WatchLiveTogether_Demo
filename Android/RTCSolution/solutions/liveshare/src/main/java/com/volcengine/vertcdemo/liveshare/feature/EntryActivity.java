// Copyright (c) 2023 Beijing Volcano Engine Technology Ltd.
// SPDX-License-Identifier: MIT

package com.volcengine.vertcdemo.liveshare.feature;

import static com.volcengine.vertcdemo.core.net.rts.RTSInfo.KEY_RTS;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;

import androidx.annotation.Keep;
import androidx.annotation.NonNull;

import com.vertcdemo.joinrtsparams.bean.JoinRTSRequest;
import com.vertcdemo.joinrtsparams.common.JoinRTSManager;
import com.volcengine.vertcdemo.common.IAction;
import com.volcengine.vertcdemo.common.SolutionBaseActivity;
import com.volcengine.vertcdemo.common.SolutionToast;
import com.volcengine.vertcdemo.core.SolutionDataManager;
import com.volcengine.vertcdemo.core.net.IRequestCallback;
import com.volcengine.vertcdemo.core.net.ServerResponse;
import com.volcengine.vertcdemo.core.net.rts.RTSBaseClient;
import com.volcengine.vertcdemo.core.net.rts.RTSInfo;
import com.volcengine.vertcdemo.liveshare.core.LiveShareDataManager;
import com.volcengine.vertcdemo.liveshare.core.LiveShareRTSClient;
import com.volcengine.vertcdemo.liveshare.utils.TTSdkHelper;
import com.volcengine.vertcdemo.utils.AppUtil;

/**
 * 场景入口Activity
 */
public class EntryActivity extends SolutionBaseActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        TTSdkHelper.initTTVodSdk();
        RTSInfo rtsInfo = getIntent() == null ? null : getIntent().getParcelableExtra(RTSInfo.KEY_RTS);
        if (rtsInfo != null && rtsInfo.isValid()) {
            startPreviewActivity(rtsInfo);
        }
        finish();
    }

    /**
     * 连接RTS成功后开启预览页
     *
     * @param rtsInfo 连接RTS必要参数
     */
    public void startPreviewActivity(@NonNull RTSInfo rtsInfo) {
        LiveShareDataManager liveShareDataManger = LiveShareDataManager.getInstance();
        liveShareDataManger.initRTC(rtsInfo);
        LiveShareRTSClient rtsClient = liveShareDataManger.getRTSClient();
        rtsClient.login(rtsInfo.rtsToken, (resultCode, message) -> {
            if (resultCode == RTSBaseClient.LoginCallBack.SUCCESS) {
                Intent intent = new Intent(EntryActivity.this, PreviewActivity.class);
                startActivity(intent);
            } else {
                SolutionToast.show("Login RTM Fail Error:" + resultCode + ",message:" + message);
            }
        });
    }

    @Keep
    @SuppressWarnings("unused")
    public static void prepareSolutionParams(Activity activity, IAction<Object> doneAction) {
        IRequestCallback<ServerResponse<RTSInfo>> callback = new IRequestCallback<ServerResponse<RTSInfo>>() {
            @Override
            public void onSuccess(ServerResponse<RTSInfo> response) {
                RTSInfo data = response == null ? null : response.getData();
                if (data == null || !data.isValid()) {
                    onError(-1, "");
                    return;
                }
                Intent intent = new Intent(Intent.ACTION_MAIN);
                intent.setClass(AppUtil.getApplicationContext(), EntryActivity.class);
                intent.putExtra(KEY_RTS, data);
                activity.startActivity(intent);
                if (doneAction != null) {
                    doneAction.act(null);
                }
            }

            @Override
            public void onError(int errorCode, String message) {
                if (doneAction != null) {
                    doneAction.act(null);
                }
            }
        };
        JoinRTSRequest request = new JoinRTSRequest("twv", SolutionDataManager.ins().getToken());
        JoinRTSManager.setAppInfoAndJoinRTM(request, callback);
    }
}