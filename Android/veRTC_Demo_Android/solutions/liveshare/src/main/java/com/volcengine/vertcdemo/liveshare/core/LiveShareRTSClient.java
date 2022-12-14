package com.volcengine.vertcdemo.liveshare.core;

import android.widget.Toast;

import androidx.annotation.NonNull;

import com.google.gson.JsonObject;
import com.ss.bytertc.base.utils.NetworkUtils;
import com.ss.bytertc.engine.RTCVideo;
import com.ss.video.rtc.demo.basic_module.utils.AppExecutors;
import com.ss.video.rtc.demo.basic_module.utils.SafeToast;
import com.ss.video.rtc.demo.basic_module.utils.Utilities;
import com.volcengine.vertcdemo.core.SolutionDataManager;
import com.volcengine.vertcdemo.core.eventbus.SolutionDemoEventManager;
import com.volcengine.vertcdemo.core.net.IBroadcastListener;
import com.volcengine.vertcdemo.core.net.IRequestCallback;
import com.volcengine.vertcdemo.core.net.rts.RTSBaseClient;
import com.volcengine.vertcdemo.core.net.rts.RTSBizInform;
import com.volcengine.vertcdemo.core.net.rts.RTSBizResponse;
import com.volcengine.vertcdemo.core.net.rts.RTSInfo;
import com.volcengine.vertcdemo.liveshare.bean.Room;
import com.volcengine.vertcdemo.liveshare.bean.inform.CloseRoomInform;
import com.volcengine.vertcdemo.liveshare.bean.inform.JoinRoomInform;
import com.volcengine.vertcdemo.liveshare.bean.inform.LeaveRoomInform;
import com.volcengine.vertcdemo.liveshare.bean.inform.ReceiveMessageInform;
import com.volcengine.vertcdemo.liveshare.bean.inform.TurnOnOffMicCameraInform;
import com.volcengine.vertcdemo.liveshare.bean.inform.UpdateLiveUrlInform;
import com.volcengine.vertcdemo.liveshare.bean.inform.UpdateRoomSceneInform;
import com.volcengine.vertcdemo.liveshare.bean.response.ClearUserResponse;
import com.volcengine.vertcdemo.liveshare.bean.response.GetUserListResponse;
import com.volcengine.vertcdemo.liveshare.bean.response.JoinRoomResponse;
import com.volcengine.vertcdemo.liveshare.bean.response.JoinShareResponse;
import com.volcengine.vertcdemo.liveshare.bean.response.LeaveShareResponse;
import com.volcengine.vertcdemo.liveshare.bean.response.UpdateUrlResponse;

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
     * ?????????????????????????????????????????????????????????
     */
    public boolean clearUser(String userId, Runnable callback) {
        if (isNetworkDisabled()) {
            return false;
        }
        AppExecutors.networkIO().execute(() -> {
            JsonObject params = getCommonParams(CLEAR_USER, "", userId);
            sendServerMessage(CLEAR_USER, "", params, null, new IRequestCallback<RTSBizResponse>() {
                @Override
                public void onSuccess(RTSBizResponse data) {
                    callback.run();
                }

                @Override
                public void onError(int errorCode, String message) {
                    callback.run();
                }
            });
        });
        return true;
    }

    /**
     * ????????????
     *
     * @param roomId   ?????????
     * @param userId   ??????id
     * @param userName ?????????
     * @param micOn    ?????????????????????
     * @param cameraOn ?????????????????????
     * @param callback ????????????
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
     * ????????????
     *
     * @param roomId ???????????????id
     * @param userId ???????????????id
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
     * ???????????????????????????????????????
     * @param roomId ??????id
     * @param userId ??????????????????id
     * @param callback ??????
     */
    public void getUserList(String roomId, String userId, IRequestCallback<GetUserListResponse> callback) {
        AppExecutors.networkIO().execute(() -> {
            JsonObject params = getCommonParams(GET_USER_LIST, roomId, userId);
            sendServerMessage(GET_USER_LIST, roomId, params, GetUserListResponse.class, callback);
        });
    }

    /**
     * ???????????????
     *
     * @param roomId            ??????id
     * @param userId            ????????????????????????id
     * @param liveUrl           ?????????????????????
     * @param screenOrientation ????????????
     * @param callback          ???????????????????????????
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
     * ???????????????
     *
     * @param roomId   ??????id
     * @param userId   ????????????????????????id
     * @param callback ???????????????????????????
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
     * ?????????????????????
     *
     * @param roomId            ??????id
     * @param userId            ????????????????????????id
     * @param liveUrl           ???????????????url
     * @param screenOrientation ????????????????????????????????????
     * @param callback          ????????????????????????
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
     * ??????????????????????????????
     *
     * @param roomId        ??????id
     * @param userId        ???????????????????????????????????????id
     * @param micOnOrOff    ??????????????????????????????
     * @param cameraOnOrOff ??????????????????????????????
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
     * ????????????????????????
     *
     * @param roomId  ??????id
     * @param userid  ?????????????????????id
     * @param message ??????????????????
     */
    public void sendTextMessage(String roomId, String userid, String message) {
        JsonObject params = getCommonParams(SEND_MESSAGE, roomId, userid);
        params.addProperty("message", message);
        sendServerMessage(SEND_MESSAGE, roomId, params, null, null);
    }

    private JsonObject getCommonParams(String action, String roomId, String userId) {
        JsonObject params = new JsonObject();
        params.addProperty("app_id", mRtmInfo.appId);
        params.addProperty("room_id", roomId);
        params.addProperty("user_id", userId);
        params.addProperty("event_name", action);
        params.addProperty("request_id", UUID.randomUUID().toString());
        params.addProperty("device_id", SolutionDataManager.ins().getDeviceId());
        return params;
    }

    private boolean isNetworkDisabled() {
        if (!NetworkUtils.isNetworkAvailable(Utilities.getApplicationContext())) {
            SafeToast.show(Utilities.getApplicationContext(), "????????????!", Toast.LENGTH_SHORT);
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
        mEventListeners.put(event, new IBroadcastListener<T>() {
            @Override
            public String getEvent() {
                return event;
            }

            @Override
            public Class<T> getDataClass() {
                return infoClazz;
            }

            @Override
            public void onListener(RTSBizInform RTSBizInform) {
                SolutionDemoEventManager.post(RTSBizInform);
            }
        });
    }
}
