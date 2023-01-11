package com.volcengine.vertcdemo.liveshare.feature;

import android.Manifest;
import android.content.Intent;
import android.os.Bundle;
import android.text.Editable;
import android.text.InputFilter;
import android.text.TextUtils;
import android.util.Log;
import android.view.TextureView;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.Toast;

import androidx.annotation.Nullable;

import com.ss.bytertc.engine.RTCVideo;
import com.ss.bytertc.engine.VideoCanvas;
import com.ss.bytertc.engine.data.StreamIndex;
import com.ss.video.rtc.demo.basic_module.acivities.BaseActivity;
import com.ss.video.rtc.demo.basic_module.adapter.TextWatcherAdapter;
import com.ss.video.rtc.demo.basic_module.utils.IMEUtils;
import com.ss.video.rtc.demo.basic_module.utils.SafeToast;
import com.ss.video.rtc.demo.basic_module.utils.WindowUtils;
import com.volcengine.vertcdemo.common.LengthFilterWithCallback;
import com.volcengine.vertcdemo.core.SolutionDataManager;
import com.volcengine.vertcdemo.core.eventbus.SolutionDemoEventManager;
import com.volcengine.vertcdemo.core.net.IRequestCallback;
import com.volcengine.vertcdemo.core.net.rts.RTSBaseClient;
import com.volcengine.vertcdemo.liveshare.R;
import com.volcengine.vertcdemo.liveshare.bean.RTCErrorEvent;
import com.volcengine.vertcdemo.liveshare.bean.Room;
import com.volcengine.vertcdemo.liveshare.bean.response.ClearUserResponse;
import com.volcengine.vertcdemo.liveshare.bean.response.JoinRoomResponse;
import com.volcengine.vertcdemo.liveshare.core.CameraMicManger;
import com.volcengine.vertcdemo.liveshare.core.LiveShareDataManager;
import com.volcengine.vertcdemo.liveshare.core.LiveShareRTCManger;
import com.volcengine.vertcdemo.liveshare.core.LiveShareRTSClient;
import com.volcengine.vertcdemo.liveshare.databinding.ActivityLiveSharePreviewBinding;
import com.volcengine.vertcdemo.utils.DebounceClickListener;
import com.volcengine.vertcdemo.utils.Utils;

import org.greenrobot.eventbus.Subscribe;
import org.greenrobot.eventbus.ThreadMode;

import java.util.Observer;
import java.util.regex.Pattern;

/**
 * 一起看直播Demo预览&登陆页
 */
public class PreviewActivity extends BaseActivity {
    private static final String TAG = "PreviewActivity";
    public static final String ROOM_INPUT_REGEX = "^[a-zA-Z0-9@_-]+$";
    private static final int REQUEST_CODE_START_LIVE = 101;
    private ActivityLiveSharePreviewBinding mViewBinding;

    private boolean mRoomIdOverflow = false;
    private LiveShareDataManager mDataManger;
    private LiveShareRTSClient mRTSClient;
    private CameraMicManger mCameraMicManger;
    private RTCVideo mRTCEngine;
    private String mUserId;
    private Runnable mPendingJoinRoom;

    private final TextWatcherAdapter mTextWatcher = new TextWatcherAdapter() {
        @Override
        public void afterTextChanged(Editable s) {
            setupInputStatus();
        }
    };

    /**
     * 摄像头、麦克风监听用户动作设置UI
     */
    private final Observer mCameraMicOperationListener = (Observer, data) -> {
        mViewBinding.cameraOnOffIv.setImageResource(mCameraMicManger.isCameraOn()
                ? R.drawable.ic_camera_on
                : R.drawable.ic_camera_off_red);
        mViewBinding.cameraStatusIv.setVisibility(mCameraMicManger.isCameraOn()
                ? View.GONE
                : View.VISIBLE);
        mViewBinding.micOnOffIv.setImageResource(mCameraMicManger.isMicOn()
                ? R.drawable.ic_mic_on
                : R.drawable.ic_mic_off_red);
    };

    @Override
    protected void setupStatusBar() {
        WindowUtils.setLayoutFullScreen(getWindow());
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        mViewBinding = ActivityLiveSharePreviewBinding.inflate(getLayoutInflater());
        setContentView(mViewBinding.getRoot());
        initData();
        initUi();
        initRtc();
        SolutionDemoEventManager.register(this);
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (mDataManger.getCameraMicManager().isCameraOn()) {
            mDataManger.getCameraMicManager().openCamera();
        }
        if (mDataManger.getCameraMicManager().isMicOn()) {
            mDataManger.getCameraMicManager().openMic();
        }
        updateVideoView();
    }

    private void initData() {
        mUserId = SolutionDataManager.ins().getUserId();
        mDataManger = LiveShareDataManager.getInstance();
        mRTSClient = mDataManger.getRTSClient();
        mCameraMicManger = mDataManger.getCameraMicManager();
        mCameraMicManger.addObserver(mCameraMicOperationListener);
        mRTCEngine = mDataManger.getRTCEngine();
    }

    private void initRtc() {
        setLocalRenderView();
    }

    protected void initUi() {
        mViewBinding.rootFl.setOnClickListener(DebounceClickListener.create(v -> IMEUtils.closeIME(mViewBinding.rootFl)));
        mViewBinding.closeBtn.setOnClickListener(DebounceClickListener.create(v -> finish()));
        mViewBinding.roomIdEt.addTextChangedListener(mTextWatcher);
        InputFilter meetingIDFilter = new LengthFilterWithCallback(18, (overflow) -> mRoomIdOverflow = overflow);
        InputFilter[] meetingIDFilters = new InputFilter[]{meetingIDFilter};
        mViewBinding.roomIdEt.setFilters(meetingIDFilters);
        mViewBinding.micOnOffIv.setOnClickListener(DebounceClickListener.create(v -> mCameraMicManger.toggleMic()));
        mViewBinding.cameraOnOffIv.setOnClickListener(DebounceClickListener.create(v -> {
            mCameraMicManger.toggleCamera();
            updateVideoView();
        }));
        mViewBinding.effectSetting.setOnClickListener(DebounceClickListener.create(v ->
                LiveShareRTCManger.ins().openEffectDialog(PreviewActivity.this)));
        mViewBinding.joinRoomBtn.setOnClickListener(DebounceClickListener.create(v -> {
            if (mRTSClient == null) {
                return;
            }
            final String input = mViewBinding.roomIdEt.getText().toString().trim();
            if (TextUtils.isEmpty(input)) {
                SafeToast.show(this, getString(R.string.room_id_empty_hint), Toast.LENGTH_SHORT);
                return;
            }

            final String roomId = "twv_" + input;
            boolean requested = mRTSClient.clearUser(mUserId, () -> {
                joinRoom(roomId);
            });

            if (requested) { // 请求已经发出，禁用按钮，防止重复发起请求
                disableJoinRoomButton();
            } else {
                enableJoinRoomButton();
            }
        }));
        requestPermissions(Manifest.permission.RECORD_AUDIO, Manifest.permission.CAMERA);
    }

    private void joinRoom(String roomId) {
        String userName = SolutionDataManager.ins().getUserName();
        //业务入房，如果没有房间创建一个房间
        boolean requested = mRTSClient.joinRoom(roomId,
                mUserId, userName,
                mCameraMicManger.isMicOn(), mCameraMicManger.isCameraOn(),
                new IRequestCallback<JoinRoomResponse>() {
                    @Override
                    public void onSuccess(JoinRoomResponse data) {
                        if (isFinishing()) {
                            return;
                        }
                        Room room = data == null ? null : data.room;
                        if (room == null) {
                            onError(RTSBaseClient.ERROR_CODE_DEFAULT, getString(R.string.join_room_error_rtc_room_empty));
                        } else if (TextUtils.isEmpty(room.rtcToken)) {
                            onError(RTSBaseClient.ERROR_CODE_DEFAULT, getString(R.string.join_room_error_rtc_token_empty));
                        } else {
                            joinRTCRoom(room, data);
                        }
                    }

                    @Override
                    public void onError(int errorCode, String message) {
                        Log.i(TAG, "joinRoom biz failed message: " + message + ",errorCode:" + errorCode);
                        runOnUiThread(() -> enableJoinRoomButton());
                        if (RTSBaseClient.ERROR_CODE_USERNAME_SAME == errorCode) {
                            SafeToast.show(getString(R.string.join_room_error_has_in));
                        } else if (RTSBaseClient.ERROR_CODE_ROOM_FULL == errorCode) {
                            SafeToast.show(getString(R.string.join_room_error_room_full));
                        } else {
                            SafeToast.show(message);
                        }
                    }
                });

        if (requested) { // 请求已经发出，禁用按钮，防止重复发起请求
            disableJoinRoomButton();
        } else {
            enableJoinRoomButton();
        }
    }

    void disableJoinRoomButton() {
        mViewBinding.joinRoomBtn.setEnabled(false);
    }

    void enableJoinRoomButton() {
        mViewBinding.joinRoomBtn.setEnabled(true);
    }

    void joinRTCRoom(Room room, JoinRoomResponse data) {
        mPendingJoinRoom = () -> LiveShareActivity.startForResult(PreviewActivity.this, REQUEST_CODE_START_LIVE, data);
        LiveShareRTCManger.ins().joinRoom(room.rtcToken, room.roomId, mUserId);
    }

    @Subscribe(threadMode = ThreadMode.MAIN)
    public void onRTCErrorEvent(RTCErrorEvent event) {
        if (mPendingJoinRoom != null) {
            mPendingJoinRoom.run();
        }
        mPendingJoinRoom = null;
        mViewBinding.joinRoomBtn.postDelayed(this::enableJoinRoomButton, 100);
    }

    /**
     * 设置视频渲染
     */
    private void setLocalRenderView() {
        VideoCanvas videoCanvas = new VideoCanvas();
        videoCanvas.isScreen = false;
        videoCanvas.renderMode = VideoCanvas.RENDER_MODE_HIDDEN;
        videoCanvas.uid = mUserId;
        TextureView renderView = mDataManger.getUserRenderView(mUserId);
        videoCanvas.renderView = renderView;
        FrameLayout.LayoutParams params = new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT);
        Utils.attachViewToViewGroup(mViewBinding.previewContainerFl, renderView, params);
        mViewBinding.previewContainerFl.setVisibility(View.VISIBLE);
        mRTCEngine.setLocalVideoCanvas(StreamIndex.STREAM_INDEX_MAIN, videoCanvas);
    }

    /**
     * 根据用户视频采集状态更新视图
     */
    private void updateVideoView() {
        if (mDataManger.getCameraMicManager().isCameraOn()) {
            setLocalRenderView();
        } else {
            mViewBinding.previewContainerFl.removeAllViews();
        }
    }

    @Override
    protected void onPermissionResult(String permission, boolean granted) {
        if (mCameraMicManger == null && !granted) {
            return;
        }
        if (TextUtils.equals(Manifest.permission.RECORD_AUDIO, permission)) {
            mCameraMicManger.openMic();
        }
        if (TextUtils.equals(Manifest.permission.CAMERA, permission)) {
            mCameraMicManger.openCamera();
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        //从连麦页返回
        if (REQUEST_CODE_START_LIVE == requestCode) {
            enableJoinRoomButton();
            //如果是因为重复登录被踢出，退回场景选择页
            if (resultCode == LiveShareActivity.RESULT_CODE_DUPLICATE_LOGIN) {
                finish();
                return;
            }
            mCameraMicManger.switchCamera(true);
            setLocalRenderView();
        } else {
            super.onActivityResult(requestCode, resultCode, data);
        }
    }

    private final Runnable mRoomIdWaringDismiss = () -> mViewBinding.roomIdWaringTv.setVisibility(View.GONE);

    private void setupInputStatus() {
        int roomIDLength = mViewBinding.roomIdEt.getText().length();
        boolean canJoin = false;
        if (Pattern.matches(ROOM_INPUT_REGEX, mViewBinding.roomIdEt.getText().toString())) {
            if (mRoomIdOverflow) {
                mViewBinding.roomIdWaringTv.setVisibility(View.VISIBLE);
                mViewBinding.roomIdWaringTv.setText(R.string.input_room_id_length_waring);
                mViewBinding.roomIdWaringTv.removeCallbacks(mRoomIdWaringDismiss);
                mViewBinding.roomIdWaringTv.postDelayed(mRoomIdWaringDismiss, 2500);
            } else {
                mViewBinding.roomIdWaringTv.setVisibility(View.INVISIBLE);
                canJoin = true;
            }
        } else {
            if (roomIDLength > 0) {
                mViewBinding.roomIdWaringTv.setVisibility(View.VISIBLE);
                mViewBinding.roomIdWaringTv.setText(R.string.input_room_id_format_waring);
            } else {
                mViewBinding.roomIdWaringTv.setVisibility(View.INVISIBLE);
            }
        }

        boolean joinBtnEnable = roomIDLength > 0 && roomIDLength <= 18 && canJoin;
        mViewBinding.joinRoomBtn.setEnabled(joinBtnEnable);
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        mCameraMicManger.deleteObserver(mCameraMicOperationListener);
        mDataManger.clearUp();
        SolutionDemoEventManager.unregister(this);
    }
}
