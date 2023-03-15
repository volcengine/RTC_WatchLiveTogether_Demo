package com.volcengine.vertcdemo.liveshare.feature.player;

import static com.ss.ttm.player.MediaPlayer.IMAGE_LAYOUT_ASPECT_FIT;
import static com.ss.videoarch.liveplayer.ILivePlayer.ENABLE;
import static com.ss.videoarch.liveplayer.ILivePlayer.LIVE_OPTION_IMAGE_LAYOUT;
import static com.ss.videoarch.liveplayer.ILivePlayer.LIVE_PLAYER_OPTION_ASYNC_INIT_CODEC;
import static com.ss.videoarch.liveplayer.ILivePlayer.LIVE_PLAYER_OPTION_H264_HARDWARE_DECODE;

import android.graphics.SurfaceTexture;
import android.util.Log;
import android.view.Surface;
import android.view.SurfaceView;
import android.view.TextureView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.pandora.live.player.LivePlayerBuilder;
import com.ss.ttm.player.AudioProcessor;
import com.ss.video.rtc.demo.basic_module.utils.Utilities;
import com.ss.videoarch.liveplayer.ILiveListener;
import com.ss.videoarch.liveplayer.ILivePlayer;
import com.ss.videoarch.liveplayer.INetworkClient;
import com.ss.videoarch.liveplayer.VideoLiveManager;
import com.ss.videoarch.liveplayer.log.LiveError;
import com.ss.videoarch.liveplayer.model.LiveURL;
import com.volcengine.vertcdemo.liveshare.feature.player.playerevent.PlayStateCompletion;
import com.volcengine.vertcdemo.liveshare.feature.player.playerevent.PlayStateError;
import com.volcengine.vertcdemo.liveshare.feature.player.playerevent.PlayStateFirstFrame;
import com.volcengine.vertcdemo.liveshare.feature.player.playerevent.PlayStatePrepared;
import com.volcengine.vertcdemo.liveshare.feature.player.playerevent.PlayStateResolutionChanged;
import com.volcengine.vertcdemo.liveshare.feature.player.playerevent.PlayerEvent;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.Observable;
import java.util.concurrent.TimeUnit;

import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;

public class LivePlayer extends Observable {
    private static final int RETRY_TIME_LIMIT = 5;

    private static final String TAG = "LivePlayer";
    private final ILivePlayer mLivePlayer;
    private LiveURL mCurrentLiveURL;
    private boolean mAudioMuted;

    public LivePlayer() {
        ILiveListener liveListener = new LiveListenerAdapter() {
            @Override
            public void onError(LiveError liveError) {
                notifyObservers(new PlayStateError(liveError.toString()));
            }

            @Override
            public void onFirstFrame(boolean retry) {
                notifyObservers(new PlayStateFirstFrame(retry));
            }

            @Override
            public void onPrepared() {
                notifyObservers(new PlayStatePrepared(mCurrentLiveURL.mainURL));
            }

            @Override
            public void onCompletion() {
                if (mLivePlayer != null){
                    mLivePlayer.stop();
                }
                notifyObservers(new PlayStateCompletion(mCurrentLiveURL.mainURL));
            }

            @Override
            public void onVideoSizeChanged(int width, int height) {
                notifyObservers(new PlayStateResolutionChanged(width, height));
            }

            @Override
            public void onMonitorLog(JSONObject jsonObject, String s) {
                Log.d(TAG, "onMonitorLog jsonObject:" + jsonObject);
            }
        };
        mLivePlayer = LivePlayerBuilder.newBuilder(Utilities.getApplicationContext())
                .setRetryTimeout(RETRY_TIME_LIMIT)
                .setNetworkClient(new LiveTTSDKHttpClient())//该类的实现可参考demo
                .setForceHttpDns(false)
                .setForceTTNetHttpDns(false)
                .setPlayerType(VideoLiveManager.PLAYER_OWN)// 选择自研或系统播放器
                .setListener(liveListener)
                .build();
    }

    /**
     * 设置播放地址
     *
     * @param url 主播放地址，默认编码格式为h264
     */
    public void setPlayUrl(String url) {
        setPlayUrl(url, null, "{\"VCodec\":\"h264\"}");
    }

    /**
     * 设置播放地址
     *
     * @param mainUrl   主播放地址
     * @param backUpUrl 备份播放地址
     * @param sdkParam  URL所具有的能力集属性，比如编码格式等，例如："{\"VCodec\":\"h264\"}",
     *                  设置正确的编码格式有利于播放器提前初始化对应的解码器
     */
    public void setPlayUrl(@NonNull String mainUrl, @Nullable String backUpUrl, @Nullable String sdkParam) {
        mCurrentLiveURL = new LiveURL(mainUrl, backUpUrl, sdkParam);
        if (mLivePlayer != null) {
            LiveURL[] urls = {mCurrentLiveURL};
            mLivePlayer.setPlayURLs(urls);
        }
    }

    /**
     * 返回当前播放直播的主播放地址
     */
    @Nullable
    public String getPlayUrl() {
        return mCurrentLiveURL == null ? null : mCurrentLiveURL.mainURL;
    }

    public void setRenderView(@NonNull TextureView textureView) {
        textureView.setSurfaceTextureListener(new TextureView.SurfaceTextureListener() {
            @Override
            public void onSurfaceTextureAvailable(SurfaceTexture surfaceTexture, int width, int height) {
                if (mLivePlayer == null) return;
                mLivePlayer.setSurface(new Surface(surfaceTexture));
            }

            @Override
            public void onSurfaceTextureSizeChanged(SurfaceTexture surfaceTexture, int width, int height) {
            }

            @Override
            public boolean onSurfaceTextureDestroyed(SurfaceTexture surfaceTexture) {
                return true;
            }

            @Override
            public void onSurfaceTextureUpdated(SurfaceTexture surfaceTexture) {
            }
        });
    }

    public void setRenderView(@NonNull SurfaceView surfaceView) {
        if (mLivePlayer == null) return;
        mLivePlayer.setSurfaceHolder(surfaceView.getHolder());
    }

    /**
     * 设置音频处理器
     */
    public void setAudioProcessor(@NonNull AudioProcessor audioProcessor) {
        if (mLivePlayer == null) return;
        mLivePlayer.setAudioProcessor(audioProcessor);
    }

    /**
     * 采用硬解码
     */
    public void enableHardwareDecoder() {
        if (mLivePlayer == null) return;
        mLivePlayer.setIntOption(ILivePlayer.LIVE_OPTION_ENABLE_HARDWARE_DECODE, ENABLE);
        mLivePlayer.setIntOption(LIVE_PLAYER_OPTION_H264_HARDWARE_DECODE, ENABLE);
        mLivePlayer.setIntOption(LIVE_PLAYER_OPTION_ASYNC_INIT_CODEC, ENABLE);
    }

    /**
     * 设置屏幕方向
     *
     * @param isLandscape 是否为横屏
     */
    public void setScreenOrientation(boolean isLandscape) {
        if (mLivePlayer == null) return;
        if (!isLandscape) {
            mLivePlayer.setIntOption(LIVE_OPTION_IMAGE_LAYOUT, IMAGE_LAYOUT_ASPECT_FIT);
            return;
        }
        mLivePlayer.setIntOption(LIVE_OPTION_IMAGE_LAYOUT, IMAGE_LAYOUT_ASPECT_FIT);
    }

    public void play() {
        if (mLivePlayer == null) return;
        try {
            mLivePlayer.play();
        } catch (Exception e) {
            Log.d(TAG, "play failed:" + e.getLocalizedMessage());
            notifyObservers(new PlayStateError("Play failed,Please check URL!"));
        }
        muteAudio();
    }

    public void pause() {
        if (mLivePlayer == null) return;
        mLivePlayer.pause();
    }

    public void stop() {
        if (mLivePlayer == null) return;
        mLivePlayer.stop();
    }

    public void reset() {
        if (mLivePlayer == null) return;
        mLivePlayer.reset();
    }

    public void release() {
        if (mLivePlayer == null) return;
        mLivePlayer.release();
        Log.d(TAG, "LivePlayer release");
    }

    public void muteAudio() {
        if (mAudioMuted) return;
        if (mLivePlayer == null) return;
        mLivePlayer.setMute(true);
        mAudioMuted = true;
    }

    public void unMuteAudio() {
        if (!mAudioMuted) return;
        if (mLivePlayer == null) return;
        mLivePlayer.setMute(false);
        mAudioMuted = false;
    }

    public void toggleAudio() {
        if (mLivePlayer == null) return;
        if (mAudioMuted) {
            unMuteAudio();
        } else {
            muteAudio();
        }
    }

    public boolean isPlaying() {
        if (mLivePlayer == null) return false;
        return mLivePlayer.isPlaying();
    }

    public boolean isPausing() {
        if (mLivePlayer == null) return false;
        return mLivePlayer.getLivePlayerState() == VideoLiveManager.LivePlayerState.PAUSED;
    }

    public int getState() {
        if (mLivePlayer == null) {
            return -1;
        }
        VideoLiveManager.PlayerState playerState = mLivePlayer.getPlayerState();
        VideoLiveManager.LivePlayerState livePlayerState = mLivePlayer.getLivePlayerState();
        Log.d(TAG, "getState playerState:" + playerState + ",livePlayerState:" + livePlayerState);
        return 0;
    }

    public void notifyObservers(PlayerEvent event) {
        Log.d(TAG, "notifyObservers event:" + event);
        setChanged();
        super.notifyObservers(event);
    }

    private static class LiveTTSDKHttpClient implements INetworkClient {
        private final OkHttpClient mClient;

        public LiveTTSDKHttpClient() {
            mClient = new OkHttpClient().newBuilder()
                    .connectTimeout(10, TimeUnit.SECONDS)
                    .readTimeout(10, TimeUnit.SECONDS)
                    .writeTimeout(10, TimeUnit.SECONDS)
                    .build();
        }

        @Override
        public Result doRequest(String url, String host) {
            String body = null;
            JSONObject response = null;
            String header = null;
            try {
                Request request = new Request.Builder().url(url).addHeader("host", host).build();
                Response rsp = mClient.newCall(request).execute();
                if (rsp.isSuccessful()) {
                    body = rsp.body().string();
                    header = rsp.headers().toString();
                    response = new JSONObject(body);
                }
            } catch (JSONException e) {
                return Result.newBuilder().setBody(body).setHeader(header).setException(e).build();
            } catch (Exception e) {
                return Result.newBuilder().setException(e).build();
            }
            return Result.newBuilder().setResponse(response).setBody(body).build();
        }

        @Override
        public Result doPost(String s, String s1) {
            return null;
        }
    }

}
