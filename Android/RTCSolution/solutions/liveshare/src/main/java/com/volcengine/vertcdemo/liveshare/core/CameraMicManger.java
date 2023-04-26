// Copyright (c) 2023 Beijing Volcano Engine Technology Ltd.
// SPDX-License-Identifier: MIT

package com.volcengine.vertcdemo.liveshare.core;

import com.ss.bytertc.engine.data.CameraId;

import java.util.Observable;

/**
 * 摄像头、麦克风状态管理
 */
public class CameraMicManger extends Observable {
    private boolean mCameraOn = true; // 摄像头状态
    private boolean mMicOn = true; // 麦克风状态
    private CameraId mCameraID = CameraId.CAMERA_ID_FRONT;

    public CameraMicManger() {

    }

    /**
     * 摄像头是否打开
     */
    public boolean isCameraOn() {
        return mCameraOn;
    }

    /**
     * 麦克风是否打开
     */
    public boolean isMicOn() {
        return mMicOn;
    }

    /**
     * 当前摄像头是否为前置摄像头
     */
    public boolean isFrontCamera() {
        return mCameraID == CameraId.CAMERA_ID_FRONT;
    }

    /**
     * 开启麦克风
     */
    public void openMic() {
        mMicOn = true;
        notifyObservers();
    }

    /**
     * 关闭麦克风
     */
    public void closeMic() {
        mMicOn = false;
        notifyObservers();
    }

    /**
     * 开关麦克风
     */
    public void toggleMic() {
        mMicOn = !mMicOn;
        notifyObservers();
    }


    /**
     * 开启摄像头
     */
    public void openCamera() {
        mCameraOn = true;
        notifyObservers();
    }

    /**
     * 开启摄像头
     */
    public void closeCamera() {
        mCameraOn = false;
        notifyObservers();
    }

    /**
     * 开关摄像头
     */
    public void toggleCamera() {
        mCameraOn = !mCameraOn;
        notifyObservers();
    }

    /**
     * 设置前后摄像头
     */
    public void switchCamera(boolean isFront) {
        mCameraID = isFront ? CameraId.CAMERA_ID_FRONT : CameraId.CAMERA_ID_BACK;
        notifyObservers();
    }

    /**
     * 切换前后摄像头
     */
    public void switchCamera() {
        mCameraID = mCameraID == CameraId.CAMERA_ID_BACK ? CameraId.CAMERA_ID_FRONT : CameraId.CAMERA_ID_BACK;
        notifyObservers();
    }

    public void notifyObservers() {
        setChanged();
        super.notifyObservers();
    }
}
