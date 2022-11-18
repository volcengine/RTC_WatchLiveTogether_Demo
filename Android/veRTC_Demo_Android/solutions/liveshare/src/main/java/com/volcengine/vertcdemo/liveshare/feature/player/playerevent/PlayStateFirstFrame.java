package com.volcengine.vertcdemo.liveshare.feature.player.playerevent;

public class PlayStateFirstFrame implements PlayerEvent {
    // 首帧回调，代表视频画面开始渲染。isFirstFrame 代表是否是真正意义的首帧
    // 若true，代表是真正的首帧，若false，则是重试得到的首帧
    // 因为在播放过程中重试，会重置播放器，同样需要通过首帧回调告知业务层
    public boolean isRetry;

    public PlayStateFirstFrame(boolean isRetry) {
        this.isRetry = isRetry;
    }

    @Override
    public int code() {
        return State.FIRST_FRAME;
    }
}
