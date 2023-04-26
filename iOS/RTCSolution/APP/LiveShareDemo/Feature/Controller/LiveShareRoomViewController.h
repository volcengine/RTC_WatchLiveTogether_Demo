// 
// Copyright (c) 2023 Beijing Volcano Engine Technology Ltd.
// SPDX-License-Identifier: MIT
// 

#import "LiveSharePlayViewController.h"
#import "LiveShareRTSManager.h"
#import "LiveShareRoomModel.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LiveShareRoomViewController : UIViewController

@property(nonatomic, weak) LiveSharePlayViewController *playController;

/**
 * @brief 新用户进房，收到 RTS 消息后执行该方法。
 * @param userModel 用户模型
 */
- (void)onUserJoined:(LiveShareUserModel *)userModel;

/**
 * @brief 用户退房，收到 RTS 消息后执行该方法。
 * @param userModel 用户模型
 */
- (void)onUserLeaved:(LiveShareUserModel *)userModel;

/**
 * @brief 房间状态改变，收到 RTS 消息后执行该方法。
 * @param roomID 房间ID
 * @param scene 房间场景：聊天场景、一起看直播场景
 * @param videoURL 直播 URL
 * @param videoDirection 视频方向
 */
- (void)onUpdateRoomScene:(NSString *)roomID
                    scene:(LiveShareRoomStatus)scene
                 videoURL:(NSString *)videoURL
           videoDirection:(LiveShareVideoDirection)videoDirection;

/**
 * @brief 房间直播源变更，收到 RTS 消息后执行该方法。
 * @param roomID 房间ID
 * @param userID 用户ID
 * @param videoURL 直播 URL
 * @param videoDirection 视频方向
 */
- (void)onRoomVideoURLUpdated:(NSString *)roomID
                       userID:(NSString *)userID
                     videoURL:(NSString *)videoURL
               videoDorection:(LiveShareVideoDirection)videoDirection;

/**
 * @brief 用户媒体状态更新，收到 RTS 消息后执行该方法。
 * @param roomID 房间ID
 * @param userModel 用户模型
 */
- (void)onUserMediaUpdated:(NSString *)roomID
                 userModel:(LiveShareUserModel *)userModel;

/**
 * @brief 收到用户消息，收到 RTS 消息后执行该方法。
 * @param userModel 用户模型
 * @param message 消息内容
 */
- (void)onReceivedUserMessage:(LiveShareUserModel *)userModel
                      message:(NSString *)message;

/**
 * @brief 房间关闭，收到 RTS 消息后执行该方法。
 * @param roomID 房间ID
 * @param type 关闭类型
 */
- (void)onRoomClosed:(NSString *)roomID type:(LiveShareRoomCloseType)type;

@end

NS_ASSUME_NONNULL_END
