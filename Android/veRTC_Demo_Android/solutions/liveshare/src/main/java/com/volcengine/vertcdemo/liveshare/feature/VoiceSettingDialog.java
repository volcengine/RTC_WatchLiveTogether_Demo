package com.volcengine.vertcdemo.liveshare.feature;

import android.app.Dialog;
import android.content.Context;
import android.os.Bundle;
import android.view.Gravity;
import android.view.Window;
import android.view.WindowManager;
import android.widget.SeekBar;

import androidx.annotation.NonNull;
import androidx.lifecycle.Lifecycle;
import androidx.lifecycle.LifecycleEventObserver;

import com.volcengine.vertcdemo.liveshare.bean.AudioConfig;
import com.volcengine.vertcdemo.liveshare.core.LiveShareDataManager;
import com.volcengine.vertcdemo.liveshare.core.LiveShareRTCManger;
import com.volcengine.vertcdemo.liveshare.databinding.DialogLiveShareVoiceSettingBinding;
import com.volcengine.vertcdemo.liveshare.feature.player.VodAudioProcessor;

public class VoiceSettingDialog extends Dialog {
    private DialogLiveShareVoiceSettingBinding mViewBinding;

    private boolean mVoiceDodgeOpening;
    private int mVideoVolume;
    private int mUserVolume;
    private final AudioConfig mAudioConfig;
    private final LiveShareRTCManger mLiveShareRTCManager;

    public VoiceSettingDialog(@NonNull Context context, Lifecycle lifecycle) {
        super(context);
        LiveShareDataManager liveShareDataManager = LiveShareDataManager.getInstance();
        mLiveShareRTCManager = liveShareDataManager.getRTCManager();
        mAudioConfig = liveShareDataManager.getAudioConfig();
        mVoiceDodgeOpening = mAudioConfig.isVoiceDodgeOpening();
        mVideoVolume = mAudioConfig.getVideoVolume();
        mUserVolume = mAudioConfig.getUserVolume();
        lifecycle.addObserver((LifecycleEventObserver) (source, event) -> {
            if (event == Lifecycle.Event.ON_DESTROY) {
                dismiss();
            }
        });
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        mViewBinding = DialogLiveShareVoiceSettingBinding.inflate(getLayoutInflater());
        setContentView(mViewBinding.getRoot());
        setLayout();
        initView();
    }

    private void setLayout() {
        Window window = getWindow();
        window.setBackgroundDrawableResource(android.R.color.transparent);
        window.setLayout(WindowManager.LayoutParams.MATCH_PARENT, WindowManager.LayoutParams.WRAP_CONTENT);
        window.setGravity(Gravity.BOTTOM);
        window.setDimAmount(0);
    }

    private void initView() {
        mViewBinding.videoVolumeSeekbar.setMax(200);
        mViewBinding.userVolumeSeekbar.setMax(200);
        mViewBinding.videoVolumeProgress.setText(String.valueOf(mVideoVolume));
        mViewBinding.userVolumeProgress.setText(String.valueOf(mUserVolume));
        onVideoVolumeProgressChanged(mVideoVolume);
        onUserVolumeProgressChanged(mUserVolume);
        mViewBinding.voiceDodgeSwitch.setChecked(mVoiceDodgeOpening);
        mViewBinding.voiceDodgeSwitch.setOnCheckedChangeListener((buttonView, isChecked) -> {
            mVoiceDodgeOpening = isChecked;
            mAudioConfig.setVoiceDodgeOpening(isChecked);
            mLiveShareRTCManager.enablePlaybackDucking(mVoiceDodgeOpening);
        });
        SeekBar.OnSeekBarChangeListener seekBarChangeListener = new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                if (!fromUser) return;
                if (seekBar == mViewBinding.videoVolumeSeekbar) {
                    onVideoVolumeProgressChanged(progress);
                } else if (seekBar == mViewBinding.userVolumeSeekbar) {
                    onUserVolumeProgressChanged(progress);
                }
            }

            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {

            }

            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {

            }
        };
        mViewBinding.videoVolumeSeekbar.setOnSeekBarChangeListener(seekBarChangeListener);
        mViewBinding.userVolumeSeekbar.setOnSeekBarChangeListener(seekBarChangeListener);
    }

    private void onVideoVolumeProgressChanged(int progress) {
        mVideoVolume = progress;
        mViewBinding.videoVolumeProgress.setText(String.valueOf(progress));
        mViewBinding.videoVolumeSeekbar.setProgress(progress);
        mAudioConfig.setVideoVolume(progress);
        VodAudioProcessor.mixAudioGain = progress;
    }

    private void onUserVolumeProgressChanged(int progress) {
        mUserVolume = progress;
        mViewBinding.userVolumeProgress.setText(String.valueOf(progress));
        mViewBinding.userVolumeSeekbar.setProgress(progress);
        mAudioConfig.setUserVolume(progress);
        mLiveShareRTCManager.adjustUserVolume(progress);
    }
}
