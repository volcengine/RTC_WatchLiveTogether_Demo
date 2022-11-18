package com.volcengine.vertcdemo.liveshare.core;

import android.view.TextureView;
import android.view.ViewGroup;
import android.view.ViewParent;

import androidx.annotation.MainThread;
import androidx.annotation.NonNull;

import com.ss.bytertc.engine.RTCVideo;
import com.ss.video.rtc.demo.basic_module.utils.Utilities;
import com.volcengine.vertcdemo.core.net.rts.RTSInfo;
import com.volcengine.vertcdemo.liveshare.bean.AudioConfig;
import com.volcengine.vertcdemo.liveshare.feature.player.VodAudioProcessor;

import java.util.HashMap;
import java.util.Objects;

public class LiveShareDataManager {
    private static volatile LiveShareDataManager sInstance;

    private CameraMicManger mCameraMicManager = new CameraMicManger();
    private LiveShareRTCManger mRTCManger;
    private HashMap<String, TextureView> mTextures;
    private final AudioConfig mAudioConfig = new AudioConfig();

    private LiveShareDataManager() {
    }

    public static LiveShareDataManager getInstance() {
        if (sInstance == null) {
            synchronized (LiveShareDataManager.class) {
                if (sInstance == null) {
                    sInstance = new LiveShareDataManager();
                }
            }
        }
        return sInstance;
    }

    /**
     * 清除一起看直播场景数据管理，只在退出当前场景时使用
     */
    public void clearUp() {
        if (mRTCManger != null) {
            mRTCManger.destroyRTCEngine();
            mRTCManger = null;
        }
        if (mTextures != null) {
            mTextures.clear();
            mTextures = null;
        }
        sInstance = null;
        mCameraMicManager = null;
    }

    /**
     * 初始化RTC
     *
     * @param rtsInfo 连接rts需要的参数
     */
    public void initRTC(@NonNull RTSInfo rtsInfo) {
        LiveShareRTCManger.ins().rtcConnect(rtsInfo);
        mRTCManger = LiveShareRTCManger.ins();
    }

    @NonNull
    public CameraMicManger getCameraMicManager() {
        Objects.requireNonNull(mCameraMicManager, "get DeviceStatusManager, but null");
        return mCameraMicManager;
    }

    @NonNull
    public LiveShareRTCManger getRTCManager() {
        Objects.requireNonNull(mRTCManger, "get mRTCManger, but null");
        return mRTCManger;
    }

    @NonNull
    public LiveShareRTSClient getRTSClient() {
        Objects.requireNonNull(mRTCManger, "get LiveShareRTSClient, but RTCManger is null");
        LiveShareRTSClient rtsClient = mRTCManger.getRTSClient();
        Objects.requireNonNull(rtsClient, "get LiveShareRTSClient, but null");
        return rtsClient;
    }

    @NonNull
    public RTCVideo getRTCEngine() {
        Objects.requireNonNull(mRTCManger, "get RTCEngine, but RTCManger is null");
        RTCVideo rtcVideo = mRTCManger.getRTCEngine();
        Objects.requireNonNull(rtcVideo, "get RTCEngine, but null");
        return rtcVideo;
    }

    public AudioConfig getAudioConfig() {
        return mAudioConfig;
    }

    public void resetAudioConfig(){
        mAudioConfig.setVideoVolume(AudioConfig.DEFAULT_VIDEO_VOLUME);
        mAudioConfig.setUserVolume(AudioConfig.DEFAULT_USER_VOLUME);
        if (mRTCManger != null){
            mRTCManger.adjustUserVolume(mAudioConfig.getUserVolume());
            VodAudioProcessor.mixAudioGain = mAudioConfig.getVideoVolume();
        }
    }

    /**
     * 获取userId对应的视频渲染View
     *
     * @param userId 需要渲染视频的用户id
     */
    @NonNull
    @MainThread
    public TextureView getUserRenderView(@NonNull String userId) {
        if (mTextures == null) {
            mTextures = new HashMap<>(3);
        }
        TextureView textureView = mTextures.get(userId);
        if (textureView == null) {
            textureView = new TextureView(Utilities.getApplicationContext());
            mTextures.put(userId, textureView);
        }
        return textureView;
    }

    /**
     * 删除特定用户视频渲染View的缓存
     *
     * @param userId 需要删除渲染View对应的用户id
     */
    public void removeUserRenderView(String userId) {
        if (mTextures == null) return;
        mTextures.remove(userId);
    }
}
