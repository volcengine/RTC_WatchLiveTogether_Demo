package com.volcengine.vertcdemo.liveshare.feature.player.playerevent;

/**
 * 视频分辨率
 */
public class PlayStateResolutionChanged implements PlayerEvent {

    public int width;
    public int height;

    public PlayStateResolutionChanged(int width, int height) {
        this.width = width;
        this.height = height;
    }

    @Override
    public int code() {
        return State.VIDEO_SIZE_CHANGED;
    }
}
