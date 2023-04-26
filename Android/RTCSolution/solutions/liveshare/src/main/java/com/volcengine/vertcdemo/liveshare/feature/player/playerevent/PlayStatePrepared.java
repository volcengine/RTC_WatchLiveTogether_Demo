// Copyright (c) 2023 Beijing Volcano Engine Technology Ltd.
// SPDX-License-Identifier: MIT

package com.volcengine.vertcdemo.liveshare.feature.player.playerevent;

public class PlayStatePrepared implements PlayerEvent {

    public String liveUrl;

    public PlayStatePrepared(String liveUrl) {
        this.liveUrl = liveUrl;
    }

    @Override
    public int code() {
        return State.PREPARED;
    }
}
