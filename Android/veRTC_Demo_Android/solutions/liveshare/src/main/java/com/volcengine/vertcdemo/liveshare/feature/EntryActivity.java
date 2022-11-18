package com.volcengine.vertcdemo.liveshare.feature;

import static com.volcengine.vertcdemo.core.net.rts.RTSInfo.KEY_RTM;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;

import androidx.annotation.Keep;
import androidx.annotation.NonNull;

import com.ss.video.rtc.demo.basic_module.acivities.BaseActivity;
import com.ss.video.rtc.demo.basic_module.utils.SafeToast;
import com.ss.video.rtc.demo.basic_module.utils.Utilities;
import com.ss.video.rtc.demo.basic_module.utils.WindowUtils;
import com.vertcdemo.joinrtsparams.bean.JoinRTSRequest;
import com.vertcdemo.joinrtsparams.common.JoinRTSManager;
import com.volcengine.vertcdemo.common.IAction;
import com.volcengine.vertcdemo.core.SolutionDataManager;
import com.volcengine.vertcdemo.core.net.IRequestCallback;
import com.volcengine.vertcdemo.core.net.ServerResponse;
import com.volcengine.vertcdemo.core.net.rts.RTSBaseClient;
import com.volcengine.vertcdemo.core.net.rts.RTSInfo;
import com.volcengine.vertcdemo.liveshare.core.LiveShareDataManager;
import com.volcengine.vertcdemo.liveshare.core.LiveShareRTSClient;
import com.volcengine.vertcdemo.liveshare.utils.TTSdkHelper;

/**
 * 场景入口Activity
 */
public class EntryActivity extends BaseActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        TTSdkHelper.initTTVodSdk();
        RTSInfo rtsInfo = getIntent() == null ? null : getIntent().getParcelableExtra(RTSInfo.KEY_RTM);
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
        rtsClient.login(rtsInfo.rtmToken, (resultCode, message) -> {
            if (resultCode == RTSBaseClient.LoginCallBack.SUCCESS) {
                Intent intent = new Intent(EntryActivity.this, PreviewActivity.class);
                startActivity(intent);
            } else {
                SafeToast.show("Login RTM Fail Error:" + resultCode + ",message:" + message);
            }
        });
    }

    protected void setupStatusBar() {
        WindowUtils.setLayoutFullScreen(getWindow());
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
                intent.setClass(Utilities.getApplicationContext(), EntryActivity.class);
                intent.putExtra(KEY_RTM, data);
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
        JoinRTSRequest request = new JoinRTSRequest();
        request.scenesName = "twv";
        request.loginToken = SolutionDataManager.ins().getToken();
        JoinRTSManager.setAppInfoAndJoinRTM(request, callback);
    }
}