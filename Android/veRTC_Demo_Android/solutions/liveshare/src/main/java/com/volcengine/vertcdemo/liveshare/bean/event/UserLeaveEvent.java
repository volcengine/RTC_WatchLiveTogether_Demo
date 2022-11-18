package com.volcengine.vertcdemo.liveshare.bean.event;

public class UserLeaveEvent {
    public String userId;

    public UserLeaveEvent(String userId) {
        this.userId = userId;
    }
}
