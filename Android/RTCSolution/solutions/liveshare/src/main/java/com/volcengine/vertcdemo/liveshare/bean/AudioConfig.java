// Copyright (c) 2023 Beijing Volcano Engine Technology Ltd.
// SPDX-License-Identifier: MIT

package com.volcengine.vertcdemo.liveshare.bean;

/**
 * 声音相关设置
 */
public class AudioConfig {
    public static final int DEFAULT_VIDEO_VOLUME = 20;
    public static final int DEFAULT_USER_VOLUME = 100;

    /***音频闪避功能是否打开的***/
    private boolean isVoiceDodgeOpening = false;
    /***视频音量***/
    private int mVideoVolume = DEFAULT_VIDEO_VOLUME;
    /***人声音量***/
    private int mUserVolume = DEFAULT_USER_VOLUME;


    public boolean isVoiceDodgeOpening() {
        return isVoiceDodgeOpening;
    }

    public void setVoiceDodgeOpening(boolean voiceDodgeOpening) {
        isVoiceDodgeOpening = voiceDodgeOpening;
    }

    public int getVideoVolume() {
        return mVideoVolume;
    }

    public void setVideoVolume(int mVideoVolume) {
        this.mVideoVolume = mVideoVolume;
    }

    public int getUserVolume() {
        return mUserVolume;
    }

    public void setUserVolume(int mUserVolume) {
        this.mUserVolume = mUserVolume;
    }
}
