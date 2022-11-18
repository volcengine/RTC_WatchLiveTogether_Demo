package com.volcengine.vertcdemo.liveshare.feature.player.playerevent;

public class PlayStateEnterFullScreen implements PlayerEvent {

    @Override
    public int code() {
        return Action.ENTER_FULL_SCREEN;
    }
}
