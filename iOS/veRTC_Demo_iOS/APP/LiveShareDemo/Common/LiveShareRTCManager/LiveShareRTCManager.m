//
//  LiveShareRTCManager.m
//  veRTC_Demo
//
//

#import "LiveShareRTCManager.h"
#import "SystemAuthority.h"
#import "LiveShareVideoConfig.h"
#import <WatchBase/VodAudioProcessor.h>

@interface LiveShareRTCManager ()<ByteRTCVideoDelegate>

@property (nonatomic, assign) int audioMixingID;
@property (nonatomic, assign) ByteRTCCameraID cameraID;
@property (nonatomic, strong) NSMutableDictionary<NSString *, UIView *> *streamViewDic;
@property (nonatomic, strong) ByteRTCVideoEncoderConfig *videoEncoderConfig;


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

#pragma mark - Publish Action

- (void)configeRTCEngine {
        
    // Encoder config
    self.videoEncoderConfig.width = [LiveShareVideoConfig defaultVideoSize].width;
    self.videoEncoderConfig.height = [LiveShareVideoConfig defaultVideoSize].height;
    self.videoEncoderConfig.frameRate = [LiveShareVideoConfig frameRate];
    self.videoEncoderConfig.maxBitrate = [LiveShareVideoConfig maxKbps];
    [self.rtcEngineKit SetMaxVideoEncoderConfig:self.videoEncoderConfig];
    
    //设置视频镜像
    [self.rtcEngineKit setLocalVideoMirrorType:ByteRTCMirrorTypeRenderAndEncoder];
    
    _cameraID = ByteRTCCameraIDFront;

    _audioMixingID = 3001;
    VodAudioProcessorAudioMixingID = _audioMixingID;
}

- (void)joinChannelWithToken:(NSString *)token roomID:(NSString *)roomID uid:(NSString *)uid {
    // 加入房间，开始连麦,需要申请 AppId 和 Token
    // Join the room, start connecting the microphone, you need to apply for AppId and Token
    ByteRTCUserInfo *userInfo = [[ByteRTCUserInfo alloc] init];
    userInfo.userId = uid;
    ByteRTCRoomConfig *config = [[ByteRTCRoomConfig alloc] init];
    config.profile = ByteRTCRoomProfileCommunication;
    config.isAutoPublish = YES;
    config.isAutoSubscribeAudio = YES;
    config.isAutoSubscribeVideo = YES;
    self.rtcRoom = [self.rtcEngineKit createRTCRoom:roomID];
    self.rtcRoom.delegate = self;
    [self.rtcRoom joinRoomByToken:token userInfo:userInfo roomConfig:config];
    
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

- (void)startAudioMixing {
    /// 设置一起看分辨率
    self.videoEncoderConfig.width = [LiveShareVideoConfig watchingVideoSize].width;
    self.videoEncoderConfig.height = [LiveShareVideoConfig watchingVideoSize].height;
    [self.rtcEngineKit SetMaxVideoEncoderConfig:self.videoEncoderConfig];
    
    /// 开启混音
    ByteRTCAudioMixingManager *manager = [self.rtcEngineKit getAudioMixingManager];
    [manager enableAudioMixingFrame:_audioMixingID type:ByteRTCAudioMixingTypePlayout];
}

- (void)stopAudioMixing {
    /// 设置通话分辨率
    self.videoEncoderConfig.width = [LiveShareVideoConfig defaultVideoSize].width;
    self.videoEncoderConfig.height = [LiveShareVideoConfig defaultVideoSize].height;
    [self.rtcEngineKit SetMaxVideoEncoderConfig:self.videoEncoderConfig];
    
    /// 关闭混音
    ByteRTCAudioMixingManager *manager = [self.rtcEngineKit getAudioMixingManager];
    [manager disableAudioMixingFrame:_audioMixingID];
}

#pragma mark - rtc method

- (void)enableLocalAudio:(BOOL)enable {
    //开启/关闭 本地音频采集
    //Turn on/off local audio capture
    if (enable) {
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

- (void)enableLocalVideo:(BOOL)enable {
    if (enable) {
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

/**
 * Switch local audio capture
 * @param mute ture:Turn on audio capture false：Turn off audio capture
 */
- (void)muteLocalAudio:(BOOL)mute {
    if (mute) {
        [self.rtcRoom unpublishStream:ByteRTCMediaStreamTypeAudio];
    } else {
        [self.rtcRoom publishStream:ByteRTCMediaStreamTypeAudio];
    }
}

- (void)switchCamera {
    if (self.cameraID == ByteRTCCameraIDFront) {
        self.cameraID = ByteRTCCameraIDBack;
    } else {
        self.cameraID = ByteRTCCameraIDFront;
    }
    [self switchCamera:self.cameraID];
}

- (void)updateCameraID:(BOOL)isFront {
    self.cameraID = isFront ? ByteRTCCameraIDFront : ByteRTCCameraIDBack;
    [self switchCamera:self.cameraID];
}

- (void)switchCamera:(ByteRTCCameraID)cameraID {
    if (cameraID == ByteRTCCameraIDFront) {
        [self.rtcEngineKit setLocalVideoMirrorType:ByteRTCMirrorTypeRenderAndEncoder];
    } else {
        [self.rtcEngineKit setLocalVideoMirrorType:ByteRTCMirrorTypeNone];
    }
    [self.rtcEngineKit switchCamera:cameraID];
}

- (void)setLocalPreView:(UIView *_Nullable)view {
    ByteRTCVideoCanvas *canvas = [[ByteRTCVideoCanvas alloc] init];
    canvas.view = view;
    canvas.renderMode = ByteRTCRenderModeHidden;
    //设置本地视频显示信息
    //Set local video display information
    [self.rtcEngineKit setLocalVideoCanvas:ByteRTCStreamIndexMain withCanvas:canvas];
}

- (void)leaveChannel {
    //离开频道
    //Leave the channel
    [self.rtcRoom leaveRoom];
    [self.streamViewDic removeAllObjects];
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
                streamView.backgroundColor = [UIColor grayColor];
                ByteRTCVideoCanvas *canvas = [[ByteRTCVideoCanvas alloc] init];
                canvas.uid = uid;
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
                remoteRoomView.backgroundColor = [UIColor grayColor];
                ByteRTCVideoCanvas *canvas = [[ByteRTCVideoCanvas alloc] init];
                canvas.uid = uid;
                canvas.renderMode = ByteRTCRenderModeHidden;
                canvas.view = remoteRoomView;
                canvas.roomId = self.rtcRoom.getRoomId;
                [self.rtcEngineKit setRemoteVideoCanvas:canvas.uid
                                        withIndex:ByteRTCStreamIndexMain
                                       withCanvas:canvas];
                
                [self.streamViewDic setValue:remoteRoomView forKey:uid];
            }
        }
    }));
}

#pragma mark - ByteRTCVideoDelegate

- (void)rtcRoom:(ByteRTCRoom *)rtcRoom onUserJoined:(ByteRTCUserInfo *)userInfo elapsed:(NSInteger)elapsed {
    [self bindCanvasViewWithUid:userInfo.userId];
}

- (void)rtcEngine:(ByteRTCVideo *)engine onFirstRemoteVideoFrameDecoded:(ByteRTCRemoteStreamKey *)streamKey withFrameInfo:(ByteRTCVideoFrameInfo *)frameInfo {
    dispatch_queue_async_safe(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(liveShareRTCManager:onFirstRemoteVideoFrameDecoded:)]) {
            [self.delegate liveShareRTCManager:self onFirstRemoteVideoFrameDecoded:streamKey.userId];
        }
    });
}

// 调用 enableAudioPropertiesReport:{@link #ByteRTCEngineKit#enableAudioPropertiesReport:} 后，根据设置的 interval 值，你会周期性地收到此回调
- (void)rtcEngine:(ByteRTCVideo *)engine onLocalAudioPropertiesReport:(NSArray<ByteRTCLocalAudioPropertiesInfo *> *)audioPropertiesInfos {
    
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
// 远端用户进房后，本地调用 enableAudioPropertiesReport:{@link #ByteRTCEngineKit#enableAudioPropertiesReport:} ，根据设置的 interval 值，本地会周期性地收到此回调
- (void)rtcEngine:(ByteRTCVideo *)engine onRemoteAudioPropertiesReport:(NSArray<ByteRTCRemoteAudioPropertiesInfo *> *)audioPropertiesInfos totalRemoteVolume:(NSInteger)totalRemoteVolume {
    
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

#pragma mark - Audio Mixing

/// 调节本地播放的所有远端用户混音后的音量 [0, 1.0]
- (void)setRecordingVolume:(CGFloat)recordingVolume {
    _recordingVolume = recordingVolume;
    [self.rtcEngineKit setPlaybackVolume:(int)(recordingVolume*200)];
}

/// 调节混音的音量大小[0, 1.0]
- (void)setAudioMixingVolume:(CGFloat)audioMixingVolume {
    _audioMixingVolume = audioMixingVolume;
    ByteRTCAudioMixingManager *audioMixingManager = [self.rtcEngineKit getAudioMixingManager];
    [audioMixingManager setAudioMixingVolume:_audioMixingID volume:(int)(_audioMixingVolume*100) type:ByteRTCAudioMixingTypePlayout];
}

- (void)setEnableAudioDucking:(BOOL)enableAudioDucking {
    _enableAudioDucking = enableAudioDucking;
    
    [self.rtcEngineKit enablePlaybackDucking:enableAudioDucking];
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
