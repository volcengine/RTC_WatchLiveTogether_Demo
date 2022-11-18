//
//  LiveShareRTCManager.h
//  veRTC_Demo
//
//

#import "BaseRTCManager.h"
#import <Foundation/Foundation.h>
@class LiveShareRTCManager;

NS_ASSUME_NONNULL_BEGIN

@protocol LiveShareRTCManagerDelegate <NSObject>

/**
 * 用户首帧回调，刷新渲染UI
 * @param manager LiveShareRTCManager
 * @param userID UserID
 */
- (void)liveShareRTCManager:(LiveShareRTCManager *)manager
    onFirstRemoteVideoFrameDecoded:(NSString *)userID;

/**
 * 本地用户音量变化回调
 * @param manager RTC manager
 * @param volume 用户音量大小
 */
- (void)liveShareRTCManager:(LiveShareRTCManager *)manager
    onLocalAudioPropertiesReport:(NSInteger)volume;

/**
 * 远端用户音量变化回调
 * @param manager RTC manager
 * @param volumeInfo 用户音量信息{ UserID : 音量大小 }
 */
- (void)liveShareRTCManager:(LiveShareRTCManager *)manager
    onReportRemoteUserAudioVolume:
        (NSDictionary<NSString *, NSNumber *> *_Nonnull)volumeInfo;

@end

@interface LiveShareRTCManager : BaseRTCManager

@property(nonatomic, weak) id<LiveShareRTCManagerDelegate> delegate;

/**
 * RTC Manager Singletons
 */
+ (LiveShareRTCManager *)shareRtc;

#pragma mark - Method

/**
 * Join room
 * @param token token
 * @param roomID roomID
 * @param uid uid
 */
- (void)joinChannelWithToken:(NSString *)token
                      roomID:(NSString *)roomID
                         uid:(NSString *)uid;

/**
 * Switch local audio capture
 * @param enable ture:Turn on audio capture false：Turn off audio capture
 */
- (void)enableLocalAudio:(BOOL)enable;

/**
 * Switch local video capture
 * @param enable ture:Turn on audio capture false：Turn off video capture
 */
- (void)enableLocalVideo:(BOOL)enable;

/**
 * Switch local audio capture
 * @param mute ture:Turn on audio capture false：Turn off audio capture
 */
- (void)muteLocalAudio:(BOOL)mute;

/**
 * Switch the camera
 */
- (void)switchCamera;

/**
 * Set the camera is front
 */
- (void)updateCameraID:(BOOL)isFront;

/**
 * Set the local preview screen
 * @param view Render view
 */
- (void)setLocalPreView:(UIView *_Nullable)view;

/**
 * Leave the room
 */
- (void)leaveChannel;

#pragma mark - Audio Mixing

/**
 * Adjust the volume of all remote user mixes played locally [0, 1.0]
 * 调节本地播放的所有远端用户混音后的音量 [0, 1.0]
 */
@property(nonatomic, assign) CGFloat recordingVolume;

/**
 * Adjust the volume of the mix [0, 1.0]
 * 调节混音的音量大小[0, 1.0]
 */
@property(nonatomic, assign) CGFloat audioMixingVolume;

/**
 * Whether to enable audio ducking
 * 是否开启音频闪避
 */
@property(nonatomic, assign) BOOL enableAudioDucking;

/**
 * Enable audio mixing
 */
- (void)startAudioMixing;

/**
 * Turn off audio mixing
 */
- (void)stopAudioMixing;

#pragma mark - Render

/**
 * Get stream render view
 */
- (UIView *)getStreamViewWithUid:(NSString *)uid;

/**
 * Remove stream view
 * @param userID User id
 */
- (void)removeStreamViewWithUserID:(NSString *)userID;

/**
 * Bind the stream to render the view
 */
- (void)bindCanvasViewWithUid:(NSString *)uid;

@end

NS_ASSUME_NONNULL_END
