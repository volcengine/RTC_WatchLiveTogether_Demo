package com.volcengine.vertcdemo.liveshare.feature.player.playerevent;

public class PlayStateCompletion implements PlayerEvent {

    public String liveUrl;

    public PlayStateCompletion(String liveUrl) {
        this.liveUrl = liveUrl;
    }

    @Override
    public int code() {
        return State.COMPLETED;
    }
}
