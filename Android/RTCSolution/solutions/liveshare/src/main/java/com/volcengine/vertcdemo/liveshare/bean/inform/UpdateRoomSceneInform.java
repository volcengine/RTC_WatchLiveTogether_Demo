// Copyright (c) 2023 Beijing Volcano Engine Technology Ltd.
// SPDX-License-Identifier: MIT

package com.volcengine.vertcdemo.liveshare.bean.inform;

import com.google.gson.annotations.SerializedName;
import com.volcengine.vertcdemo.core.net.rts.RTSBizInform;

public class UpdateRoomSceneInform implements RTSBizInform {
    @SerializedName("room_id")
    public String roomId;
    @SerializedName("room_scene")
    public int roomScene;
    @SerializedName("user_id")
    public String userId;
    @SerializedName("url")
    public String url;
    @SerializedName("compose")
    public int screenOrientation;

    @Override
    public String toString() {
        return "UpdateRoomSceneInform{" +
                "roomId='" + roomId + '\'' +
                ", roomScene=" + roomScene +
                ", userId='" + userId + '\'' +
                ", url='" + url + '\'' +
                ", screenOrientation='" + screenOrientation + '\'' +
                '}';
    }
}
