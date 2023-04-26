// Copyright (c) 2023 Beijing Volcano Engine Technology Ltd.
// SPDX-License-Identifier: MIT

package com.volcengine.vertcdemo.liveshare.bean.event;

public class RTCUserJoinEvent {
    public String userId;
    public boolean micOn;

    public RTCUserJoinEvent(String userId, boolean micOn) {
        this.userId = userId;
        this.micOn = micOn;
    }
}
