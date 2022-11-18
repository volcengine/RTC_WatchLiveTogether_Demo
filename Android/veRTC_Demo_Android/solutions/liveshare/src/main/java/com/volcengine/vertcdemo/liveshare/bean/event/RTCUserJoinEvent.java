package com.volcengine.vertcdemo.liveshare.bean.event;

public class RTCUserJoinEvent {
    public String userId;
    public boolean micOn;

    public RTCUserJoinEvent(String userId, boolean micOn) {
        this.userId = userId;
        this.micOn = micOn;
    }
}
