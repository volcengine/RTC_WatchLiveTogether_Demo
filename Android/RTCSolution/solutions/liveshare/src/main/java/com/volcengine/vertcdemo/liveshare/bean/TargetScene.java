// Copyright (c) 2023 Beijing Volcano Engine Technology Ltd.
// SPDX-License-Identifier: MIT

package com.volcengine.vertcdemo.liveshare.bean;

import android.text.TextUtils;
import android.util.Log;

public class TargetScene {
    public String liveUrl = "";
    @Room.SCREEN_ORIENTATION
    public int screenOrientation = Room.SCREEN_ORIENTATION_PORTRAIT;
    @Room.SCENE
    public int scene;

    public TargetScene(@Room.SCENE int scene, String liveUrl, @Room.SCREEN_ORIENTATION int screenOrientation) {
        this.scene = scene;
        if (scene == Room.SCENE_SHARE && TextUtils.isEmpty(liveUrl)) {
            Log.e("TargetScene", "liveUrl don't match Scene!");
        }
        this.liveUrl = liveUrl;
        this.screenOrientation = screenOrientation;
    }

    public TargetScene(@Room.SCENE int scene) {
        this.scene = scene;
    }
}
