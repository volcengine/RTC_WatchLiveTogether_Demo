// Copyright (c) 2023 Beijing Volcano Engine Technology Ltd.
// SPDX-License-Identifier: MIT

package com.volcengine.vertcdemo.liveshare.feature;

import android.app.Activity;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.text.TextUtils;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import com.ss.bytertc.engine.RTCVideo;
import com.volcengine.vertcdemo.common.SolutionToast;
import com.volcengine.vertcdemo.core.net.ErrorTool;
import com.volcengine.vertcdemo.core.net.IRequestCallback;
import com.volcengine.vertcdemo.liveshare.R;
import com.volcengine.vertcdemo.liveshare.bean.AudioConfig;
import com.volcengine.vertcdemo.liveshare.bean.Room;
import com.volcengine.vertcdemo.liveshare.bean.response.JoinShareResponse;
import com.volcengine.vertcdemo.liveshare.bean.response.UpdateUrlResponse;
import com.volcengine.vertcdemo.liveshare.core.LiveShareDataManager;
import com.volcengine.vertcdemo.liveshare.core.LiveShareRTCManger;
import com.volcengine.vertcdemo.liveshare.core.LiveShareRTSClient;
import com.volcengine.vertcdemo.liveshare.databinding.FragmentLiveShareBinding;
import com.volcengine.vertcdemo.liveshare.feature.player.VideoAudioProcessor;
import com.volcengine.vertcdemo.liveshare.feature.player.VideoView;
import com.volcengine.vertcdemo.liveshare.feature.player.VodAudioProcessor;
import com.volcengine.vertcdemo.liveshare.feature.player.playerevent.PlayStateCompletion;
import com.volcengine.vertcdemo.liveshare.feature.player.playerevent.PlayStateError;
import com.volcengine.vertcdemo.liveshare.feature.player.playerevent.PlayStateFirstFrame;

import java.util.Observer;
import java.util.concurrent.TimeUnit;

public class LiveFragment extends Fragment {
    public static final String ROOM_ID = "room_id";
    public static final String SELF_UID = "self_uid";
    public static final String HOST_UID = "host_uid";
    public static final String LIVE_URL = "live_url";
    public static final String SCREEN_ORIENTATION = "screen_orientation";

    private String mRoomId;
    private String mSelfUid;
    private String mHostUid;
    private String mLiveUrl;
    private int mTargetScreenOrientation = Room.SCREEN_ORIENTATION_PORTRAIT;
    private Observer mPlayEventListener;
    private ShareFailedListener mParseFailedListener;

    private VideoView mVideoView;
    private ParseUrlDialog mParseUrlDialog;
    private Activity mHostActivity;
    private boolean mFirstPlay = true;
    private final Handler mHandler = new Handler(Looper.getMainLooper());
    private final Runnable mParseTimeoutTask = () -> {
        if (mParseUrlDialog != null && mParseUrlDialog.isShowing()) {
            mParseUrlDialog.showParseFailed();
        }
    };

    public void updateVideoUrl(@NonNull String url, @Room.SCREEN_ORIENTATION int screenOrientation) {
        mLiveUrl = url;
        mVideoView.updateLiveUrl(url);
        mVideoView.enableFullScreen(screenOrientation == Room.SCREEN_ORIENTATION_LANDSCAPE);
        mTargetScreenOrientation = screenOrientation;
        showParseUrlDialog();
        if (!mFirstPlay) {
            syncPlayAction();
        }
    }

    public void setPlayEventListener(Observer observer) {
        mPlayEventListener = observer;
    }

    public void setParseFailedListener(ShareFailedListener listener) {
        mParseFailedListener = listener;
    }

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        mHostActivity = getActivity();
        Bundle args = getArguments();
        mRoomId = args == null ? null : args.getString(ROOM_ID);
        mSelfUid = args == null ? null : args.getString(SELF_UID);
        mHostUid = args == null ? null : args.getString(HOST_UID);
        mLiveUrl = args == null ? null : args.getString(LIVE_URL);
        mTargetScreenOrientation = args == null ? -1 : args.getInt(SCREEN_ORIENTATION);
        showParseUrlDialog();
    }

    @Nullable
    @Override
    public View onCreateView(@NonNull final LayoutInflater inflater, @Nullable final ViewGroup container, @Nullable final Bundle savedInstanceState) {
        FragmentLiveShareBinding shareViewBinding = FragmentLiveShareBinding.inflate(getLayoutInflater());
        mVideoView = shareViewBinding.videoViewVv;
        mVideoView.setFullScreenContainer(shareViewBinding.videoContainerFl);
        mVideoView.enableFullScreen(mTargetScreenOrientation == Room.SCREEN_ORIENTATION_LANDSCAPE);
        mVideoView.addPlayEventListener((observer, playEvent) -> {
            if (playEvent instanceof PlayStateError) {
                if (mParseUrlDialog != null) {
                    mParseUrlDialog.showParseFailed();
                }
                mVideoView.stop();
            } else if (playEvent instanceof PlayStateFirstFrame) {
                mHandler.removeCallbacks(mParseTimeoutTask);
                if (mParseUrlDialog != null) {
                    mParseUrlDialog.dismiss();
                }
                if (mFirstPlay) {
                    syncPlayAction();
                }
            } else if (playEvent instanceof PlayStateCompletion) {
                if (TextUtils.equals(mSelfUid, mHostUid)) {
                    SolutionToast.show(R.string.live_ended_please_enter_new);
                }
                mVideoView.stop();
            }
            if (mPlayEventListener != null) {
                mPlayEventListener.update(observer, playEvent);
            }
        });
        RTCVideo rtcVideo = LiveShareRTCManger.ins().getRTCEngine();
        VideoAudioProcessor audioProcessor = new VideoAudioProcessor(rtcVideo);
        AudioConfig audioConfig = LiveShareDataManager.getInstance().getAudioConfig();
        VodAudioProcessor.mixAudioGain = audioConfig.getVideoVolume();
        mVideoView.setAudioProcessor(audioProcessor);
        return shareViewBinding.getRoot();
    }

    /**
     * 向观众同步播放直播的动作
     */
    private void syncPlayAction() {
        LiveShareRTSClient mRTSClient = LiveShareDataManager.getInstance().getRTSClient();
        //观众不需要同步
        if (TextUtils.isEmpty(mSelfUid) || !TextUtils.equals(mSelfUid, mHostUid)) {
            return;
        }
        if (mFirstPlay) {//首次播放通知观众进入一起看
            mRTSClient.joinLiveShare(mRoomId, mSelfUid, mLiveUrl, mTargetScreenOrientation,
                    new IRequestCallback<JoinShareResponse>() {

                        @Override
                        public void onSuccess(JoinShareResponse data) {
                            mFirstPlay = false;
                        }

                        @Override
                        public void onError(int errorCode, String message) {
                            if (errorCode == 649) {
                                if (mParseUrlDialog != null) {
                                    mParseUrlDialog.dismiss();
                                }
                                mParseUrlDialog = new ParseUrlDialog(mHostActivity, getLifecycle(), dialog -> {
                                    if (dialog == mParseUrlDialog) {
                                        mParseUrlDialog = null;
                                    }
                                });
                                mParseUrlDialog.setFailedListener(() -> {
                                    if (mParseFailedListener != null) {
                                        mParseFailedListener.onParseFailed(mFirstPlay);
                                    }
                                });
                                mParseUrlDialog.show();
                                mParseUrlDialog.showParseFailed(getString(R.string.url_only_use_once_a_day));
                                return;
                            }
                            SolutionToast.show(ErrorTool.getErrorMessageByErrorCode(errorCode, message));
                        }
                    });
        } else {//非首次播放通知观众更新直播URL
            mRTSClient.updateLiveUrl(mRoomId, mSelfUid, mLiveUrl, mTargetScreenOrientation,
                    new IRequestCallback<UpdateUrlResponse>() {
                        @Override
                        public void onSuccess(UpdateUrlResponse data) {

                        }

                        @Override
                        public void onError(int errorCode, String message) {
                            SolutionToast.show(ErrorTool.getErrorMessageByErrorCode(errorCode, message));
                        }
                    });
        }
    }

    @Override
    public void onViewCreated(@NonNull final View view, @Nullable final Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        if (!TextUtils.isEmpty(mLiveUrl)) {
            mVideoView.setLiveUrl(mLiveUrl);
            mVideoView.play();
        }
    }

    private void showParseUrlDialog() {
        if (!TextUtils.equals(mSelfUid, mHostUid)) {
            return;
        }
        mHandler.postDelayed(mParseTimeoutTask, TimeUnit.SECONDS.toMillis(30));
        if (mParseUrlDialog != null) {
            mParseUrlDialog.dismiss();
        }
        mParseUrlDialog = new ParseUrlDialog(mHostActivity, getLifecycle(),
                dialog -> {
                    if (dialog == mParseUrlDialog) {
                        mParseUrlDialog = null;
                    }
                });
        mParseUrlDialog.setCancelListener(() -> {
            if (mParseFailedListener != null) {
                mParseFailedListener.onParseFailed(mFirstPlay);
            }
        });
        mParseUrlDialog.setFailedListener(() -> {
            if (mParseFailedListener != null) {
                mParseFailedListener.onParseFailed(mFirstPlay);
            }
        });
        mParseUrlDialog.show();
    }

    @Override
    public void onResume() {
        super.onResume();
        if (mVideoView.isPausing()) {
            mVideoView.play();
        }
    }

    @Override
    public void onPause() {
        super.onPause();
        if (mVideoView.isPlaying()) {
            mVideoView.pause();
        }
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        mVideoView.release();
        if (mVideoView.isFullScreen()) {
            mVideoView.exitFullScreen();
        }
    }

    /**
     * 分享直播失败监听接口
     */
    public interface ShareFailedListener {
        /**
         * 是不是第一次成功播放
         *
         * @param isFirstPlay 是不是第一次成功播放
         */
        void onParseFailed(boolean isFirstPlay);
    }
}
