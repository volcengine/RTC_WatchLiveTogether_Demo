package com.volcengine.vertcdemo.liveshare.feature.player;

import com.ss.videoarch.liveplayer.ILiveListener;
import com.ss.videoarch.liveplayer.log.LiveError;

import org.json.JSONObject;

import java.nio.ByteBuffer;

public class LiveListenerAdapter implements ILiveListener {
    // 播放过程中遇到错误会通知给应用
    @Override
    public void onError(LiveError error) {
    }

    // 首帧回调，代表视频画面开始渲染。isFirstFrame 代表是否是真正意义的首帧
    // 若true，代表是真正的首帧，若false，则是重试得到的首帧
    // 因为在播放过程中重试，会重置播放器，同样需要通过首帧回调告知业务层
    @Override
    public void onFirstFrame(boolean isFirstFrame) {
    }

    // 卡顿回调
    @Override
    public void onStallStart() {
    }

    // 卡顿结束回调
    @Override
    public void onStallEnd() {
    }

    // 视频渲染卡顿回调
    @Override
    public void onVideoRenderStall(int stallTime) {
    }

    // 音频渲染卡顿回调
    @Override
    public void onAudioRenderStall(int stallTime) {
    }

    // 播放器prepare回调, 代表播放内容已准备好，即将开始播放
    @Override
    public void onPrepared() {
    }

    @Override
    public void onAbrSwitch(String s) {
    }

    // 播放结束回调，可能是直播结束，也可能是断流
    @Override
    public void onCompletion() {
    }

    // 边播边录时，本地录制文件结束回调
    @Override
    public void onCacheFileCompletion() {
    }

    @Override
    public void onResolutionDegrade(String s) {

    }

    @Override
    public void onTextureRenderDrawFrame() {

    }

    // 视频分辨率回调
    @Override
    public void onVideoSizeChanged(int width, int height) {
    }

    // sei信息回调
    @Override
    public void onSeiUpdate(String message) {
    }

    @Override
    public void onBinarySeiUpdate(ByteBuffer byteBuffer) {

    }

    // 日志信息回调
    @Override
    public void onMonitorLog(JSONObject jsonObject, String s) {
    }

    @Override
    public void onReportALog(int i, String s) {
    }

}
