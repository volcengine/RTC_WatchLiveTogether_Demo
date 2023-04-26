// 
// Copyright (c) 2023 Beijing Volcano Engine Technology Ltd.
// SPDX-License-Identifier: MIT
// 

#import "LiveShareVideoComponent.h"
#import <TTSDK/TTVideoLive.h>
#import <TTSDK/TTSDKManager.h>
#import "LiveShareVodAudioManager.h"
#import "LiveShareRTCManager.h"

@interface LiveShareVideoComponent ()<TVLDelegate>

@property (nonatomic, weak) UIView *superView;

@property (nonatomic, strong) TVLManager *tvlManager;
@property (nonatomic, strong) LiveShareVodAudioManager *audioProcesser;

@end

@implementation LiveShareVideoComponent {
    TVLAudioWrapper *_audioWrapper;
}

- (void)dealloc {
    [self releaseAudioWrapper];
}

- (instancetype)initWithSuperview:(UIView *)superView {
    if (self = [super init]) {
        self.superView = superView;
        [self addObserver];
        [TVLManager startOpenGLESActivity];
        
        self.tvlManager = [[TVLManager alloc] initWithOwnPlayer:YES];
        self.tvlManager.playerViewScaleMode = TVLViewScalingModeAspectFit;
        self.tvlManager.delegate = self;
        self.tvlManager.hardwareDecode = YES;
        
        _audioProcesser = [[LiveShareVodAudioManager alloc] initWithRTCKit:[LiveShareRTCManager shareRtc].rtcEngineKit];
        _audioWrapper = new TVLAudioWrapper();
        _audioWrapper->context = (__bridge void *)self;
        _audioWrapper->open = audio_open;
        _audioWrapper->process = audio_process;
        _audioWrapper->close = audio_close;
        _audioWrapper->release = audio_release;
        [self.tvlManager setOptionValue:[NSValue valueWithPointer:_audioWrapper] forIdentifier:@(TVLPlayerOptionAudioProcessWrapper)];
        [self.tvlManager setMuted:YES];
   
        [superView addSubview:self.tvlManager.playerView];
        [self.tvlManager.playerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(superView);
        }];;
    }
    return self;
}

#pragma mark - Observer

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

#pragma mark - playerAudio

static void audio_open(void *context, int samplerate, int channels, int duration) {
    if (!context) {
        return;
    }
    LiveShareVideoComponent *process = (__bridge LiveShareVideoComponent *)(context);
    [process.audioProcesser openAudio:samplerate channels:channels];
}

static void audio_process(void *context, float **audioData, int samples, int64_t timestamp) {
    if (!context) {
        return;
    }
    LiveShareVideoComponent *process = (__bridge LiveShareVideoComponent *)(context);
    [process.audioProcesser processAudio:audioData samples:samples];
}

static void audio_close(void *context) {
    
}

static void audio_release(void *context) {
    if (!context) {
        return;
    }
    @autoreleasepool {
        LiveShareVideoComponent *process = (__bridge LiveShareVideoComponent *)(context);
        [process releaseAudioWrapper];
    }
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

#pragma mark - Publish Action

// 开始播放
// @param urlString URL string
- (void)playWihtURLString:(NSString *)urlString {

    [self.tvlManager stop];
    // 设置播放器Item
    TVLPlayerItem *item = [TVLPlayerItem playerItemWithURL:[NSURL URLWithString:urlString]];
    
    if (!item) {
        NSError *error = [NSError errorWithDomain:@"URL is not valid" code:-1 userInfo:nil];
        if ([self.delegate respondsToSelector:@selector(liveShareVideoComponent:onVideoStateChanged:error:)]) {
            [self.delegate liveShareVideoComponent:self onVideoStateChanged:LiveShareVideoStateFailure error:error];
        }
        return;
    }
    
    [self.tvlManager replaceCurrentItemWithPlayerItem:item];
    // 播放
    [self.tvlManager play];
}
// 停止播放
- (void)stop {
    [self.tvlManager stop];
}
// 关闭播放器
- (void)close {
    if (_tvlManager) {
        [_tvlManager stop];
        [_tvlManager close];
        [self releaseAudioWrapper];
        _tvlManager = nil;
    }
}

- (void)releaseAudioWrapper {
    if (_audioWrapper != nullptr) {
        _audioWrapper->context = nullptr;
        NSValue *nsWrapper = [NSValue valueWithPointer:nullptr];
        [self.tvlManager setOptionValue:nsWrapper forIdentifier:@(TVLPlayerOptionAudioProcessWrapper)];
        delete _audioWrapper;
        _audioWrapper = nil;
    }
}

@end
