package com.volcengine.vertcdemo.liveshare.bean.inform;

import com.google.gson.annotations.SerializedName;
import com.volcengine.vertcdemo.core.net.rts.RTSBizInform;
import com.volcengine.vertcdemo.liveshare.bean.User;

public class LeaveRoomInform implements RTSBizInform {
    @SerializedName("room_id")
    public String roomId;
    @SerializedName("user")
    public User user;
}
