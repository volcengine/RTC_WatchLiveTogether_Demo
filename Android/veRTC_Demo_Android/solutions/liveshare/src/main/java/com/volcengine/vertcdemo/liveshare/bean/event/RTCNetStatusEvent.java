package com.volcengine.vertcdemo.liveshare.bean.event;

public class RTCNetStatusEvent {
    public boolean unblocked;

    public RTCNetStatusEvent(boolean unblocked) {
        this.unblocked = unblocked;
    }
}
