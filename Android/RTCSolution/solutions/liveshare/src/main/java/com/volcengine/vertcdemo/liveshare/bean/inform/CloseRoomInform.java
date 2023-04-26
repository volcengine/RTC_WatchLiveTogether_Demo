// Copyright (c) 2023 Beijing Volcano Engine Technology Ltd.
// SPDX-License-Identifier: MIT

package com.volcengine.vertcdemo.liveshare.bean.inform;

import com.google.gson.annotations.SerializedName;
import com.volcengine.vertcdemo.core.net.rts.RTSBizInform;

public class CloseRoomInform implements RTSBizInform {

    public static final int TYPE_HOST_CLOSE = 1;//房主关房
    public static final int TYPE_TIMEOUT = 2;//超时解散
    public static final int TYPE_BY_AUDIT = 3;//审核关房

    @SerializedName("room_id")
    public String roomId;
    @SerializedName("type")
    public int type;
}
