// Copyright (c) 2023 Beijing Volcano Engine Technology Ltd.
// SPDX-License-Identifier: MIT

package com.volcengine.vertcdemo.liveshare.feature.player.playerevent;

public class PlayStateError implements PlayerEvent {
    public String message;

    public PlayStateError(String message) {
        this.message = message;
    }

    @Override
    public int code() {
        return State.ERROR;
    }
}
