package com.volcengine.vertcdemo.liveshare.feature.player;

import android.content.Context;
import android.graphics.drawable.Drawable;
import android.text.TextUtils;
import android.util.AttributeSet;
import android.util.Log;
import android.view.Gravity;
import android.view.TextureView;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.content.ContextCompat;

import com.ss.ttm.player.AudioProcessor;
import com.ss.video.rtc.demo.basic_module.utils.Utilities;
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
    private TextureView mVideoRenderView;
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
        mVideoRenderView = new TextureView(getContext());
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
        mEnterFullScreenBtn.setText(R.string.enter_full_screen);
        mEnterFullScreenBtn.setTextColor(ContextCompat.getColor(getContext(), R.color.white));
        mEnterFullScreenBtn.setTextSize(Util.sp2px(getContext(), 3));
        Drawable drawable = ContextCompat.getDrawable(getContext(), R.drawable.ic_screen_landscape_selected);
        if (drawable != null) {
            drawable.setBounds(0, 0, (int) Utilities.dip2Px(16), (int) Utilities.dip2Px(16));
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
     * ???????????????????????????
     *
     * @param fullScreenContainer ?????????????????????
     */
    public void setFullScreenContainer(@NonNull FrameLayout fullScreenContainer) {
        mFullScreenContainer = fullScreenContainer;
        mEnterFullScreenBtn.setVisibility(VISIBLE);
        mFullScreenHelper.setFullScreenContainer(mFullScreenContainer);
    }

    /**
     * ?????????????????????
     */
    public void setAudioProcessor(@NonNull AudioProcessor audioProcessor) {
        mLivePlayer.setAudioProcessor(audioProcessor);
    }

    /**
     * ??????????????????
     */
    public void setLiveUrl(String liveUrl) {
        if (TextUtils.isEmpty(liveUrl)) {
            return;
        }
        mLivePlayer.setPlayUrl(liveUrl);
    }

    /**
     * ??????????????????
     *
     * @param newLiveUrl ??????????????????
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
     * ????????????
     */
    public void play() {
        mLivePlayer.play();
    }

    /**
     * ????????????
     */
    public void pause() {
        mLivePlayer.pause();
    }

    /**
     * ????????????
     */
    public void stop() {
        mLivePlayer.stop();
    }

    /**
     * ???????????????
     */
    public void release() {
        mLivePlayer.release();
    }

    /**
     * ????????????????????????
     */
    public String getLiveUrl() {
        return mLivePlayer.getPlayUrl();
    }

    /**
     * ????????????????????????
     */
    public void addPlayEventListener(Observer observer) {
        mLivePlayer.addObserver(observer);
    }

    /**
     * ????????????????????????
     */
    public void removePlayEventListener(Observer observer) {
        mLivePlayer.deleteObserver(observer);
    }

    /**
     * ??????/????????????????????????
     */
    public void enableFullScreen(boolean enable) {
        if (isFullScreen()) {
            exitFullScreen();
        }

        mEnterFullScreenBtn.setVisibility(enable ? VISIBLE : GONE);
    }

    /**
     * ??????????????????????????????
     */
    public boolean isFullScreen() {
        return mFullScreenHelper != null && mFullScreenHelper.isInFullScreen();
    }

    /**
     * ????????????
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
     * ????????????
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
     * ??????????????????
     */
    public boolean isPlaying() {
        return mLivePlayer.isPlaying();
    }

    /**
     * ?????????????????????
     */
    public boolean isPausing() {
        return mLivePlayer.isPausing();
    }

    public TextureView getVideoRenderView() {
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
