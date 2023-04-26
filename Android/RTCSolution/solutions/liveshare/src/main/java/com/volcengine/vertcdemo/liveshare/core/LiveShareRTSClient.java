// Copyright (c) 2023 Beijing Volcano Engine Technology Ltd.
// SPDX-License-Identifier: MIT

package com.volcengine.vertcdemo.liveshare.core;

import androidx.annotation.NonNull;

import com.google.gson.JsonObject;
import com.ss.bytertc.base.utils.NetworkUtils;
import com.ss.bytertc.engine.RTCVideo;
import com.volcengine.vertcdemo.common.AbsBroadcast;
import com.volcengine.vertcdemo.common.AppExecutors;
import com.volcengine.vertcdemo.core.SolutionDataManager;
import com.volcengine.vertcdemo.core.eventbus.SolutionDemoEventManager;
import com.volcengine.vertcdemo.core.net.IRequestCallback;
import com.volcengine.vertcdemo.core.net.RequestCallbackAdapter;
import com.volcengine.vertcdemo.core.net.rts.RTSBaseClient;
import com.volcengine.vertcdemo.core.net.rts.RTSBizInform;
import com.volcengine.vertcdemo.core.net.rts.RTSInfo;
import com.volcengine.vertcdemo.liveshare.bean.Room;
import com.volcengine.vertcdemo.liveshare.bean.inform.CloseRoomInform;
import com.volcengine.vertcdemo.liveshare.bean.inform.JoinRoomInform;
import com.volcengine.vertcdemo.liveshare.bean.inform.LeaveRoomInform;
import com.volcengine.vertcdemo.liveshare.bean.inform.ReceiveMessageInform;
import com.volcengine.vertcdemo.liveshare.bean.inform.TurnOnOffMicCameraInform;
import com.volcengine.vertcdemo.liveshare.bean.inform.UpdateLiveUrlInform;
import com.volcengine.vertcdemo.liveshare.bean.inform.UpdateRoomSceneInform;
import com.volcengine.vertcdemo.liveshare.bean.response.GetUserListResponse;
import com.volcengine.vertcdemo.liveshare.bean.response.JoinRoomResponse;
import com.volcengine.vertcdemo.liveshare.bean.response.JoinShareResponse;
import com.volcengine.vertcdemo.liveshare.bean.response.LeaveShareResponse;
import com.volcengine.vertcdemo.liveshare.bean.response.UpdateUrlResponse;
import com.volcengine.vertcdemo.utils.AppUtil;

import java.util.UUID;

public class LiveShareRTSClient extends RTSBaseClient {
    private static final String CLEAR_USER = "twvClearUser";
    private static final String JOIN_ROOM = "twvJoinRoom";
    private static final String LEAVE_ROOM = "twvLeaveRoom";
    private static final String GET_USER_LIST = "twvGetUserList";
    private static final String JOIN_SHARE = "twvJoinTw";
    private static final String SEND_MESSAGE = "twvSendMsg";
    private static final String LEAVE_SHARE = "twvLeaveTw";
    private static final String UPDATE_URL = "twvSetVideoUrl";
    private static final String TURN_ON_OR_OFF_MIC_CAMERA = "twvUpdateMedia";

    public LiveShareRTSClient(@NonNull RTCVideo rtcVideo, @NonNull RTSInfo rtmInfo) {
        super(rtcVideo, rtmInfo);
        initEventListener();
    }


    /**
     * 进入场景清除自己信息防止上次非正常退出
     */
    public boolean clearUser(String userId, Runnable callback) {
        if (isNetworkDisabled()) {
            return false;
        }
        AppExecutors.networkIO().execute(() -> {
            JsonObject params = getCommonParams(CLEAR_USER, "", userId);
            sendServerMessage(CLEAR_USER, "", params, null, RequestCallbackAdapter.create(callback));
        });
        return true;
    }

    /**
     * 业务入房
     *
     * @param roomId   房间号
     * @param userId   用户id
     * @param userName 用户名
     * @param micOn    麦克风是否打开
     * @param cameraOn 摄像头是否打开
     * @param callback 加房回调
     */
    public boolean joinRoom(String roomId,
                            String userId,
                            String userName,
                            boolean micOn,
                            boolean cameraOn,
                            IRequestCallback<JoinRoomResponse> callback) {
        if (isNetworkDisabled()) {
            return false;
        }
        AppExecutors.networkIO().execute(() -> {
            JsonObject params = getCommonParams(JOIN_ROOM, roomId, userId);
            params.addProperty("user_name", userName);
            params.addProperty("mic", micOn ? 1 : 0);
            params.addProperty("camera", cameraOn ? 1 : 0);
            sendServerMessage(JOIN_ROOM, roomId, params, JoinRoomResponse.class, callback);
        });
        return true;
    }

    /**
     * 业务离房
     *
     * @param roomId 离开的房间id
     * @param userId 离房的用户id
     */
    public void leaveRoom(String roomId,
                          String userId) {
        if (isNetworkDisabled()) {
            return;
        }
        AppExecutors.networkIO().execute(() -> {
            JsonObject params = getCommonParams(LEAVE_ROOM, roomId, userId);
            sendServerMessage(LEAVE_ROOM, roomId, params, null, null);
        });
    }

    /**
     * 业务主动获取房间内用户列表
     *
     * @param roomId   房间id
     * @param userId   当前登录用户id
     * @param callback 回调
     */
    public void getUserList(String roomId, String userId, IRequestCallback<GetUserListResponse> callback) {
        AppExecutors.networkIO().execute(() -> {
            JsonObject params = getCommonParams(GET_USER_LIST, roomId, userId);
            sendServerMessage(GET_USER_LIST, roomId, params, GetUserListResponse.class, callback);
        });
    }

    /**
     * 加入一起看
     *
     * @param roomId            房间id
     * @param userId            加入一起看的用户id
     * @param liveUrl           分享的直播连接
     * @param screenOrientation 屏幕方向
     * @param callback          加入一起看请求回调
     */
    public void joinLiveShare(String roomId,
                              String userId,
                              String liveUrl,
                              @Room.SCREEN_ORIENTATION int screenOrientation,
                              IRequestCallback<JoinShareResponse> callback) {
        if (isNetworkDisabled()) {
            return;
        }
        AppExecutors.networkIO().execute(() -> {
            JsonObject params = getCommonParams(JOIN_SHARE, roomId, userId);
            params.addProperty("url", liveUrl);
            params.addProperty("compose", screenOrientation);
            sendServerMessage(JOIN_SHARE, roomId, params, JoinShareResponse.class, callback);
        });
    }

    /**
     * 离开一起看
     *
     * @param roomId   房间id
     * @param userId   离开一起看的用户id
     * @param callback 离开一起看请求回调
     */
    public void leaveLiveShare(String roomId,
                               String userId,
                               IRequestCallback<LeaveShareResponse> callback) {
        if (isNetworkDisabled()) {
            return;
        }
        AppExecutors.networkIO().execute(() -> {
            JsonObject params = getCommonParams(LEAVE_SHARE, roomId, userId);
            sendServerMessage(LEAVE_SHARE, roomId, params, LeaveShareResponse.class, callback);
        });
    }

    /**
     * 更新房间直播源
     *
     * @param roomId            房间id
     * @param userId            改变直播源的用户id
     * @param liveUrl           新的直播源url
     * @param screenOrientation 新的直播源要求的屏幕方向
     * @param callback          更新直播源的回调
     */
    public void updateLiveUrl(String roomId,
                              String userId,
                              String liveUrl,
                              int screenOrientation,
                              IRequestCallback<UpdateUrlResponse> callback) {
        if (isNetworkDisabled()) {
            return;
        }
        AppExecutors.networkIO().execute(() -> {
            JsonObject params = getCommonParams(UPDATE_URL, roomId, userId);
            params.addProperty("url", liveUrl);
            params.addProperty("compose", screenOrientation);
            sendServerMessage(UPDATE_URL, roomId, params, UpdateUrlResponse.class, callback);
        });
    }

    /**
     * 开关麦克风或者摄像头
     *
     * @param roomId        房间id
     * @param userId        开关麦克风或者摄像头的用户id
     * @param micOnOrOff    麦克风是打开还是关闭
     * @param cameraOnOrOff 摄像头是打开还是关闭
     */
    public void turnOnOrOffMicCamera(String roomId,
                                     String userId,
                                     String micOnOrOff,
                                     String cameraOnOrOff) {
        if (isNetworkDisabled()) {
            return;
        }
        AppExecutors.networkIO().execute(() -> {
            JsonObject params = getCommonParams(TURN_ON_OR_OFF_MIC_CAMERA, roomId, userId);
            params.addProperty("mic", micOnOrOff);
            params.addProperty("camera", cameraOnOrOff);
            sendServerMessage(TURN_ON_OR_OFF_MIC_CAMERA, roomId, params, UpdateUrlResponse.class, null);
        });
    }

    /**
     * 发送文字聊天消息
     *
     * @param roomId  房间id
     * @param userid  发送消息的用户id
     * @param message 文字消息内容
     */
    public void sendTextMessage(String roomId, String userid, String message) {
        JsonObject params = getCommonParams(SEND_MESSAGE, roomId, userid);
        params.addProperty("message", message);
        sendServerMessage(SEND_MESSAGE, roomId, params, null, null);
    }

    public void requestReconnect(String roomId, String userId, IRequestCallback<JoinRoomResponse> callback) {
        JsonObject params = getCommonParams(INFORM_RECONNECT, roomId, userId);
        sendServerMessage(INFORM_RECONNECT, roomId, params, JoinRoomResponse.class, callback);
    }

    private JsonObject getCommonParams(String action, String roomId, String userId) {
        JsonObject params = new JsonObject();
        params.addProperty("app_id", mRTSInfo.appId);
        params.addProperty("room_id", roomId);
        params.addProperty("user_id", userId);
        params.addProperty("event_name", action);
        params.addProperty("request_id", UUID.randomUUID().toString());
        params.addProperty("device_id", SolutionDataManager.ins().getDeviceId());
        return params;
    }

    private boolean isNetworkDisabled() {
        if (!NetworkUtils.isNetworkAvailable(AppUtil.getApplicationContext())) {
            return true;
        }
        return false;
    }

    private static final String INFORM_JOIN_ROOM = "twvOnJoinRoom";
    private static final String INFORM_LEAVE_ROOM = "twvOnLeaveRoom";
    private static final String INFORM_UPDATE_ROOM_SCENE = "twvOnUpdateRoomScene";
    private static final String INFORM_UPDATE_LIVE_URL = "twvOnUpdateRoomVideoUrl";
    private static final String INFORM_MIC_CAMERA_TURN_ON_OFF = "twvOnUpdateRoomMedia";
    private static final String INFORM_RECEIVED_MESSAGE = "twvOnSendMessage";
    private static final String INFORM_CLOSE_ROOM = "twvOnCloseRoom";
    private static final String INFORM_RECONNECT = "twvReconnect";

    private void initEventListener() {
        addEventListener(INFORM_JOIN_ROOM, JoinRoomInform.class);
        addEventListener(INFORM_LEAVE_ROOM, LeaveRoomInform.class);
        addEventListener(INFORM_UPDATE_ROOM_SCENE, UpdateRoomSceneInform.class);
        addEventListener(INFORM_UPDATE_LIVE_URL, UpdateLiveUrlInform.class);
        addEventListener(INFORM_MIC_CAMERA_TURN_ON_OFF, TurnOnOffMicCameraInform.class);
        addEventListener(INFORM_RECEIVED_MESSAGE, ReceiveMessageInform.class);
        addEventListener(INFORM_CLOSE_ROOM, CloseRoomInform.class);
    }

    private <T extends RTSBizInform> void addEventListener(String event, Class<T> infoClazz) {
        mEventListeners.put(event, new AbsBroadcast<T>(event, infoClazz, SolutionDemoEventManager::post));
    }
}
