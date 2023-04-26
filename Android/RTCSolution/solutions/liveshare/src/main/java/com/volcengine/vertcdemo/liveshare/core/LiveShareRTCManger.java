// Copyright (c) 2023 Beijing Volcano Engine Technology Ltd.
// SPDX-License-Identifier: MIT

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
import com.volcengine.vertcdemo.core.eventbus.SDKReconnectToRoomEvent;
import com.volcengine.vertcdemo.utils.AppUtil;
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
import com.volcengine.vertcdemo.protocol.IEffect;
import com.volcengine.vertcdemo.protocol.ProtocolUtil;

import java.util.Observer;

/**
 * RTC对象管理类
 *
 * 使用单例形式，调用RTC接口，并在调用中更新 LiveShareDataManager 数据
 * 内部记录开关状态
 *
 * 功能：
 * 1.开关和媒体状态
 * 2.获取当前媒体状态
 * 3.接收RTC各种回调，例如：用户进退房、媒体状态改变、媒体状态数据回调、网络状态回调、音量大小回调
 * 4.管理用户视频渲染view
 * 5.加入离开房间
 * 6.创建和销毁引擎
 */
public class LiveShareRTCManger {
    private static final String TAG = "LiveShareRTCManger";

    private static LiveShareRTCManger sInstance = null;

    private RTCVideo mRTCVideo;
    private RTCRoom mRTCRoom;
    private LiveShareRTSClient mRTSClient;
    private String mRoomId;

    /**
     * 摄像头、麦克风、摄像头方向数据变化监听。
     */
    private final Observer mMediaStatusObserver = (o, arg) -> {
        if (mRTCVideo == null) {
            return;
        }
        // 开启、关闭摄像头采集。
        if (LiveShareDataManager.getInstance().getCameraMicManager().isCameraOn()) {
            mRTCVideo.startVideoCapture();
        } else {
            mRTCVideo.stopVideoCapture();
        }

        boolean isMicOn = LiveShareDataManager.getInstance().getCameraMicManager().isMicOn();
        if (isMicOn) {
            // 开启麦克风采集。
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
         * SDK 接收并解码远端视频流首帧后，收到此回调。
         * @param remoteStreamKey 远端流信息，参看 RemoteStreamKey{@link #RemoteStreamKey}
         * @param frameInfo 视频帧信息，参看 VideoFrameInfo{@link #VideoFrameInfo}
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

        @Override
        public void onWarning(int warn) {
            super.onWarning(warn);
            Log.d(TAG, "onWarning: " + warn);
        }

        /**
         * 发生错误回调。
         * @param err 错误代码，参见 IRTCEngineEventHandler.ErrorCode.
         */
        @Override
        public void onError(int err) {
            super.onError(err);
            Log.d(TAG, "onError: " + err);
            SolutionDemoEventManager.post(new RTCErrorEvent(err));
        }

        /**
         * 远端用户的音频信息回调。
         * @param audioPropertiesInfo 远端音频信息，其中包含音频流属性、房间 ID、用户 ID ，详见 RemoteAudioPropertiesInfo。
         * @param totalRemoteVolume 订阅的所有远端流的总音量。
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
         * 本地音频属性信息回调。
         * @param audioPropertiesInfo 本地音频信息，详见 LocalAudioPropertiesInfo。
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

        /**
         * 房间状态改变回调，加入房间、离开房间、发生房间相关的警告或错误时会收到此回调。
         * @param roomId 房间id
         * @param uid 用户id
         * @param state 房间状态码
         * @param extraInfo 额外信息
         */
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
            } else if (isFirstJoinRoomSuccess(state, extraInfo)) {
                SolutionDemoEventManager.post(new RTCErrorEvent(0));
            }
            if (isReconnectSuccess(state, extraInfo)) {
                SolutionDemoEventManager.post(new SDKReconnectToRoomEvent(roomId));
            }
        }

        /**
         * 可见用户加入房间，或房内隐身用户切换为可见的回调。
         * @param userInfo 用户信息
         * @param elapsed 主播角色用户调用 joinRoom 加入房间到房间内其他用户收到该事件经历的时间，单位为 ms。
         */
        @Override
        public void onUserJoined(UserInfo userInfo, int elapsed) {
            super.onUserJoined(userInfo, elapsed);
            Log.d(TAG, String.format("onUserJoined : %s %d", userInfo, elapsed));

            // SDK 用户真实进房
            SolutionDemoEventManager.post(new RTCUserJoinEvent(userInfo.getUid(), true));
        }

        /**
         * 远端用户离开房间，或切至不可见时，本地用户会收到此事件
         * @param uid 离开房间，或切至不可见的的远端用户 ID。
         * @param reason 用户离开房间的原因：
         * • 0: 远端用户调用 leaveRoom 主动退出房间。
         * • 1: 远端用户因 Token 过期或网络原因等掉线。
         * • 2: 远端用户调用 setUserVisibility 切换至不可见状态。
         * • 3: 服务端调用 OpenAPI 将该远端用户踢出房间。
         */
        @Override
        public void onUserLeave(String uid, int reason) {
            Log.d(TAG, "onUserLeave uid: " + uid + ",reason:" + reason);
            SolutionDemoEventManager.post(new RTCUserLeaveEvent(uid));
        }
    };

    private LiveShareRTCManger() {}

    /**
     * 初始化RTC。
     */
    private void initEngine(String appId, String bid) {
        Log.d(TAG, String.format("initEngine: appId: %s", appId));
        destroyRTCEngine();
        mRTCVideo = RTCVideo.createRTCVideo(AppUtil.getApplicationContext(), appId, mRTCVideoEventHandler, null, null);
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
     * 销毁RTCEngine。
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

    public void adjustUserVolume(int volume) {
        if (mRTCVideo == null) {
            return;
        }
        mRTCVideo.setPlaybackVolume(volume);
    }

    /**
     * 打开/关闭音量闪避功能。
     * @param enable true: 打开音量闪避功能。
     *               false: 关闭音量闪避功能。
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
     * 绑定远端视图
     * @param userId 用户id
     * @param textureView 用户视频渲染视图
     */
    public void setRemoteVideoView(String userId, TextureView textureView) {
        mRoomId = mRoomId == null ? "" : mRoomId;
        Log.d(TAG, String.format("setRemoteVideoView : %s %s", userId, mRoomId));
        if (mRTCVideo != null) {
            VideoCanvas canvas = new VideoCanvas(textureView, RENDER_MODE_HIDDEN);
            RemoteStreamKey remoteStreamKey = new RemoteStreamKey(mRoomId, userId, StreamIndex.STREAM_INDEX_MAIN);
            mRTCVideo.setRemoteVideoCanvas(remoteStreamKey, canvas);
        }
    }

    /**
     * 加入 RTC 房间
     * @param token 动态密钥。用于对进房用户进行鉴权验证。
     *              进入房间需要携带 Token。测试时可使用控制台生成临时 Token，正式上线需要使用密钥 SDK 在你的服务端生成并下发 Token。
     *              使用不同 AppID 的 App 是不能互通的。
     *              请务必保证生成 Token 使用的 AppID 和创建引擎时使用的 AppID 相同，否则会导致加入房间失败。
     * @param roomId RTC 房间 id。
     * @param userId    用户 id。
     */
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

    /**
     * 离开房间。
     */
    public void leaveRoom() {
        MLog.d("leaveRoom", "");
        if (mRTCRoom != null) {
            mRTCRoom.leaveRoom();
            mRTCRoom.destroy();
        }
        mRTCRoom = null;
    }

    /**
     * 静音本地音频流。
     * @param mute true: 静音本地音频流。
     *             false: 取消静音本地音频流。
     */
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
     * 注册摄像头、麦克风、摄像头方向数据变化监听。
     */
    public void observeMediaStatus() {
        LiveShareDataManager.getInstance().getCameraMicManager().addObserver(mMediaStatusObserver);
    }

    /**
     * 取消摄像头、麦克风、摄像头方向数据变化监听。
     */
    public void stopObserveMediaStatus() {
        LiveShareDataManager.getInstance().getCameraMicManager().deleteObserver(mMediaStatusObserver);
    }

    /**
     * 开关摄像头。
     * @param isCameraOn 是否打开摄像头。
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
     * 设置视频镜像，前置摄像头开启镜像，后置摄像头不开启镜像。
     */
    private void setLocalVideoMirror() {
        boolean isFrontCamera = LiveShareDataManager.getInstance().getCameraMicManager().isFrontCamera();
        LiveShareRTCManger.ins().setLocalVideoMirrorMode(isFrontCamera
                ? MirrorType.MIRROR_TYPE_RENDER_AND_ENCODER
                : MirrorType.MIRROR_TYPE_NONE);
    }

    /**
     * 初始化美颜。
     */
    private void initVideoEffect() {
        IEffect effect = ProtocolUtil.getIEffect();
        if (effect != null) {
            effect.initWithRTCVideo(mRTCVideo);
        }
    }

    /**
     * 打开美颜对话框。
     * @param context 上下文对象。
     */
    public void openEffectDialog(Context context) {
        IEffect effect = ProtocolUtil.getIEffect();
        if (effect != null) {
            effect.showEffectDialog(context, null);
        }
    }
}
