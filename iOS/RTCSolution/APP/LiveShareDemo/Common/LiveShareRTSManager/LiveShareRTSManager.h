// 
// Copyright (c) 2023 Beijing Volcano Engine Technology Ltd.
// SPDX-License-Identifier: MIT
// 

#import "LiveShareRoomModel.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, LiveShareRoomCloseType) {
    // 房主关闭
    LiveShareRoomCloseTypeByHost = 1,
    // 超时解散
    LiveShareRoomCloseTypeTimeout,
    // 审核关房
    LiveShareRoomCloseTypeReview,
};

@interface LiveShareRTSManager : NSObject

/**
 * @brief 加入房间
 * @param roomID RoomID
 * @param block Callback
 */
+ (void)
    requestJoinRoomWithRoomID:(NSString *)roomID
                        block:(void (^)(LiveShareRoomModel *roomModel,
                                        NSArray<LiveShareUserModel *> *userList,
                                        RTSACKModel *model))block;

/**
 * @brief 离开房间
 * @param roomID RoomID
 * @param block Callback
 */
+ (void)requestLeaveRoom:(NSString *)roomID
                   block:(void (^)(RTSACKModel *model))block;

/**
 * @brief 主播开启一起看
 * @param roomID RoomID
 * @param urlString URL string
 * @param videoDirection 视频方向
 * @param block Callback
 */
+ (void)requestJoinWatch:(NSString *)roomID
               urlString:(NSString *)urlString
          videoDirection:(LiveShareVideoDirection)videoDirection
                   block:(void (^)(LiveShareRoomModel *roomModel,
                                   RTSACKModel *model))block;

/**
 * @brief 主播退出一起看
 * @param roomID RoomID
 * @param block Callback
 */
+ (void)requestLeaveWatch:(NSString *)roomID
                    block:(void (^)(LiveShareRoomModel *roomModel,
                                    RTSACKModel *model))block;

/**
 * @brief 主播改变播放链接
 * @param roomID RoomID
 * @param urlString URL string
 * @param videoDirection Video direction
 * @param block Callback
 */
+ (void)requestChangeVideo:(NSString *)roomID
                 urlString:(NSString *)urlString
            videoDirection:(LiveShareVideoDirection)videoDirection
                     block:(void (^)(LiveShareRoomModel *roomModel,
                                     RTSACKModel *model))block;

/**
 * @brief 发消息
 * @param roomID Room ID
 * @param message Message
 * @param block Callback
 */
+ (void)sendMessage:(NSString *)roomID
            message:(NSString *)message
              block:(void (^)(RTSACKModel *model))block;

/**
 * @brief 改变媒体状态
 * @param roomID RoomID
 * @param enableMic 麦克风状态
 * @param enableCamera 摄像头状态
 * @param block Callback
 */
+ (void)requestChangeMediaStatus:(NSString *)roomID
                             mic:(BOOL)enableMic
                          camera:(BOOL)enableCamera
                           block:(void (^)(LiveShareUserModel *userModel,
                                           RTSACKModel *model))block;

/**
 * @brief 清理用户遗留状态
 * @param block Callback
 */
+ (void)clearUser:(void (^)(RTSACKModel *model))block;

/**
 * @brief 断网重连
 * @param block Callback
 */
+ (void)reconnectWithBlock:(void (^)(LiveShareRoomModel *roomModel,
                                     NSArray<LiveShareUserModel *> *userList,
                                     RTSACKModel *model))block;

/**
 * @brief 获取房间内观众列表
 * @param block Callback
 */
+ (void)getUserListStatusWithBlock:(void (^)(NSArray<LiveShareUserModel *> *userList,
                                             RTSACKModel *model))block;

#pragma mark - Notification Message

+ (void)onUserJoinedBlock:(void (^)(LiveShareUserModel *userModel))block;

+ (void)onUserLeavedBlock:(void (^)(LiveShareUserModel *userModel))block;

+ (void)onUpdateRoomSceneWithBlock:
    (void (^)(NSString *roomID, LiveShareRoomStatus roomStatus,
              NSString *userID, NSString *videoURL,
              LiveShareVideoDirection videoDirection))block;

+ (void)onRoomVideoURLUpdatedBlock:
    (void (^)(NSString *roomID, NSString *videoURL, NSString *userID,
              LiveShareVideoDirection videoDirection))block;

+ (void)onUserMediaUpdatedBlock:(void (^)(NSString *roomID,
                                          LiveShareUserModel *userModel))block;

+ (void)onReceivedUserMessageBlock:(void (^)(LiveShareUserModel *userModel,
                                             NSString *message))block;

+ (void)onRoomClosedBlock:(void (^)(NSString *roomID,
                                    LiveShareRoomCloseType type))block;

@end

NS_ASSUME_NONNULL_END
