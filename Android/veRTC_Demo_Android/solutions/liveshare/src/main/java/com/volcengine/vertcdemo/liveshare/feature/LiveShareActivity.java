package com.volcengine.vertcdemo.liveshare.feature;

import static com.volcengine.vertcdemo.liveshare.bean.User.CAMERA_STATUS_ON;

import android.app.Activity;
import android.content.Intent;
import android.graphics.drawable.Drawable;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.text.TextUtils;
import android.util.Log;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.TextureView;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;

import androidx.core.content.ContextCompat;

import com.ss.bytertc.engine.RTCVideo;
import com.ss.bytertc.engine.VideoCanvas;
import com.ss.bytertc.engine.data.StreamIndex;
import com.ss.video.rtc.demo.basic_module.acivities.BaseActivity;
import com.ss.video.rtc.demo.basic_module.ui.CommonDialog;
import com.ss.video.rtc.demo.basic_module.utils.IMEUtils;
import com.ss.video.rtc.demo.basic_module.utils.SafeToast;
import com.ss.video.rtc.demo.basic_module.utils.Utilities;
import com.volcengine.vertcdemo.common.SolutionToast;
import com.volcengine.vertcdemo.core.SolutionDataManager;
import com.volcengine.vertcdemo.core.eventbus.SolutionDemoEventManager;
import com.volcengine.vertcdemo.core.net.IRequestCallback;
import com.volcengine.vertcdemo.liveshare.R;
import com.volcengine.vertcdemo.liveshare.bean.AudioProperty;
import com.volcengine.vertcdemo.liveshare.bean.Room;
import com.volcengine.vertcdemo.liveshare.bean.TargetScene;
import com.volcengine.vertcdemo.liveshare.bean.User;
import com.volcengine.vertcdemo.liveshare.bean.event.KickOutEvent;
import com.volcengine.vertcdemo.liveshare.bean.event.RTCLocalUserSpeakStatusEvent;
import com.volcengine.vertcdemo.liveshare.bean.event.RTCRemoteUserSpeakStatusEvent;
import com.volcengine.vertcdemo.liveshare.bean.event.RTCUserJoinEvent;
import com.volcengine.vertcdemo.liveshare.bean.inform.CloseRoomInform;
import com.volcengine.vertcdemo.liveshare.bean.inform.JoinRoomInform;
import com.volcengine.vertcdemo.liveshare.bean.inform.LeaveRoomInform;
import com.volcengine.vertcdemo.liveshare.bean.inform.TurnOnOffMicCameraInform;
import com.volcengine.vertcdemo.liveshare.bean.inform.UpdateLiveUrlInform;
import com.volcengine.vertcdemo.liveshare.bean.inform.UpdateRoomSceneInform;
import com.volcengine.vertcdemo.liveshare.bean.response.GetUserListResponse;
import com.volcengine.vertcdemo.liveshare.bean.response.JoinRoomResponse;
import com.volcengine.vertcdemo.liveshare.bean.response.LeaveShareResponse;
import com.volcengine.vertcdemo.liveshare.core.CameraMicManger;
import com.volcengine.vertcdemo.liveshare.core.LiveShareDataManager;
import com.volcengine.vertcdemo.liveshare.core.LiveShareRTCManger;
import com.volcengine.vertcdemo.liveshare.core.LiveShareRTSClient;
import com.volcengine.vertcdemo.liveshare.databinding.ActivityLiveShareBinding;
import com.volcengine.vertcdemo.liveshare.databinding.LayoutSmallVideoBinding;
import com.volcengine.vertcdemo.liveshare.feature.LiveUrlDialog.TriggerLiveShareListener;
import com.volcengine.vertcdemo.liveshare.feature.player.playerevent.PlayStateEnterFullScreen;
import com.volcengine.vertcdemo.liveshare.feature.player.playerevent.PlayStateExitFullScreen;
import com.volcengine.vertcdemo.liveshare.utils.Util;
import com.volcengine.vertcdemo.utils.DebounceClickListener;
import com.volcengine.vertcdemo.utils.Utils;

import org.greenrobot.eventbus.Subscribe;
import org.greenrobot.eventbus.ThreadMode;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Observer;

public class LiveShareActivity extends BaseActivity {
    public static final int RESULT_CODE_DUPLICATE_LOGIN = 10000;
    private static final String TAG = "LiveShareActivity";
    private static final String EXTRA_JOIN_ROOM_RESPONSE = "join_response";
    private LiveFragment mShareFragment;

    private ActivityLiveShareBinding mViewBinding;
    private VoiceSettingDialog mVoiceSettingDialog;
    private CommonDialog mCloseRoomDialog;
    private LiveUrlDialog mLiveUrlDialog;

    private LiveShareDataManager mDataManger;
    private RTCVideo mRTCVideo;
    private CameraMicManger mCameraMicManger;
    private LiveShareRTSClient mRTSClient;
    private TextMessageComponent mTextMessageComponent;

    private Room mRoom;
    private boolean mIsLandscape;
    private String mSelfUid;
    private String mRoomId;
    private final List<User> mRemoteUsers = new ArrayList<>(1);
    private final HashMap<String, View> mSmallRenderViews = new HashMap<>(1);

    private boolean mVisible;
    private TargetScene mWaitScene;

    private final Handler mHandler = new Handler(Looper.getMainLooper());
    private HashSet<AudioProperty> mRemoteUserProperties;
    private HashSet<AudioProperty> mLocalUserProperties;
    private final Runnable mUserSpeakStatusTask = () -> {
        if (mRemoteUserProperties != null && mRemoteUserProperties.size() > 0) {
            for (AudioProperty property : mRemoteUserProperties) {
                if (property == null || TextUtils.isEmpty(property.uid)) {
                    continue;
                }
                updateSpeakStatus(property.uid, property.speaking);
            }
        }
        if (mLocalUserProperties != null && mLocalUserProperties.size() > 0) {
            for (AudioProperty property : mLocalUserProperties) {
                if (property == null || property.isScreenStream) {
                    continue;
                }
                updateSpeakStatus(mSelfUid, property.speaking);
            }
        }
    };

    private void updateSpeakStatus(String uid, boolean speaking) {
        View smallVideoView = mSmallRenderViews.get(uid);
        if (smallVideoView == null) return;
        smallVideoView.setBackground(
                ContextCompat.getDrawable(Utilities.getApplicationContext(),
                        speaking ? R.drawable.bg_small_video_speaking_border
                                : R.drawable.bg_small_video_no_speak_border));
    }

    public static void startForResult(Activity context, int requestCode, JoinRoomResponse joinRoomResponse) {
        Intent intent = new Intent(context, LiveShareActivity.class);
        intent.putExtra(EXTRA_JOIN_ROOM_RESPONSE, joinRoomResponse);
        context.startActivityForResult(intent, requestCode);
    }


    private String mLastMicStatus;
    private String mLastCameraStatus;

    /**
     * 监听用户动作更新摄像头、麦克风UI
     */
    private final Observer mCameraMicOperationListener = (Observer, data) -> {
        final String micStatus = mCameraMicManger.isMicOn() ? "1" : "0";
        final String cameraStatus = mCameraMicManger.isCameraOn() ? "1" : "0";

        boolean needNotifyRemote = !micStatus.equals(mLastMicStatus) || !cameraStatus.equals(mLastCameraStatus);
        mLastMicStatus = micStatus;
        mLastCameraStatus = cameraStatus;
        if (needNotifyRemote) {
            mRTSClient.turnOnOrOffMicCamera(
                    mRoomId,
                    mSelfUid,
                    micStatus,
                    cameraStatus);
        }
        updateCameraMicStatusUi();
    };

    private final TriggerLiveShareListener mTriggerLiveShareListener = (liveUrl, isLandscape) -> {
        boolean needUpdateServer = mRoom.scene != Room.SCENE_SHARE;
        int screenOrientation = isLandscape ? Room.SCREEN_ORIENTATION_LANDSCAPE : Room.SCREEN_ORIENTATION_PORTRAIT;
        if (!needUpdateServer) {
            mRoom.videoUrl = liveUrl;
            mRoom.screenOrientation = screenOrientation;
            mShareFragment.updateVideoUrl(mRoom.videoUrl, screenOrientation);
            return;
        }
        TargetScene scene = new TargetScene(Room.SCENE_SHARE, liveUrl, screenOrientation);
        updateRoomSceneAndUi(scene, true);
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        mViewBinding = ActivityLiveShareBinding.inflate(getLayoutInflater());
        setContentView(mViewBinding.getRoot());
        SolutionDemoEventManager.register(this);
        initData();
        initView();
    }

    private void initData() {
        Intent intent = getIntent();
        JoinRoomResponse joinRoomResponse = intent.getParcelableExtra(EXTRA_JOIN_ROOM_RESPONSE);
        mRoom = joinRoomResponse == null ? null : joinRoomResponse.room;
        mRoomId = mRoom == null ? null : mRoom.roomId;
        mSelfUid = SolutionDataManager.ins().getUserId();
        mDataManger = LiveShareDataManager.getInstance();
        mDataManger.resetAudioConfig();
        mRTCVideo = mDataManger.getRTCEngine();
        mCameraMicManger = mDataManger.getCameraMicManager();
        mCameraMicManger.addObserver(mCameraMicOperationListener);
        mRTSClient = mDataManger.getRTSClient();
        mTextMessageComponent = new TextMessageComponent(mViewBinding, mRoomId, mSelfUid, mRTSClient, LiveShareActivity.this);
        List<User> remoteUsers = (joinRoomResponse == null || joinRoomResponse.users == null) ? null : joinRoomResponse.users;
        if (remoteUsers != null && remoteUsers.size() > 1) {
            mRemoteUsers.addAll(joinRoomResponse.users);
            removeRemoteUser(mSelfUid);
        }
        getUserListFromServer(mRoomId, mSelfUid);
    }

    /**
     * 主动从服务端获取用户列表
     * @param roomId 房间id
     * @param userId 用户id
     */
    private void getUserListFromServer(String roomId, String userId) {
        IRequestCallback<GetUserListResponse> callback = new IRequestCallback<GetUserListResponse>() {
            @Override
            public void onSuccess(GetUserListResponse data) {
                if (data != null && data.userList != null) {
                    mRemoteUsers.addAll(data.userList);
                    removeRemoteUser(mSelfUid);
                    showRemoteUsers();
                }
            }

            @Override
            public void onError(int errorCode, String message) {

            }
        };
        LiveShareRTCManger.ins().getRTSClient().getUserList(roomId, userId, callback);
    }

    private void initView() {
        mViewBinding.cameraSwitchIv.setOnClickListener(DebounceClickListener.create(v -> {
            mCameraMicManger.switchCamera();
            IMEUtils.closeIME(v);
        }));
        mViewBinding.roomIdTv.setText(getString(R.string.room_id, mRoomId).replace("twv_", ""));
        mViewBinding.roomIdTv.setOnClickListener(DebounceClickListener.create(IMEUtils::closeIME));
        mViewBinding.hangupIv.setOnClickListener(DebounceClickListener.create(v -> {
            boolean isHost = !TextUtils.isEmpty(mSelfUid) && TextUtils.equals(mSelfUid, mRoom.hostUserId);
            //当前在一起看场景
            if (mRoom.scene == Room.SCENE_SHARE) {
                if (isHost) {//主播退出一起看
                    TargetScene scene = new TargetScene(Room.SCENE_CHAT);
                    updateRoomSceneAndUi(scene, isHost);
                } else {//非主播直接退出
                    finish();
                }
                return;
            }
            //当前在直播场景
            if (isHost) {//主播关房二次确认
                showCloseRoomDialog();
            } else {//非主播直接退出
                finish();
            }
            IMEUtils.closeIME(v);
        }));
        mViewBinding.micOnOffIv.setOnClickListener(DebounceClickListener.create(v -> mCameraMicManger.toggleMic()));
        mViewBinding.cameraOnOffIv.setOnClickListener(DebounceClickListener.create(v -> mCameraMicManger.toggleCamera()));
        updateCameraMicStatusUi();
        mViewBinding.effectSetting.setOnClickListener(DebounceClickListener.create(v
                -> LiveShareRTCManger.ins().openEffectDialog(LiveShareActivity.this)));
        mViewBinding.liveShareIv.setOnClickListener(DebounceClickListener.create(v -> {
            if (mLiveUrlDialog != null) {
                mLiveUrlDialog.dismiss();
                mLiveUrlDialog = null;
            }
            mLiveUrlDialog = new LiveUrlDialog(this, mTriggerLiveShareListener, getLifecycle());
            mLiveUrlDialog.show();
        }));
        mViewBinding.settingIv.setOnClickListener(DebounceClickListener.create(v -> showVoiceSettingDialog()));
        mViewBinding.shareLiveContainer.setOnClickListener(DebounceClickListener.create(IMEUtils::closeIME));

        //bind data to view
        setLargeRenderView(mSelfUid);
        showRemoteUsers();
        TargetScene scene = new TargetScene(mRoom.scene, mRoom.videoUrl, mRoom.screenOrientation);
        updateRoomSceneAndUi(scene, false);
    }

    public void showCloseRoomDialog() {
        if (mCloseRoomDialog != null && mCloseRoomDialog.isShowing()) {
            mCloseRoomDialog.dismiss();
        }
        mCloseRoomDialog = new CommonDialog(this);
        mCloseRoomDialog.setMessage(Util.getString(R.string.close_room_confirm_hint));
        mCloseRoomDialog.setPositiveListener((v) -> {
            finish();
            mCloseRoomDialog.dismiss();
        });
        mCloseRoomDialog.setNegativeListener((v) -> mCloseRoomDialog.dismiss());
        mCloseRoomDialog.show();
    }

    /**
     * 设置摄像头、麦克风UI
     */
    private void updateCameraMicStatusUi() {
        if (mCameraMicManger == null) return;
        mViewBinding.cameraOnOffIv.setImageResource(mCameraMicManger.isCameraOn()
                ? R.drawable.ic_camera_on
                : R.drawable.ic_camera_off_red);

        mViewBinding.micOnOffIv.setImageResource(mCameraMicManger.isMicOn()
                ? R.drawable.ic_mic_on
                : R.drawable.ic_mic_off_red);
    }

    /**
     * 设置大视图中视频渲染
     */
    private void setLargeRenderView(String userId) {
        if (TextUtils.isEmpty(userId)) return;
        TextureView renderView = mDataManger.getUserRenderView(userId);
        bindRenderViewToContainer(userId, mViewBinding.chatLargeContainer);
        bindRenderViewToRTC(renderView, userId);
    }

    /**
     * 设置小视图中视频渲染
     *
     * @param userId 被渲染视频的用户id
     * @param micOn  被渲染视频用户麦克风是否打开
     */
    private void addSmallRenderView(String userId, boolean micOn) {
        View lastView = mSmallRenderViews.get(userId);
        Utils.removeFromParent(lastView);
        LayoutSmallVideoBinding smallVideoItem = LayoutSmallVideoBinding.inflate(LayoutInflater.from(this));
        smallVideoItem.getRoot().setOnClickListener(DebounceClickListener.create(v -> {
            if (mRoom.scene == Room.SCENE_SHARE) return;
            View videoContainer = v.findViewById(R.id.small_video_container_fl);
            if (videoContainer == null) return;
            String uidToLarge = (String) videoContainer.getTag(R.id.video_container_tag_id);
            if (TextUtils.isEmpty(uidToLarge)) return;
            refreshRTCRenderView(uidToLarge);
        }));
        boolean isRemote = !TextUtils.equals(userId, mSelfUid);
        FrameLayout.LayoutParams parentParams = new FrameLayout.LayoutParams(Util.dp2px(70), Util.dp2px(70));
        if (isRemote) {
            parentParams.rightMargin = Util.dp2px(3) * 2;
            parentParams.bottomMargin = Util.dp2px(3) * 2;
        }
        smallVideoItem.getRoot().setLayoutParams(parentParams);
        // 添加远端渲染视图
        TextureView renderView = mDataManger.getUserRenderView(userId);
        bindRenderViewToContainer(userId, smallVideoItem.smallVideoContainerFl);
        bindRenderViewToRTC(renderView, userId);
        if (isRemote) {
            mViewBinding.smallVideosLl.addView(smallVideoItem.getRoot());
        } else {
            FrameLayout selfContainer;
            if (mRoom.scene == Room.SCENE_CHAT || !mIsLandscape) {
                selfContainer = mViewBinding.portraitLocalSmallVideoFl;
            } else {
                selfContainer = mViewBinding.landscapeLocalSmallVideoFl;
            }
            selfContainer.addView(smallVideoItem.getRoot());
            selfContainer.setVisibility(View.VISIBLE);
        }
        smallVideoItem.micOnOffIv.setVisibility(micOn ? View.GONE : View.VISIBLE);
        if (!micOn) {
            smallVideoItem.micOnOffIv.setImageResource(R.drawable.ic_mic_off_red);
        }
        mSmallRenderViews.put(userId, smallVideoItem.getRoot());
    }

    /**
     * 将渲染视图TextureView设置到RTC，作为渲染目标视图
     *
     * @param textureView 渲染视图
     * @param userId      用户id
     */
    private void bindRenderViewToRTC(TextureView textureView, String userId) {
        if (textureView == null || TextUtils.isEmpty(userId)) {
            return;
        }
        VideoCanvas videoCanvas = new VideoCanvas();
        videoCanvas.isScreen = false;
        videoCanvas.renderMode = VideoCanvas.RENDER_MODE_HIDDEN;
        videoCanvas.uid = userId;
        videoCanvas.roomId = mRoomId;
        videoCanvas.renderView = textureView;
        if (TextUtils.equals(userId, mSelfUid)) {
            mRTCVideo.setLocalVideoCanvas(StreamIndex.STREAM_INDEX_MAIN, null);
            mRTCVideo.setLocalVideoCanvas(StreamIndex.STREAM_INDEX_MAIN, videoCanvas);
        } else {
            mRTCVideo.setRemoteVideoCanvas(userId, StreamIndex.STREAM_INDEX_MAIN, null);
            mRTCVideo.setRemoteVideoCanvas(userId, StreamIndex.STREAM_INDEX_MAIN, videoCanvas);
        }
    }

    /**
     * 将渲染视图绑定到父容器，UI才可见
     *
     * @param userId    渲染视图拥有者用户id
     * @param container 父容器
     */
    private void bindRenderViewToContainer(String userId, ViewGroup container) {
        if (userId == null || container == null) {
            return;
        }
        TextureView renderView = mDataManger.getUserRenderView(userId);
        FrameLayout.LayoutParams params = new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT);
        Utils.attachViewToViewGroup(container, renderView, params);
        // 记录view对应的uid
        container.setTag(R.id.video_container_tag_id, userId);
    }

    /**
     * 移除远端列表用户
     *
     * @param uid 用户id
     */
    private void removeSmallRenderView(String uid) {
        View view = mSmallRenderViews.get(uid);
        if (view != null) {
            mViewBinding.smallVideosLl.removeView(view);
        }
        mSmallRenderViews.remove(uid);
    }

    private void showRemoteUsers() {
        if (mRemoteUsers.size() > 0) {
            for (User item : mRemoteUsers) {
                if (item == null) continue;
                addSmallRenderView(item.userId, item.isMicOn());
            }
        }
    }

    /**
     * 更新房间场景值和相关UI
     *
     * @param needUpdateServer 是否需要更新服务端场景数据
     */
    private void updateRoomSceneAndUi(TargetScene scene, boolean needUpdateServer) {
        if (!needUpdateServer) {
            updateScene(scene);
            bindViewForScene(scene);
            return;
        }
        boolean joinShare = scene.scene == Room.SCENE_SHARE;
        String liveUrl = TextUtils.isEmpty(scene.liveUrl) ? null : scene.liveUrl;
        //加入一起看场景
        if (joinShare && liveUrl != null) {
            updateScene(scene);
            bindViewForScene(scene);
            return;
        }
        //返回聊天场景
        if (!joinShare) {
            mRTSClient.leaveLiveShare(mRoomId, mSelfUid, new IRequestCallback<LeaveShareResponse>() {
                @Override
                public void onSuccess(LeaveShareResponse data) {
                    updateScene(scene);
                    bindViewForScene(scene);
                }

                @Override
                public void onError(int errorCode, String message) {
                    String msg = "leaveLiveShare onError errorCode:" + errorCode + ",message:" + message;
                    SafeToast.show(msg);
                }
            });
        }
    }

    private void updateScene(TargetScene scene) {
        if (scene == null) return;
        mRoom.scene = scene.scene;
        mRoom.videoUrl = scene.liveUrl;
        mRoom.screenOrientation = scene.screenOrientation;
    }

    /***根据场景值更新UI*/
    private void bindViewForScene(TargetScene scene) {
        boolean liveShareVisible = scene.scene == Room.SCENE_SHARE;
        mViewBinding.triggerInputBtn.setVisibility(liveShareVisible ? View.VISIBLE : View.GONE);
        mViewBinding.settingIv.setVisibility(liveShareVisible ? View.VISIBLE : View.GONE);
        boolean isAudience = TextUtils.isEmpty(mSelfUid) || !TextUtils.equals(mRoom.hostUserId, mSelfUid);
        mViewBinding.liveShareIv.setVisibility(isAudience ? View.GONE : View.VISIBLE);
        mTextMessageComponent.enableMessagePrint(liveShareVisible);
        if (liveShareVisible) {
            showShareFragment(scene);
        } else {
            mTextMessageComponent.clearTextMessage();
            removeShareFragment();
        }
        String uidToLarge = (String) mViewBinding.chatLargeContainer.getTag(R.id.video_container_tag_id);
        if (!TextUtils.isEmpty(uidToLarge)) {
            refreshRTCRenderView(uidToLarge);
        }
    }

    /**
     * 全屏播放时开关RTC视频窗口的监听器
     */
    private final DebounceClickListener mToggleVideoWindowListener = DebounceClickListener.create(view -> {
        boolean windowClosing = mViewBinding.landscapeLocalSmallVideoFl.getVisibility() == View.GONE;
        mViewBinding.landscapeLocalSmallVideoFl.setVisibility(windowClosing ? View.VISIBLE : View.GONE);
        mViewBinding.landscapeRemoteSmallVideosSl.setVisibility(windowClosing ? View.VISIBLE : View.GONE);
        Drawable drawable = ContextCompat.getDrawable(this, windowClosing
                ? R.drawable.ic_video_window_down
                : R.drawable.ic_video_window_up);
        if (drawable != null) {
            drawable.setBounds(0, 0, (int) Utilities.dip2Px(9), (int) Utilities.dip2Px(7));
        }
        mViewBinding.closeVideosTv.setCompoundDrawables(null, null, drawable, null);
    });

    /**
     * 刷新RTC渲染View
     *
     * @param largeUid 大视图应该展示的用户Uid
     */
    private void refreshRTCRenderView(String largeUid) {
        boolean selfInLarge = TextUtils.equals(largeUid, mSelfUid);
        //本地用户小视图
        int portraitLocalSmallVis;
        int landscapeLocalSmallVis;
        if (mRoom.scene == Room.SCENE_CHAT) {
            portraitLocalSmallVis = selfInLarge ? View.GONE : View.VISIBLE;
            landscapeLocalSmallVis = View.GONE;
        } else {
            portraitLocalSmallVis = mIsLandscape ? View.GONE : View.VISIBLE;
            landscapeLocalSmallVis = mIsLandscape ? View.VISIBLE : View.GONE;
        }
        mViewBinding.portraitLocalSmallVideoFl.setVisibility(portraitLocalSmallVis);
        mViewBinding.landscapeLocalSmallVideoFl.setVisibility(landscapeLocalSmallVis);
        if (portraitLocalSmallVis == View.VISIBLE || landscapeLocalSmallVis == View.VISIBLE) {
            addSmallRenderView(mSelfUid, mCameraMicManger.isMicOn());
        }
        //远端用户小视图
        boolean portraitRemoteSmallVis = mRoom.scene == Room.SCENE_CHAT || !mIsLandscape;
        boolean landscapeRemoteSmallVis = mRoom.scene != Room.SCENE_CHAT && mIsLandscape;
        mViewBinding.portraitRemoteSmallVideosHsl.setVisibility(portraitRemoteSmallVis ? View.VISIBLE : View.GONE);
        mViewBinding.landscapeRemoteSmallVideosSl.setVisibility(landscapeRemoteSmallVis ? View.VISIBLE : View.GONE);
        mViewBinding.closeVideosTv.setVisibility(landscapeRemoteSmallVis ? View.VISIBLE : View.GONE);
        mViewBinding.closeVideosTv.setOnClickListener(mToggleVideoWindowListener);
        for (View view : mSmallRenderViews.values()) {
            if (view == null) continue;
            if (view.getVisibility() != View.VISIBLE) {
                view.setVisibility(View.VISIBLE);
                FrameLayout videoContainer = view.findViewById(R.id.small_video_container_fl);
                String uid = (String) videoContainer.getTag(R.id.video_container_tag_id);
                bindRenderViewToContainer(uid, videoContainer);
                ImageView micOnOffIv = view.findViewById(R.id.mic_on_off_iv);
                updateMicStatus(micOnOffIv, uid);
            }
        }
        if (mRoom.scene == Room.SCENE_CHAT) {
            //如果大视图中展示的时远端用户，需要在远端小视频图中隐藏
            if (!selfInLarge) {
                View smallVideoItem = mSmallRenderViews.get(largeUid);
                if (smallVideoItem != null) {
                    smallVideoItem.setVisibility(View.GONE);
                }
            }
            //大视图
            bindRenderViewToContainer(largeUid, mViewBinding.chatLargeContainer);
        }
    }

    private void updateMicStatus(ImageView micOnOffIv, String uid) {
        boolean micOn;
        if (TextUtils.equals(uid, mSelfUid)) {
            micOn = mCameraMicManger.isMicOn();
        } else {
            User user = getRemoteUser(uid);
            micOn = user != null && user.isMicOn();
        }
        micOnOffIv.setVisibility(micOn ? View.GONE : View.VISIBLE);
        if (!micOn) {
            micOnOffIv.setImageResource(R.drawable.ic_mic_off_red);
        }
    }

    private final Observer mPlayEventListener = (o, playEvent) -> {
        if (playEvent instanceof PlayStateEnterFullScreen) {
            mIsLandscape = true;
            mViewBinding.titleBar.setVisibility(View.GONE);
            mViewBinding.bottomBar.setVisibility(View.GONE);
            mViewBinding.inputBar.setVisibility(View.GONE);
            mViewBinding.textMessageRcv.setVisibility(View.GONE);

            mViewBinding.portraitRemoteSmallVideosHsl.removeView(mViewBinding.smallVideosLl);
            mViewBinding.smallVideosLl.setOrientation(LinearLayout.VERTICAL);
            FrameLayout.LayoutParams llp = new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.MATCH_PARENT, Gravity.TOP);
            mViewBinding.landscapeRemoteSmallVideosSl.removeAllViews();
            mViewBinding.landscapeRemoteSmallVideosSl.addView(mViewBinding.smallVideosLl, llp);
            String uidToSmall = (String) mViewBinding.chatLargeContainer.getTag(R.id.video_container_tag_id);
            if (!TextUtils.isEmpty(uidToSmall)) {
                refreshRTCRenderView(uidToSmall);
            }
        } else if (playEvent instanceof PlayStateExitFullScreen) {
            mIsLandscape = false;
            mViewBinding.titleBar.setVisibility(View.VISIBLE);
            mViewBinding.bottomBar.setVisibility(View.VISIBLE);
            mViewBinding.textMessageRcv.setVisibility(View.VISIBLE);

            mViewBinding.landscapeRemoteSmallVideosSl.removeView(mViewBinding.smallVideosLl);
            mViewBinding.smallVideosLl.setOrientation(LinearLayout.HORIZONTAL);
            FrameLayout.LayoutParams plp = new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.MATCH_PARENT, Gravity.CENTER);
            mViewBinding.portraitRemoteSmallVideosHsl.removeAllViews();
            mViewBinding.portraitRemoteSmallVideosHsl.addView(mViewBinding.smallVideosLl, plp);
            String uidToLarge = (String) mViewBinding.chatLargeContainer.getTag(R.id.video_container_tag_id);
            if (!TextUtils.isEmpty(uidToLarge)) {
                refreshRTCRenderView(uidToLarge);
            }
        }
    };

    private final LiveFragment.ShareFailedListener mShareFailedListener = (isFirstPlay) -> {
        if (isFirstPlay) {
            TargetScene scene = new TargetScene(Room.SCENE_CHAT);
            updateRoomSceneAndUi(scene, false);
        } else {
            // 非第一次解析失败，需要停在一起看页面
            SafeToast.show(Util.getString(R.string.paring_url_failed));
        }
    };

    /**
     * 展示一起看fragment
     */
    private void showShareFragment(TargetScene scene) {
        if (mShareFragment != null && mShareFragment.isVisible()) return;
        if (!TextUtils.isEmpty(scene.liveUrl)) {
            mShareFragment = new LiveFragment();
            Bundle args = new Bundle();
            args.putString(LiveFragment.ROOM_ID, mRoomId);
            args.putString(LiveFragment.SELF_UID, mSelfUid);
            args.putString(LiveFragment.HOST_UID, mRoom.hostUserId);
            args.putString(LiveFragment.LIVE_URL, scene.liveUrl);
            args.putInt(LiveFragment.SCREEN_ORIENTATION, scene.screenOrientation);
            mShareFragment.setArguments(args);
            mShareFragment.setPlayEventListener(mPlayEventListener);
            mShareFragment.setParseFailedListener(mShareFailedListener);
            getSupportFragmentManager().beginTransaction()
                    .add(R.id.share_live_container, mShareFragment)
                    .commitAllowingStateLoss();
        }
    }

    /**
     * 移除一起看fragment
     */
    private void removeShareFragment() {
        if (mShareFragment == null) return;
        mShareFragment.resetToPortrait();
        getSupportFragmentManager().beginTransaction()
                .remove(mShareFragment)
                .commitAllowingStateLoss();
        mShareFragment = null;
        dismissVoiceSettingDialog();
        mDataManger.resetVideoVolume();
    }

    @Override
    protected void onResume() {
        super.onResume();
        mVisible = true;
        TargetScene waitScene = mWaitScene;
        if (waitScene != null) {
            mWaitScene = null;
            updateRoomSceneAndUi(waitScene, false);
        }
    }

    @Override
    protected void onPause() {
        super.onPause();
        mVisible = false;
    }

    @Override
    protected void onDestroy() {
        SolutionDemoEventManager.unregister(this);
        if (mCloseRoomDialog != null && mCloseRoomDialog.isShowing()) {
            mCloseRoomDialog.dismiss();
        }
        IMEUtils.closeIME(mViewBinding.inputEt);
        mRTSClient.leaveRoom(mRoomId, mSelfUid);
        LiveShareRTCManger.ins().leaveRoom();
        mHandler.removeCallbacks(mUserSpeakStatusTask);
        super.onDestroy();
    }

    /**
     * 业务用户加入房间事件
     */
    @Subscribe(threadMode = ThreadMode.MAIN)
    public void onUserJoin(JoinRoomInform inform) {
        if (isFinishing()) {
            return;
        }
        User user = inform.user;
        if (user == null) {
            return;
        }
        String userId = inform.user.userId;
        Log.i(TAG, "onUserJoin uid:" + userId);
        if (TextUtils.isEmpty(userId) || TextUtils.equals(userId, mSelfUid)) return;
        mRemoteUsers.add(inform.user);

        // 短时间杀进程重进case
        RTCUserJoinEvent rtcUserJoinEvent = new RTCUserJoinEvent(inform.user.userId, inform.user.isMicOn());
        onRTCUserJoinEvent(rtcUserJoinEvent);
    }

    /**
     * SDK 用户加入房间事件
     */
    @Subscribe(threadMode = ThreadMode.MAIN)
    public void onRTCUserJoinEvent(RTCUserJoinEvent event) {
        User user = getRemoteUser(event.userId);
        if (user == null) {
            return;
        }
        addSmallRenderView(user.userId, user.isMicOn());
        updateUserMediaStatus(user.userId, user.camera, user.mic);
    }

    /**
     * 业务用户离开房间事件回调
     */
    @Subscribe(threadMode = ThreadMode.MAIN)
    public void onUserLeave(LeaveRoomInform inform) {
        if (isFinishing()) {
            return;
        }
        User user = inform.user;
        if (user == null) {
            return;
        }
        String userId = inform.user.userId;
        Log.i(TAG, "onUserLeaveInform uid:" + userId);
        if (TextUtils.equals(userId, mSelfUid) && !TextUtils.equals(mSelfUid, mRoom.hostUserId)) {
            finish();
            return;
        }
        removeRemoteUser(userId);
        removeSmallRenderView(userId);
        mDataManger.removeUserRenderView(userId);
        String uidInLarge = (String) mViewBinding.chatLargeContainer.getTag(R.id.video_container_tag_id);
        if (TextUtils.equals(userId, uidInLarge)) {
            refreshRTCRenderView(mSelfUid);
            mViewBinding.chatLargeContainer.setTag(R.id.video_container_tag_id, mSelfUid);
        }
    }

    /**
     * 更新用户的媒体状态
     *
     * @param userId   用户id
     * @param cameraOn 摄像头状态
     * @param micOn    麦克风状态
     */
    private void updateUserMediaStatus(String userId,
                                       @User.CameraStatus int cameraOn,
                                       @User.MicStatus int micOn) {
        userId = userId == null ? "" : userId;
        Log.d(TAG, String.format("updateUserMediaStatus: %s %d %d", userId, cameraOn, micOn));
        if (TextUtils.isEmpty(userId)) {
            return;
        }
        for (User item : mRemoteUsers) {
            if (TextUtils.equals(item.userId, userId)) {
                item.camera = cameraOn;
                item.mic = micOn;
            }
        }
        View smallVideoView = mSmallRenderViews.get(userId);
        if (smallVideoView == null) {
            return;
        }
        ImageView micOnOffIv = smallVideoView.findViewById(R.id.mic_on_off_iv);
        updateMicStatus(micOnOffIv, userId);
        View renderView = smallVideoView.findViewById(R.id.small_video_container_fl);
        renderView.setVisibility(cameraOn == CAMERA_STATUS_ON ? View.VISIBLE : View.GONE);
    }

    /**
     * 业务用户开关麦克风、摄像头通知
     */
    @Subscribe(threadMode = ThreadMode.MAIN)
    public void onMicCameraChanged(TurnOnOffMicCameraInform inform) {
        if (isFinishing()) {
            return;
        }
        User user = inform.user;
        if (user == null) {
            return;
        }
        updateUserMediaStatus(user.userId, user.camera, user.mic);
    }

    private void removeRemoteUser(String userId) {
        if (TextUtils.isEmpty(userId)) return;
        Iterator<User> iterator = mRemoteUsers.iterator();
        while (iterator.hasNext()) {
            User user = iterator.next();
            if (TextUtils.equals(user.userId, userId)) {
                iterator.remove();
            }
        }
    }

    private User getRemoteUser(String userId) {
        if (TextUtils.isEmpty(userId)) return null;
        for (User user : mRemoteUsers) {
            if (TextUtils.equals(user.userId, userId)) {
                return user;
            }
        }
        return null;
    }


    /**
     * 业务房间场景切换通知
     */
    @Subscribe(threadMode = ThreadMode.MAIN)
    public void onRoomSceneChange(UpdateRoomSceneInform inform) {
        if (isFinishing()) return;
        Log.i(TAG, "onRoomSceneChange inform:" + inform);
        if (TextUtils.equals(inform.userId, mSelfUid)) {
            return;
        }
        TargetScene scene = new TargetScene(inform.roomScene, inform.url, inform.screenOrientation);
        if (!mVisible && inform.roomScene == Room.SCENE_SHARE) {
            mWaitScene = scene;
            return;
        }
        mWaitScene = null;
        updateRoomSceneAndUi(scene, false);
    }

    /**
     * 业务直播源变更通知
     */
    @Subscribe(threadMode = ThreadMode.MAIN)
    public void onLiveUrlChange(UpdateLiveUrlInform inform) {
        if (isFinishing()) return;
        Log.i(TAG, "onLiveUrlChange inform:" + inform);
        if (TextUtils.equals(inform.userId, mSelfUid)) {
            return;
        }
        mRoom.videoUrl = inform.url;
        mRoom.screenOrientation = inform.screenOrientation;
        if (mShareFragment != null) {
            mShareFragment.updateVideoUrl(inform.url, inform.screenOrientation);
            return;
        }
        if (mWaitScene != null) {
            mWaitScene.liveUrl = inform.url;
            mWaitScene.screenOrientation = inform.screenOrientation;
        }
    }

    /**
     * 业务关闭房间通知
     */
    @Subscribe(threadMode = ThreadMode.MAIN)
    public void onCloseRoom(CloseRoomInform inform) {
        Log.i(TAG, "onCloseRoom inform:" + inform);
        if (isFinishing() || !TextUtils.equals(inform.roomId, mRoomId)) {
            return;
        }
        boolean isAudience = TextUtils.isEmpty(mSelfUid) || !TextUtils.equals(mSelfUid, mRoom.hostUserId);
        if (isAudience && inform.type == CloseRoomInform.TYPE_HOST_CLOSE) {
            SafeToast.show(Util.getString(R.string.room_close_hint));
        }
        if (inform.type == CloseRoomInform.TYPE_TIMEOUT) {
            int hintResId = TextUtils.equals(mSelfUid, mRoom.hostUserId)
                    ? R.string.time_out_hint_host
                    : R.string.time_out_hint_audience;
            SafeToast.show(Util.getString(hintResId));
        }
        if (inform.type == CloseRoomInform.TYPE_BY_AUDIT) {
            SafeToast.show(Util.getString(R.string.room_close_by_audit));
        }
        if (inform.type == CloseRoomInform.TYPE_TIMEOUT
                || inform.type == CloseRoomInform.TYPE_BY_AUDIT
                || isAudience) {
            finish();
        }
    }

    /***来自RTC重复登录被踢通知*/
    @Subscribe(threadMode = ThreadMode.MAIN)
    public void onKickOutInform(KickOutEvent event) {
        SolutionToast.show(R.string.kickout_by_re_login);
        setResult(RESULT_CODE_DUPLICATE_LOGIN);
        finish();
    }

    /***来自RTC远端用户音频属性通知*/
    @Subscribe(threadMode = ThreadMode.MAIN)
    public void onRemoteUserSpeakerStatusInform(RTCRemoteUserSpeakStatusEvent event) {
        mRemoteUserProperties = event.userSpeakStatus;
        refreshUserSpeakStatus();
    }

    /***来自RTC本地用户音频属性通知*/
    @Subscribe(threadMode = ThreadMode.MAIN)
    public void onLocalUserSpeakerStatusInform(RTCLocalUserSpeakStatusEvent event) {
        mLocalUserProperties = event.userSpeakStatus;
        refreshUserSpeakStatus();
    }

    private void refreshUserSpeakStatus() {
        mHandler.removeCallbacks(mUserSpeakStatusTask);
        mHandler.post(mUserSpeakStatusTask);
    }

    void showVoiceSettingDialog() {
        dismissVoiceSettingDialog();
        mVoiceSettingDialog = new VoiceSettingDialog(this, getLifecycle());
        mVoiceSettingDialog.show();
    }

    void dismissVoiceSettingDialog() {
        if (mVoiceSettingDialog != null) {
            mVoiceSettingDialog.dismiss();
        }
    }
}
