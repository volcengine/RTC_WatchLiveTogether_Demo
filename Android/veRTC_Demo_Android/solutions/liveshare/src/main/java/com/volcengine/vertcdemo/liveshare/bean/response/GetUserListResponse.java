package com.volcengine.vertcdemo.liveshare.bean.response;

import com.google.gson.annotations.SerializedName;
import com.volcengine.vertcdemo.core.net.rts.RTSBizResponse;
import com.volcengine.vertcdemo.liveshare.bean.User;

import java.util.List;

/**
 * 主动获取房间内用户列表返回
 */
public class GetUserListResponse implements RTSBizResponse {

    @SerializedName("user_list")
    public List<User> userList;
}
