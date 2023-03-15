//
//  LiveShareVideoComponent.m
//  
//
//

#import "LiveShareVideoComponent.h"
#import <TTSDK/TTVideoLive.h>
#import <TTSDK/TTSDKManager.h>
#import <WatchBase/VodAudioProcessor.h>
#import "LiveShareRTCManager.h"

@interface LiveShareVideoComponent ()<TVLDelegate>

@property (nonatomic, weak) UIView *superView;

@property (nonatomic, strong) TVLManager *tvlManager;
@property (nonatomic, strong) VodAudioProcessor *audioProcesser;

@end

@implementation LiveShareVideoComponent


- (instancetype)initWithSuperview:(UIView *)superView {
    if (self = [super init]) {
        self.superView = superView;
        
        [self addObserver];
        [TVLManager startOpenGLESActivity];
        
        self.tvlManager = [[TVLManager alloc] initWithOwnPlayer:YES];
        self.tvlManager.playerViewScaleMode = TVLViewScalingModeAspectFit;
        self.tvlManager.delegate = self;
        self.tvlManager.hardwareDecode = YES;
        [self.tvlManager setProjectKey:@"veRTCDemo_iOS"];
        
        [superView addSubview:self.tvlManager.playerView];
        [self.tvlManager.playerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(superView);
        }];;
    }
    return self;
}

#pragma mark - observer
- (void)addObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [TVLManager startOpenGLESActivity];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    [TVLManager stopOpenGLESActivity];
}

#pragma mark - TVLDelegate

- (void)recieveError:(NSError *)error {

}

- (void)startRender {

}

- (void)stallStart {

}

- (void)stallEnd {

}

- (void)onStreamDryup:(NSError *)error {

}

- (void)onMonitorLog:(NSDictionary*) event {

}

- (void)loadStateChanged:(NSNumber*)state {

}

- (void)manager:(TVLManager *)manager playerItemStatusDidChange:(TVLPlayerItemStatus)status {
    
    BOOL needCallBack = (status == TVLPlayerItemStatusReadyToRender ||
                         status == TVLPlayerItemStatusFailed ||
                         status == TVLPlayerItemStatusCompleted);
    if (!needCallBack) {
        return;
    }
    
    LiveShareVideoState videoState = LiveShareVideoStateSuccess;
    NSError *error = nil;
    if (status == TVLPlayerItemStatusReadyToRender) {
        
        videoState = LiveShareVideoStateSuccess;
    } else if (status == TVLPlayerItemStatusFailed) {
        
        videoState = LiveShareVideoStateFailure;
        error = manager.error;
        [manager stop];
    } else if (status == TVLPlayerItemStatusCompleted) {
        
        videoState = LiveShareVideoStateCompleted;
        [manager stop];
    }
    
    if ([self.delegate respondsToSelector:@selector(liveShareVideoComponent:onVideoStateChanged:error:)]) {
        [self.delegate liveShareVideoComponent:self onVideoStateChanged:videoState error:error];
    }
}

- (void)manager:(TVLManager *)manager willOpenAudioRenderWithSampleRate:(int)sampleRate channels:(int)channels duration:(int)duration {
    [self.audioProcesser openAudio:sampleRate channels:channels];
}

- (void)manager:(TVLManager *)manager willProcessAudioFrameWithRawData:(float **)rawData samples:(int)samples timeStamp:(int64_t)timestamp {
    [self.audioProcesser processAudio:rawData samples:samples];
}

#pragma mark - publicMethods
/// 开始播放
/// @param urlString URL string
- (void)playWihtURLString:(NSString *)urlString {
    // 设置播放器Item
    [self.tvlManager stop];
    TVLPlayerItem *item = [TVLPlayerItem playerItemWithURL:[NSURL URLWithString:urlString]];
    
    if (!item) {
        NSError *error = [NSError errorWithDomain:@"URL is not valid" code:-1 userInfo:nil];
        if ([self.delegate respondsToSelector:@selector(liveShareVideoComponent:onVideoStateChanged:error:)]) {
            [self.delegate liveShareVideoComponent:self onVideoStateChanged:LiveShareVideoStateFailure error:error];
        }
        return;
    }
    
    [self.tvlManager replaceCurrentItemWithPlayerItem:item];
    // 调用播放器静音方法，停止内部渲染音频数据
    [self.tvlManager setMuted:YES];
    // 回调音频数据
    [self.tvlManager setShouldReportAudioFrame:YES];
    // 播放
    [self.tvlManager play];
}
/// 停止播放
- (void)stop {
    [self.tvlManager stop];
}
/// 关闭播放器
- (void)close {
    if (_tvlManager) {
        [_tvlManager setShouldReportAudioFrame:NO];
        [_tvlManager stop];
        [_tvlManager close];
        _tvlManager = nil;
    }
}

#pragma mark - getter

- (VodAudioProcessor *)audioProcesser {
    if (!_audioProcesser) {
        _audioProcesser = [[VodAudioProcessor alloc] initWithRTCKit:[LiveShareRTCManager shareRtc].rtcEngineKit];
    }
    return _audioProcesser;
}

@end
