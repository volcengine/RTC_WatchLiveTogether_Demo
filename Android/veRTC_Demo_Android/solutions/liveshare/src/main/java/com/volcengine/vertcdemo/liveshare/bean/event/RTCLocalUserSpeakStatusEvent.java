package com.volcengine.vertcdemo.liveshare.bean.event;

import androidx.annotation.NonNull;

import com.volcengine.vertcdemo.liveshare.bean.AudioProperty;

import java.util.HashSet;

public class RTCLocalUserSpeakStatusEvent {
    public final HashSet<AudioProperty> userSpeakStatus = new HashSet<>(1);

    public void addAudioProperty(@NonNull AudioProperty property) {
        userSpeakStatus.add(property);
    }
}
