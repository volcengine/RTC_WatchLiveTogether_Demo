package com.volcengine.vertcdemo.liveshare.core;

import static com.ss.bytertc.engine.VideoCanvas.RENDER_MODE_HIDDEN;

import android.content.Context;
import android.text.TextUtils;
import android.util.Log;
import android.view.TextureView;

import androidx.annotation.NonNull;

import com.ss.bytertc.engine.RTCRoom;
import com.ss.bytertc.engine.RTCRoomConfig;
import com.ss.bytertc.engine.RTCVideo;
import com.ss.bytertc.engine.UserInfo;
import com.ss.bytertc.engine.VideoCanvas;
import com.ss.bytertc.engine.data.AudioPropertiesConfig;
import com.ss.bytertc.engine.data.CameraId;
import com.ss.bytertc.engine.data.LocalAudioPropertiesInfo;
import com.ss.bytertc.engine.data.MirrorType;
import com.ss.bytertc.engine.data.RemoteAudioPropertiesInfo;
import com.ss.bytertc.engine.data.RemoteStreamKey;
import com.ss.bytertc.engine.data.StreamIndex;
import com.ss.bytertc.engine.data.VideoFrameInfo;
import com.ss.bytertc.engine.type.AudioProfileType;
import com.ss.bytertc.engine.type.AudioScenarioType;
import com.ss.bytertc.engine.type.ChannelProfile;
import com.ss.bytertc.engine.type.ErrorCode;
import com.ss.bytertc.engine.type.MediaStreamType;
import com.ss.video.rtc.demo.basic_module.utils.SafeToast;
import com.ss.video.rtc.demo.basic_module.utils.Utilities;
import com.volcengine.vertcdemo.common.MLog;
import com.volcengine.vertcdemo.core.eventbus.SolutionDemoEventManager;
import com.volcengine.vertcdemo.core.net.rts.RTCRoomEventHandlerWithRTS;
import com.volcengine.vertcdemo.core.net.rts.RTCVideoEventHandlerWithRTS;
import com.volcengine.vertcdemo.core.net.rts.RTSInfo;
import com.volcengine.vertcdemo.liveshare.bean.AudioProperty;
import com.volcengine.vertcdemo.liveshare.bean.RTCErrorEvent;
import com.volcengine.vertcdemo.liveshare.bean.event.KickOutEvent;
import com.volcengine.vertcdemo.liveshare.bean.event.RTCLocalUserSpeakStatusEvent;
import com.volcengine.vertcdemo.liveshare.bean.event.RTCRemoteUserSpeakStatusEvent;
import com.volcengine.vertcdemo.liveshare.bean.event.RTCUserJoinEvent;
import com.volcengine.vertcdemo.liveshare.bean.event.RTCUserLeaveEvent;

import java.util.ArrayList;
import java.util.List;
import java.util.Observer;

public class LiveShareRTCManger {
    private static final String TAG = "LiveShareRTCManger";

    private static LiveShareRTCManger sInstance = null;

    private RTCVideo mRTCVideo;
    private RTCRoom mRTCRoom;
    private LiveShareRTSClient mRTSClient;
    private String mRoomId;

    /**
     * ?????????????????????????????????????????????????????????
     */
    private final Observer mMediaStatusObserver = (o, arg) -> {
        if (mRTCVideo == null) {
            return;
        }
        // ??????????????????????????????
        if (LiveShareDataManager.getInstance().getCameraMicManager().isCameraOn()) {
            mRTCVideo.startVideoCapture();
        } else {
            mRTCVideo.stopVideoCapture();
        }

        // ??????????????????????????????
        boolean isMicOn = LiveShareDataManager.getInstance().getCameraMicManager().isMicOn();
        if (isMicOn) {
            // ?????????????????????
            mRTCVideo.startAudioCapture();
        }
        muteLocalAudioStream(!isMicOn);

        mRTCVideo.switchCamera(
                LiveShareDataManager.getInstance().getCameraMicManager().isFrontCamera()
                        ? CameraId.CAMERA_ID_FRONT
                        : CameraId.CAMERA_ID_BACK);

        setLocalVideoMirror();
    };

    public static LiveShareRTCManger ins() {
        if (sInstance == null) {
            sInstance = new LiveShareRTCManger();
        }
        return sInstance;
    }

    private final RTCVideoEventHandlerWithRTS mRTCVideoEventHandler = new RTCVideoEventHandlerWithRTS() {

        /**
         * SDK ????????????????????????????????????????????????????????????
         * @param remoteStreamKey ???????????????????????? RemoteStreamKey
         * @param frameInfo ???????????????????????? VideoFrameInfo
         */
        @Override
        public void onFirstRemoteVideoFrameDecoded(RemoteStreamKey remoteStreamKey, VideoFrameInfo frameInfo) {
            super.onFirstRemoteVideoFrameDecoded(remoteStreamKey, frameInfo);
            Log.d(TAG, "onFirstRemoteVideoFrameDecoded: " + remoteStreamKey.toString());

            String uid = remoteStreamKey.getUserId();
            if (!TextUtils.isEmpty(uid) && !TextUtils.isEmpty(mRoomId)) {
                TextureView renderView = LiveShareDataManager.getInstance().getUserRenderView(uid);
                setRemoteVideoView(uid, renderView);
            }
        }

        /**
         * ?????????????????????????????? {https://www.volcengine.com/docs/6348/70082#warncode}
         */
        @Override
        public void onWarning(int warn) {
            super.onWarning(warn);
            Log.d(TAG, "onWarning: " + warn);
        }

        /**
         * ?????????????????????????????? {https://www.volcengine.com/docs/6348/70082#errorcode}
         */
        @Override
        public void onError(int err) {
            super.onError(err);
            Log.d(TAG, "onError: " + err);
            SolutionDemoEventManager.post(new RTCErrorEvent(err));
        }

        /**
         * ????????????????????????????????? RTC SDK ????????????/?????????????????????????????????????????????????????????
         * @param audioProperties ????????????????????????????????????????????????????????? ID????????? ID ????????? RemoteAudioPropertiesInfo???
         * @param totalRemoteVolume ???????????????????????????????????????
         */
        @Override
        public void onRemoteAudioPropertiesReport(RemoteAudioPropertiesInfo[] audioProperties,
                                                  int totalRemoteVolume) {
            RTCRemoteUserSpeakStatusEvent event = new RTCRemoteUserSpeakStatusEvent();
            for (RemoteAudioPropertiesInfo item : audioProperties) {
                String uid = item.streamKey == null ? null : item.streamKey.getUserId();
                boolean isScreenStream = item.streamKey != null && item.streamKey.getStreamIndex() == StreamIndex.STREAM_INDEX_SCREEN;
                boolean speaking = item.audioPropertiesInfo != null && item.audioPropertiesInfo.linearVolume > 60;
                AudioProperty audioProperty = new AudioProperty(uid, isScreenStream, speaking);
                event.addAudioProperty(audioProperty);
            }
            SolutionDemoEventManager.post(event);
        }

        /**
         * ???????????????????????? RTC SDK ??????????????????????????????????????????????????????
         * @param audioProperties ??????????????????????????? LocalAudioPropertiesInfo ???
         */
        @Override
        public void onLocalAudioPropertiesReport(LocalAudioPropertiesInfo[] audioProperties) {
            RTCLocalUserSpeakStatusEvent event = new RTCLocalUserSpeakStatusEvent();
            for (LocalAudioPropertiesInfo item : audioProperties) {
                boolean speaking = item.audioPropertiesInfo != null && item.audioPropertiesInfo.linearVolume > 60;
                boolean isScreenStream = item.streamIndex == StreamIndex.STREAM_INDEX_SCREEN;
                AudioProperty audioProperty = new AudioProperty(isScreenStream, speaking);
                event.addAudioProperty(audioProperty);
            }
            SolutionDemoEventManager.post(event);
        }
    };

    @SuppressWarnings("WriteOnlyObject")
    private final RTCRoomEventHandlerWithRTS mRTCRoomEventHandler = new RTCRoomEventHandlerWithRTS() {

        @Override
        public void onRoomStateChanged(String roomId, String uid, int state, String extraInfo) {
            super.onRoomStateChanged(roomId, uid, state, extraInfo);
            Log.d(TAG, "onRoomStateChanged uid:" + uid + ",state:" + state);
            if (state == ErrorCode.ERROR_CODE_DUPLICATE_LOGIN) {
                SolutionDemoEventManager.post(new KickOutEvent());
                return;
            }
            if (!isFirstJoinRoomSuccess(state, extraInfo)) {
                SolutionDemoEventManager.post(new RTCErrorEvent(state));
            }
            if (isFirstJoinRoomSuccess(state, extraInfo)) {
                SolutionDemoEventManager.post(new RTCErrorEvent(0));
            }
        }

        @Override
        public void onUserJoined(UserInfo userInfo, int elapsed) {
            super.onUserJoined(userInfo, elapsed);
            Log.d(TAG, String.format("onUserJoined : %s %d", userInfo, elapsed));

            // SDK ??????????????????
            SolutionDemoEventManager.post(new RTCUserJoinEvent(userInfo.getUid(), true));
        }

        @Override
        public void onUserLeave(String uid, int reason) {
            Log.d(TAG, "onUserLeave uid: " + uid + ",reason:" + reason);
            SolutionDemoEventManager.post(new RTCUserLeaveEvent(uid));
        }
    };

    private LiveShareRTCManger() {}

    private void initEngine(String appId, String bid) {
        Log.d(TAG, String.format("initEngine: appId: %s", appId));
        destroyRTCEngine();
        mRTCVideo = RTCVideo.createRTCVideo(Utilities.getApplicationContext(), appId, mRTCVideoEventHandler, null, null);
        mRTCVideo.setBusinessId(bid);
        mRTCVideo.enableAudioPropertiesReport(new AudioPropertiesConfig(500, false, true));
        setLocalVideoMirror();

        observeMediaStatus();

        initVideoEffect();
    }

    public void rtcConnect(@NonNull RTSInfo info) {
        initEngine(info.appId, info.bid);
        mRTSClient = new LiveShareRTSClient(mRTCVideo, info);
        mRTCVideoEventHandler.setBaseClient(mRTSClient);
        mRTCRoomEventHandler.setBaseClient(mRTSClient);
    }

    public RTCVideo getRTCEngine() {
        return mRTCVideo;
    }

    public LiveShareRTSClient getRTSClient() {
        return mRTSClient;
    }

    /**
     * ??????RTCEngine
     */
    public void destroyRTCEngine() {
        if (mRTCRoom != null) {
            mRTCRoom.destroy();
        }
        if (mRTCVideo != null) {
            RTCVideo.destroyRTCVideo();
            mRTCVideo = null;
        }
        stopObserveMediaStatus();
    }

    /**
     * ??????????????????
     */
    public void adjustUserVolume(int volume) {
        if (mRTCVideo == null) {
            return;
        }
        mRTCVideo.setPlaybackVolume(volume);
    }

    /**
     * ??????/????????????????????????
     *
     * @param enable ????????????????????????
     */
    public void enablePlaybackDucking(boolean enable) {
        if (mRTCVideo == null) {
            return;
        }
        mRTCVideo.enablePlaybackDucking(enable);
    }

    public void setLocalVideoMirrorMode(MirrorType mode) {
        if (mRTCVideo == null) {
            return;
        }
        mRTCVideo.setLocalVideoMirrorType(mode);
    }

    /**
     * ??????????????????
     * @param userId ??????id
     * @param textureView ????????????????????????
     */
    public void setRemoteVideoView(String userId, TextureView textureView) {
        mRoomId = mRoomId == null ? "" : mRoomId;
        Log.d(TAG, String.format("setRemoteVideoView : %s %s", userId, mRoomId));
        if (mRTCVideo != null) {
            VideoCanvas canvas = new VideoCanvas(textureView, RENDER_MODE_HIDDEN, mRoomId, userId, false);
            mRTCVideo.setRemoteVideoCanvas(userId, StreamIndex.STREAM_INDEX_MAIN, canvas);
        }
    }

    public void joinRoom(String token, String roomId, String userId) {
        MLog.d("joinRoom", "token:" + token + " roomId:" + roomId + " userId:" + userId);
        leaveRoom();
        if (mRTCVideo == null) {
            return;
        }
        mRoomId = roomId;
        mRTCRoom = mRTCVideo.createRTCRoom(roomId);
        mRTCRoom.setRTCRoomEventHandler(mRTCRoomEventHandler);
        mRTCRoomEventHandler.setBaseClient(mRTSClient);
        UserInfo userInfo = new UserInfo(userId, null);
        RTCRoomConfig roomConfig = new RTCRoomConfig(ChannelProfile.CHANNEL_PROFILE_COMMUNICATION,
                true, true, true);
        mRTCRoom.joinRoom(token, userInfo, roomConfig);

        mRTCVideo.setAudioScenario(AudioScenarioType.AUDIO_SCENARIO_COMMUNICATION);
        mRTCVideo.setAudioProfile(AudioProfileType.AUDIO_PROFILE_STANDARD);

        muteLocalAudioStream(!LiveShareDataManager.getInstance().getCameraMicManager().isMicOn());
        turnOnCamera(LiveShareDataManager.getInstance().getCameraMicManager().isCameraOn());
    }

    public void leaveRoom() {
        MLog.d("leaveRoom", "");
        if (mRTCRoom != null) {
            mRTCRoom.leaveRoom();
            mRTCRoom.destroy();
        }
        mRTCRoom = null;
    }

    public void muteLocalAudioStream(boolean mute) {
        MLog.d("muteLocalAudioStream", "");
        if (mRTCRoom == null) {
            return;
        }
        if (mute) {
            mRTCRoom.unpublishStream(MediaStreamType.RTC_MEDIA_STREAM_TYPE_AUDIO);
        } else {
            mRTCRoom.publishStream(MediaStreamType.RTC_MEDIA_STREAM_TYPE_AUDIO);
        }
    }

    /**
     * ???????????????????????????????????????????????????????????????
     */
    public void observeMediaStatus() {
        LiveShareDataManager.getInstance().getCameraMicManager().addObserver(mMediaStatusObserver);
    }

    /**
     * ???????????????????????????????????????????????????????????????
     */
    public void stopObserveMediaStatus() {
        LiveShareDataManager.getInstance().getCameraMicManager().deleteObserver(mMediaStatusObserver);
    }

    /**
     * ???????????????
     * @param isCameraOn ?????????????????????
     */
    private void turnOnCamera(boolean isCameraOn) {
        if (mRTCVideo != null) {
            if (isCameraOn) {
                mRTCVideo.startVideoCapture();
            } else {
                mRTCVideo.stopVideoCapture();
            }
        }
    }

    /**
     * ?????????????????????????????????????????????????????????????????????????????????
     */
    private void setLocalVideoMirror() {
        boolean isFrontCamera = LiveShareDataManager.getInstance().getCameraMicManager().isFrontCamera();
        LiveShareRTCManger.ins().setLocalVideoMirrorMode(isFrontCamera
                ? MirrorType.MIRROR_TYPE_RENDER_AND_ENCODER
                : MirrorType.MIRROR_TYPE_NONE);
    }

    /**
     * ???????????????
     */
    private void initVideoEffect() {

    }

    /**
     * ?????????????????????
     * @param context ???????????????
     */
    public void openEffectDialog(Context context) {
        SafeToast.show("??????????????????????????????????????????????????????????????????Demo");
    }
}
