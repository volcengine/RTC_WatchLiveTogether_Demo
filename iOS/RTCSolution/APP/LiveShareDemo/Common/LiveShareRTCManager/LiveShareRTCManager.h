// 
// Copyright (c) 2023 Beijing Volcano Engine Technology Ltd.
// SPDX-License-Identifier: MIT
// 

#import "BaseRTCManager.h"
#import <Foundation/Foundation.h>
@class LiveShareRTCManager;

NS_ASSUME_NONNULL_BEGIN

@protocol LiveShareRTCManagerDelegate <NSObject>

/**
 * @brief 房间状态改变时的回调。 通过此回调，您会收到与房间相关的警告、错误和事件的通知。 例如，用户加入房间，用户被移出房间等。
 * @param manager LiveShareRTCManager 模型
 * @param joinModel RTCJoinModel模型房间信息、加入成功失败等信息。
 */
- (void)liveShareRTCManager:(LiveShareRTCManager *)manager
         onRoomStateChanged:(RTCJoinModel *)joinModel;

/**
 * @brief 用户首帧回调，刷新渲染UI
 * @param manager LiveShareRTCManager
 * @param userID UserID
 */
- (void)liveShareRTCManager:(LiveShareRTCManager *)manager
    onFirstRemoteVideoFrameDecoded:(NSString *)userID;

/**
 * @brief 本地用户音量变化回调
 * @param manager RTC manager
 * @param volume 用户音量大小
 */
- (void)liveShareRTCManager:(LiveShareRTCManager *)manager
    onLocalAudioPropertiesReport:(NSInteger)volume;

/**
 * @brief 远端用户音量变化回调
 * @param manager RTC manager
 * @param volumeInfo 用户音量信息{ UserID : 音量大小 }
 */
- (void)liveShareRTCManager:(LiveShareRTCManager *)manager
    onReportRemoteUserAudioVolume:
        (NSDictionary<NSString *, NSNumber *> *_Nonnull)volumeInfo;

@end

@interface LiveShareRTCManager : BaseRTCManager

@property(nonatomic, weak) id<LiveShareRTCManagerDelegate> delegate;

+ (LiveShareRTCManager *)shareRtc;
- (void)joinRoomWithToken:(NSString *)token
                   roomID:(NSString *)roomID
                      uid:(NSString *)uid;

/**
 * @brief 离开 RTC 房间
 */
- (void)leaveRTCRoom;

/**
 * @brief 开启/关闭本地视频采集
 * @param isStart ture:开启视频采集 false：关闭视频采集
 */
- (void)switchVideoCapture:(BOOL)isStart;

/**
 * @brief 开启/关闭本地音频采集
 * @param isStart ture:开启音频采集 false：关闭音频采集
 */
- (void)switchAudioCapture:(BOOL)isStart;

/**
 * @brief 前后摄像头切换
 */
- (void)switchCamera;

/**
 * @brief 控制本地音频流的发送状态：发送/不发送
 * @param isPublish true：发送, false：不发送
 */
- (void)publishAudioStream:(BOOL)isPublish;

#pragma mark - Audio Mixing
// 调节本地播放的所有远端用户混音后的音量 [0, 1.0]
@property(nonatomic, assign) CGFloat recordingVolume;
// 调节混音的音量大小[0, 1.0]
@property(nonatomic, assign) CGFloat audioMixingVolume;
// 是否开启音频闪避
@property(nonatomic, assign) BOOL enableAudioDucking;

/**
 * @brief 启用混音
 */
- (void)startAudioMixing;

/**
 * @brief 关闭混音
 */
- (void)stopAudioMixing;

#pragma mark - Render

/**
 * @brief 获取 RTC 渲染 UIView
 * @param uid 用户ID
 */
- (UIView *)getStreamViewWithUid:(NSString *)uid;

/**
 * @brief 移除用户的渲染绑定
 * @param userID 用户ID
 */
- (void)removeStreamViewWithUserID:(NSString *)userID;

/**
 * @brief 用户 ID 和 RTC 渲染 View 进行绑定
 * @param uid 用户ID
 */
- (void)bindCanvasViewWithUid:(NSString *)uid;

@end

NS_ASSUME_NONNULL_END
