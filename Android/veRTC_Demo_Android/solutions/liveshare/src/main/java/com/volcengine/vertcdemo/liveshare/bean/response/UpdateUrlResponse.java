package com.volcengine.vertcdemo.liveshare.bean.response;

import com.google.gson.annotations.SerializedName;
import com.volcengine.vertcdemo.core.net.rts.RTSBizResponse;
import com.volcengine.vertcdemo.liveshare.bean.Room;

public class UpdateUrlResponse implements RTSBizResponse {
    @SerializedName("room")
    public Room room;
}
