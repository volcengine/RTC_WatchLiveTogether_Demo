// Copyright (c) 2023 Beijing Volcano Engine Technology Ltd.
// SPDX-License-Identifier: MIT

package com.volcengine.vertcdemo.liveshare.feature.player;

import android.content.Context;
import android.graphics.drawable.Drawable;
import android.text.TextUtils;
import android.util.AttributeSet;
import android.util.Log;
import android.view.Gravity;
import android.view.SurfaceView;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.content.ContextCompat;

import com.ss.ttm.player.AudioProcessor;
import com.volcengine.vertcdemo.utils.Utils;
import com.volcengine.vertcdemo.liveshare.R;
import com.volcengine.vertcdemo.liveshare.feature.player.playerevent.PlayStateEnterFullScreen;
import com.volcengine.vertcdemo.liveshare.feature.player.playerevent.PlayStateError;
import com.volcengine.vertcdemo.liveshare.feature.player.playerevent.PlayStateExitFullScreen;
import com.volcengine.vertcdemo.liveshare.feature.player.playerevent.PlayStateResolutionChanged;
import com.volcengine.vertcdemo.liveshare.utils.Util;
import com.volcengine.vertcdemo.utils.DebounceClickListener;

import java.util.Observable;
import java.util.Observer;

public class VideoView extends FrameLayout implements Observer {
    private static final String TAG = "VideoView";
    private LivePlayer mLivePlayer;
    private DisplayModeHelper mDisplayModeHelper;
    private FullScreenHelper mFullScreenHelper;
    private TextView mEnterFullScreenBtn;
    private ImageView mExitFullScreenBtn;
    private SurfaceView mVideoRenderView;
    private FrameLayout mFullScreenContainer;

    public VideoView(@NonNull Context context) {
        this(context, null);
    }

    public VideoView(@NonNull Context context, @Nullable AttributeSet attrs) {
        this(context, attrs, 0);
    }

    public VideoView(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        init();
    }

    private void init() {
        mVideoRenderView = new SurfaceView(getContext());
        addView(mVideoRenderView, new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));

        mExitFullScreenBtn = new ImageView(getContext());
        mExitFullScreenBtn.setImageResource(R.drawable.ic_back_white);
        mExitFullScreenBtn.setOnClickListener(DebounceClickListener.create(v -> exitFullScreen()));
        FrameLayout.LayoutParams exitFullScreenLp = new FrameLayout.LayoutParams(FrameLayout.LayoutParams.WRAP_CONTENT, FrameLayout.LayoutParams.WRAP_CONTENT);
        exitFullScreenLp.gravity = Gravity.START | Gravity.TOP;
        exitFullScreenLp.leftMargin = Util.dp2px(20);
        exitFullScreenLp.topMargin = Util.dp2px(20);
        addView(mExitFullScreenBtn, exitFullScreenLp);
        mExitFullScreenBtn.setVisibility(GONE);

        mEnterFullScreenBtn = new TextView(getContext());
        mEnterFullScreenBtn.setText(R.string.active_full_screen_mode);
        mEnterFullScreenBtn.setTextColor(ContextCompat.getColor(getContext(), R.color.white));
        mEnterFullScreenBtn.setTextSize(Util.sp2px(getContext(), 3));
        Drawable drawable = ContextCompat.getDrawable(getContext(), R.drawable.ic_screen_landscape_selected);
        if (drawable != null) {
            drawable.setBounds(0, 0, (int) Utils.dp2Px(16), (int) Utils.dp2Px(16));
            mEnterFullScreenBtn.setCompoundDrawables(drawable, null, null, null);
            mEnterFullScreenBtn.setCompoundDrawablePadding(Util.dp2px(2));
        }
        mEnterFullScreenBtn.setOnClickListener(DebounceClickListener.create(v -> enterFullScreen()));
        mEnterFullScreenBtn.setBackground(ContextCompat.getDrawable(getContext(), R.drawable.bg_enter_full_screen_btn));
        FrameLayout.LayoutParams enterFullScreenLp = new FrameLayout.LayoutParams(FrameLayout.LayoutParams.WRAP_CONTENT, FrameLayout.LayoutParams.WRAP_CONTENT);
        enterFullScreenLp.gravity = Gravity.BOTTOM | Gravity.END;
        enterFullScreenLp.rightMargin = Util.dp2px(10);
        enterFullScreenLp.bottomMargin = Util.dp2px(260);
        mEnterFullScreenBtn.setPadding(Util.dp2px(6), Util.dp2px(4), Util.dp2px(6), Util.dp2px(4));
        mEnterFullScreenBtn.setGravity(Gravity.CENTER_VERTICAL);
        addView(mEnterFullScreenBtn, enterFullScreenLp);
        mEnterFullScreenBtn.setVisibility(mFullScreenContainer != null ? VISIBLE : GONE);

        mFullScreenHelper = new FullScreenHelper(this);

        mDisplayModeHelper = new DisplayModeHelper();
        mDisplayModeHelper.setContainerView(this);
        mDisplayModeHelper.setDisplayView(mVideoRenderView);
        mDisplayModeHelper.setDisplayMode(DisplayModeHelper.DISPLAY_MODE_ASPECT_FIT);

        mLivePlayer = new LivePlayer();
        mLivePlayer.enableHardwareDecoder();
        mLivePlayer.addObserver(this);
        mLivePlayer.setRenderView(mVideoRenderView);
    }

    /**
     * 设置全屏时视频容器
     *
     * @param fullScreenContainer 全屏时视频容器
     */
    public void setFullScreenContainer(@NonNull FrameLayout fullScreenContainer) {
        mFullScreenContainer = fullScreenContainer;
        mEnterFullScreenBtn.setVisibility(VISIBLE);
        mFullScreenHelper.setFullScreenContainer(mFullScreenContainer);
    }

    /**
     * 设置音频处理器
     */
    public void setAudioProcessor(@NonNull AudioProcessor audioProcessor) {
        mLivePlayer.setAudioProcessor(audioProcessor);
    }

    /**
     * 设置直播网址
     */
    public void setLiveUrl(String liveUrl) {
        if (TextUtils.isEmpty(liveUrl)) {
            return;
        }
        mLivePlayer.setPlayUrl(liveUrl);
    }

    /**
     * 更新播放地址
     *
     * @param newLiveUrl 新的拉流地址
     */
    public void updateLiveUrl(String newLiveUrl) {
        if (TextUtils.isEmpty(newLiveUrl)) {
            return;
        }
        mLivePlayer.stop();
        mLivePlayer.setPlayUrl(newLiveUrl);
        mLivePlayer.play();
    }

    /**
     * 开始播放
     */
    public void play() {
        mLivePlayer.play();
    }

    /**
     * 暂停播放
     */
    public void pause() {
        mLivePlayer.pause();
    }

    /**
     * 停止播放
     */
    public void stop() {
        mLivePlayer.stop();
    }

    /**
     * 释放播放器
     */
    public void release() {
        mLivePlayer.release();
    }

    /**
     * 获取当前播放地址
     */
    public String getLiveUrl() {
        return mLivePlayer.getPlayUrl();
    }

    /**
     * 增加播放事件监听
     */
    public void addPlayEventListener(Observer observer) {
        mLivePlayer.addObserver(observer);
    }

    /**
     * 移除播放事件监听
     */
    public void removePlayEventListener(Observer observer) {
        mLivePlayer.deleteObserver(observer);
    }

    /**
     * 展示/隐藏全屏功能按钮
     */
    public void enableFullScreen(boolean enable) {
        if (isFullScreen()) {
            exitFullScreen();
        }

        mEnterFullScreenBtn.setVisibility(enable ? VISIBLE : GONE);
    }

    /**
     * 当前是否处于全屏状态
     */
    public boolean isFullScreen() {
        return mFullScreenHelper != null && mFullScreenHelper.isInFullScreen();
    }

    /**
     * 进入全屏
     */
    public void enterFullScreen() {
        if (mFullScreenContainer == null) {
            return;
        }
        mEnterFullScreenBtn.setVisibility(GONE);
        mExitFullScreenBtn.setVisibility(VISIBLE);
        if (mFullScreenHelper != null) {
            mFullScreenHelper.enterFullScreen(getContext());
        }
        mLivePlayer.setScreenOrientation(true);
        mLivePlayer.notifyObservers(new PlayStateEnterFullScreen());
        mDisplayModeHelper.apply();
    }

    /**
     * 退出全屏
     */
    public void exitFullScreen() {
        mEnterFullScreenBtn.setVisibility(VISIBLE);
        mExitFullScreenBtn.setVisibility(GONE);
        mFullScreenHelper.exitFullScreen(getContext());
        mLivePlayer.setScreenOrientation(false);
        mLivePlayer.notifyObservers(new PlayStateExitFullScreen());
        mDisplayModeHelper.apply();
    }

    /**
     * 是否正在播放
     */
    public boolean isPlaying() {
        return mLivePlayer.isPlaying();
    }

    /**
     * 是否播放暂停中
     */
    public boolean isPausing() {
        return mLivePlayer.isPausing();
    }

    public SurfaceView getVideoRenderView() {
        return mVideoRenderView;
    }

    @Override
    public void update(Observable o, Object arg) {
        if (arg instanceof PlayStateResolutionChanged) {
            PlayStateResolutionChanged resolution = (PlayStateResolutionChanged) arg;
            mDisplayModeHelper.setVideoSize(resolution.width, resolution.height);
        } else if (arg instanceof PlayStateError) {
            Log.e(TAG, "play failed:" + ((PlayStateError) arg).message);
        }
    }
}
