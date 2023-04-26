// 
// Copyright (c) 2023 Beijing Volcano Engine Technology Ltd.
// SPDX-License-Identifier: MIT
// 

#import "LiveShareRTCManager.h"
#import "LiveShareVideoConfigModel.h"
#import "LiveShareVodAudioManager.h"

@interface LiveShareRTCManager ()<ByteRTCVideoDelegate>

@property (nonatomic, assign) int audioMixingID;
@property (nonatomic, assign) ByteRTCCameraID cameraID;
@property (nonatomic, strong) NSMutableDictionary<NSString *, UIView *> *streamViewDic;
@property (nonatomic, strong) ByteRTCVideoEncoderConfig *videoEncoderConfig;
// RTC / RTS 房间
@property (nonatomic, strong, nullable) ByteRTCRoom *rtcRoom;

@end

@implementation LiveShareRTCManager

+ (LiveShareRTCManager *)shareRtc {
    static LiveShareRTCManager *rtcManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        rtcManager = [[LiveShareRTCManager alloc] init];
    });
    return rtcManager;
}

- (void)configeRTCEngine {
        
    // 设置RTC编码分辨率、帧率、码率。
    self.videoEncoderConfig.width = [LiveShareVideoConfigModel defaultVideoSize].width;
    self.videoEncoderConfig.height = [LiveShareVideoConfigModel defaultVideoSize].height;
    self.videoEncoderConfig.frameRate = [LiveShareVideoConfigModel frameRate];
    self.videoEncoderConfig.maxBitrate = [LiveShareVideoConfigModel maxKbps];
    [self.rtcEngineKit setMaxVideoEncoderConfig:self.videoEncoderConfig];
    // 设置视频镜像
    [self.rtcEngineKit setLocalVideoMirrorType:ByteRTCMirrorTypeRenderAndEncoder];
    
    _cameraID = ByteRTCCameraIDFront;
    _audioMixingID = 3001;
    VodAudioProcessorAudioMixingID = _audioMixingID;
}

- (void)joinRoomWithToken:(NSString *)token
                   roomID:(NSString *)roomID
                      uid:(NSString *)uid {
    // 加入房间，开始连麦，需要申请 AppId 和 Token。
    ByteRTCUserInfo *userInfo = [[ByteRTCUserInfo alloc] init];
    userInfo.userId = uid;
    ByteRTCRoomConfig *config = [[ByteRTCRoomConfig alloc] init];
    config.profile = ByteRTCRoomProfileCommunication;
    config.isAutoPublish = YES;
    config.isAutoSubscribeAudio = YES;
    config.isAutoSubscribeVideo = YES;
    self.rtcRoom = [self.rtcEngineKit createRTCRoom:roomID];
    self.rtcRoom.delegate = self;
    [self.rtcRoom joinRoom:token userInfo:userInfo roomConfig:config];
    
    // 设置用户可见
    [self.rtcRoom setUserVisibility:YES];
    // 设置音频场景类型
    [self.rtcEngineKit setAudioScenario:ByteRTCAudioScenarioCommunication];
    // 设置初始通话音量
    self.recordingVolume = 0.5;
    // 设置初始混音音量
    self.audioMixingVolume = 0.1;
    // 设置初始音频闪避状态
    self.enableAudioDucking = NO;
    // 启用音频信息提示
    ByteRTCAudioPropertiesConfig *reportConfig = [[ByteRTCAudioPropertiesConfig alloc] init];
    reportConfig.interval = 500;
    [self.rtcEngineKit enableAudioPropertiesReport:reportConfig];
}

- (void)leaveRTCRoom {
    // 离开频道
    [self.rtcRoom leaveRoom];
    [self.streamViewDic removeAllObjects];
    [self switchCamera:ByteRTCCameraIDFront];
}

- (void)switchVideoCapture:(BOOL)isStart {
    // 开启/关闭相机采集
    if (isStart) {
        [SystemAuthority authorizationStatusWithType:AuthorizationTypeCamera
                                               block:^(BOOL isAuthorize) {
            if (isAuthorize) {
                [self.rtcEngineKit startVideoCapture];
            }
        }];
    } else {
        [self.rtcEngineKit stopVideoCapture];
    }
}

- (void)switchAudioCapture:(BOOL)isStart {
    // 开启/关闭麦克风采集
    if (isStart) {
        [SystemAuthority authorizationStatusWithType:AuthorizationTypeAudio
                                               block:^(BOOL isAuthorize) {
            if (isAuthorize) {
                [self.rtcEngineKit startAudioCapture];
            }
        }];
    } else {
        [self.rtcEngineKit stopAudioCapture];
    }
}

- (void)publishAudioStream:(BOOL)isPublish {
    // 发布/停止当前房间中麦克风捕获的媒体流。
    if (isPublish) {
        [self.rtcRoom publishStream:ByteRTCMediaStreamTypeAudio];
    } else {
        [self.rtcRoom unpublishStream:ByteRTCMediaStreamTypeAudio];
    }
}

- (void)switchCamera {
    if (self.cameraID == ByteRTCCameraIDFront) {
        self.cameraID = ByteRTCCameraIDBack;
    } else {
        self.cameraID = ByteRTCCameraIDFront;
    }
    // 切换前置/后置摄像头
    [self switchCamera:self.cameraID];
}

#pragma mark - Audio Mixing

- (void)startAudioMixing {
    // 设置一起看分辨率
    self.videoEncoderConfig.width = [LiveShareVideoConfigModel watchingVideoSize].width;
    self.videoEncoderConfig.height = [LiveShareVideoConfigModel watchingVideoSize].height;
    [self.rtcEngineKit setMaxVideoEncoderConfig:self.videoEncoderConfig];
    
    // 开启混音
    ByteRTCAudioMixingManager *manager = [self.rtcEngineKit getAudioMixingManager];
    [manager enableAudioMixingFrame:_audioMixingID type:ByteRTCAudioMixingTypePlayout];
}

- (void)stopAudioMixing {
    // 设置通话分辨率
    self.videoEncoderConfig.width = [LiveShareVideoConfigModel defaultVideoSize].width;
    self.videoEncoderConfig.height = [LiveShareVideoConfigModel defaultVideoSize].height;
    [self.rtcEngineKit setMaxVideoEncoderConfig:self.videoEncoderConfig];
    
    // 关闭混音
    ByteRTCAudioMixingManager *manager = [self.rtcEngineKit getAudioMixingManager];
    [manager disableAudioMixingFrame:_audioMixingID];
}

- (void)setRecordingVolume:(CGFloat)recordingVolume {
    // 调节本地播放的所有远端用户混音后的音量 [0, 1.0]
    _recordingVolume = recordingVolume;
    [self.rtcEngineKit setPlaybackVolume:(int)(recordingVolume*200)];
}

- (void)setAudioMixingVolume:(CGFloat)audioMixingVolume {
    // 调节混音的音量大小[0, 1.0]
    _audioMixingVolume = audioMixingVolume;
    ByteRTCAudioMixingManager *audioMixingManager = [self.rtcEngineKit getAudioMixingManager];
    [audioMixingManager setAudioMixingVolume:_audioMixingID volume:(int)(_audioMixingVolume*100) type:ByteRTCAudioMixingTypePlayout];
}

- (void)setEnableAudioDucking:(BOOL)enableAudioDucking {
    _enableAudioDucking = enableAudioDucking;
    
    // 开启/关闭音频闪避
    [self.rtcEngineKit enablePlaybackDucking:enableAudioDucking];
}

#pragma mark - Render

- (UIView *)getStreamViewWithUid:(NSString *)uid {
    if (IsEmptyStr(uid)) {
        return nil;
    }
    UIView *view = self.streamViewDic[uid];
    return view;
}

- (void)removeStreamViewWithUserID:(NSString *)userID {
    dispatch_queue_async_safe(dispatch_get_main_queue(), (^{
        [self.streamViewDic removeObjectForKey:userID];
    }));
}

- (void)bindCanvasViewWithUid:(NSString *)uid {
    dispatch_queue_async_safe(dispatch_get_main_queue(), (^{
        
        if ([uid isEqualToString:[LocalUserComponent userModel].uid]) {
            UIView *view = [self getStreamViewWithUid:uid];
            if (!view) {
                
                UIView *streamView = [[UIView alloc] init];
                streamView.backgroundColor = [UIColor clearColor];
                ByteRTCVideoCanvas *canvas = [[ByteRTCVideoCanvas alloc] init];
                canvas.renderMode = ByteRTCRenderModeHidden;
                canvas.view = streamView;
                
                [self.rtcEngineKit setLocalVideoCanvas:ByteRTCStreamIndexMain
                                            withCanvas:canvas];
                [self.streamViewDic setValue:streamView forKey:uid];
            }
        } else {
            UIView *remoteRoomView = [self getStreamViewWithUid:uid];
            if (!remoteRoomView) {
                
                remoteRoomView = [[UIView alloc] init];
                remoteRoomView.backgroundColor = [UIColor clearColor];
                ByteRTCVideoCanvas *canvas = [[ByteRTCVideoCanvas alloc] init];
                canvas.renderMode = ByteRTCRenderModeHidden;
                canvas.view = remoteRoomView;
                
                ByteRTCRemoteStreamKey *streamKey = [[ByteRTCRemoteStreamKey alloc] init];
                streamKey.userId = uid;
                streamKey.roomId = self.rtcRoom.getRoomId;
                streamKey.streamIndex = ByteRTCStreamIndexMain;
                
                [self.rtcEngineKit setRemoteVideoCanvas:streamKey
                                             withCanvas:canvas];
                
                [self.streamViewDic setValue:remoteRoomView forKey:uid];
            }
        }
    }));
}

#pragma mark - ByteRTCRoomDelegate

- (void)rtcRoom:(ByteRTCRoom *)rtcRoom onRoomStateChanged:(NSString *)roomId
        withUid:(NSString *)uid
          state:(NSInteger)state
      extraInfo:(NSString *)extraInfo {
    [super rtcRoom:rtcRoom onRoomStateChanged:roomId withUid:uid state:state extraInfo:extraInfo];
    
    dispatch_queue_async_safe(dispatch_get_main_queue(), ^{
        RTCJoinModel *joinModel = [RTCJoinModel modelArrayWithClass:extraInfo state:state roomId:roomId];
        if ([self.delegate respondsToSelector:@selector(liveShareRTCManager:onRoomStateChanged:)]) {
            [self.delegate liveShareRTCManager:self onRoomStateChanged:joinModel];
        }
    });
}

- (void)rtcRoom:(ByteRTCRoom *)rtcRoom onUserJoined:(ByteRTCUserInfo *)userInfo elapsed:(NSInteger)elapsed {
    // 远程可见用户加入房间，或房间不可见用户切换为可见后接收该回调。
    [self bindCanvasViewWithUid:userInfo.userId];
}

#pragma mark - ByteRTCVideoDelegate

- (void)rtcEngine:(ByteRTCVideo *)engine onFirstRemoteVideoFrameDecoded:(ByteRTCRemoteStreamKey *)streamKey withFrameInfo:(ByteRTCVideoFrameInfo *)frameInfo {
    // SDK接收到远端视频流第一帧并解码后接收该回调。
    dispatch_queue_async_safe(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(liveShareRTCManager:onFirstRemoteVideoFrameDecoded:)]) {
            [self.delegate liveShareRTCManager:self onFirstRemoteVideoFrameDecoded:streamKey.userId];
        }
    });
}

- (void)rtcEngine:(ByteRTCVideo *)engine onLocalAudioPropertiesReport:(NSArray<ByteRTCLocalAudioPropertiesInfo *> *)audioPropertiesInfos {
    // 调用 enableAudioPropertiesReport 后，根据设置的 interval 值，你会周期性地收到此回调
    
    NSInteger volume = 0;
    for (ByteRTCLocalAudioPropertiesInfo *info in audioPropertiesInfos) {
        if (info.streamIndex == ByteRTCStreamIndexMain) {
            volume = info.audioPropertiesInfo.linearVolume;
            break;
        }
    }
    dispatch_queue_async_safe(dispatch_get_main_queue(), ^{
        
        if ([self.delegate respondsToSelector:@selector(liveShareRTCManager:onLocalAudioPropertiesReport:)]) {
            [self.delegate liveShareRTCManager:self onLocalAudioPropertiesReport:volume];
        }
    });
    
}

- (void)rtcEngine:(ByteRTCVideo *)engine onRemoteAudioPropertiesReport:(NSArray<ByteRTCRemoteAudioPropertiesInfo *> *)audioPropertiesInfos totalRemoteVolume:(NSInteger)totalRemoteVolume {
    // 远端用户进房后，本地调用 enableAudioPropertiesReport 后，根据设置的 interval 值，本地会周期性地收到此回调
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    for (ByteRTCRemoteAudioPropertiesInfo *info in audioPropertiesInfos) {
        if (info.streamKey.streamIndex == ByteRTCStreamIndexMain) {
            [dict setValue:@(info.audioPropertiesInfo.linearVolume) forKey:info.streamKey.userId];
        }
    }
    
    dispatch_queue_async_safe(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(liveShareRTCManager:onReportRemoteUserAudioVolume:)]) {
            [self.delegate liveShareRTCManager:self onReportRemoteUserAudioVolume:dict];
        }
    });
}

#pragma mark - Private Action

- (void)switchCamera:(ByteRTCCameraID)cameraID {
    if (cameraID == ByteRTCCameraIDFront) {
        [self.rtcEngineKit setLocalVideoMirrorType:ByteRTCMirrorTypeRenderAndEncoder];
    } else {
        [self.rtcEngineKit setLocalVideoMirrorType:ByteRTCMirrorTypeNone];
    }
    [self.rtcEngineKit switchCamera:cameraID];
}

#pragma mark - Getter

- (NSMutableDictionary<NSString *, UIView *> *)streamViewDic {
    if (!_streamViewDic) {
        _streamViewDic = [[NSMutableDictionary alloc] init];
    }
    return _streamViewDic;
}

- (ByteRTCVideoEncoderConfig *)videoEncoderConfig {
    if (!_videoEncoderConfig) {
        _videoEncoderConfig = [[ByteRTCVideoEncoderConfig alloc] init];
        _videoEncoderConfig.encoderPreference = ByteRTCVideoEncoderPreferenceDisabled;
    }
    return _videoEncoderConfig;
}

@end
