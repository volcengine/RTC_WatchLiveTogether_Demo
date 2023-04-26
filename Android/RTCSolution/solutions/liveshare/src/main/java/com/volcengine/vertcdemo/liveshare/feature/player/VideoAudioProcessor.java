// Copyright (c) 2023 Beijing Volcano Engine Technology Ltd.
// SPDX-License-Identifier: MIT

package com.volcengine.vertcdemo.liveshare.feature.player;

import com.ss.bytertc.engine.RTCVideo;
import com.ss.ttm.player.AudioProcessor;

import java.nio.ByteBuffer;

public class VideoAudioProcessor extends AudioProcessor {
    private final VodAudioProcessor processor;

    public VideoAudioProcessor(RTCVideo engine) {
        processor = new VodAudioProcessor(engine);
    }

    @Override
    public void audioOpen(int sampleRate, int channelCount, int duration, int format) {
        processor.audioOpen(sampleRate, channelCount);
    }

    @Override
    public void audioProcess(ByteBuffer[] byteBuffers, int samples, long timestamp) {
        processor.audioProcess(byteBuffers, samples, timestamp);
    }

    @Override
    public void audioClose() {

    }

    @Override
    public void audioRelease(int i) {

    }
}