package com.volcengine.vertcdemo.liveshare.bean.inform;

import com.google.gson.annotations.SerializedName;
import com.volcengine.vertcdemo.core.net.rts.RTSBizInform;

public class UpdateLiveUrlInform implements RTSBizInform {
    @SerializedName("room_id")
    public String roomId;
    @SerializedName("user_id")
    public String userId;
    @SerializedName("url")
    public String url;
    @SerializedName("compose")
    public int screenOrientation;

    @Override
    public String toString() {
        return "UpdateLiveUrlInform{" +
                "roomId='" + roomId + '\'' +
                ", userId='" + userId + '\'' +
                ", url='" + url + '\'' +
                ", screenOrientation='" + screenOrientation + '\'' +
                '}';
    }
}
