//
//  LiveShareControlComponments.h
//  veRTC_Demo
//
//

#import "LiveShareRoomModel.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, LiveShareRoomCloseType) {
  /// 房主关闭
  LiveShareRoomCloseTypeByHost = 1,
  /// 超时解散
  LiveShareRoomCloseTypeTimeout,
  /// 审核关房
  LiveShareRoomCloseTypeReview,
};

@interface LiveShareRTSManager : NSObject

/// 加入房间
/// @param roomID RoomID
/// @param block Callback
+ (void)
    requestJoinRoomWithRoomID:(NSString *)roomID
                        block:(void (^)(LiveShareRoomModel *roomModel,
                                        NSArray<LiveShareUserModel *> *userList,
                                        RTMACKModel *model))block;

/// 离开房间
/// @param roomID RoomID
/// @param block Callback
+ (void)requestLeaveRoom:(NSString *)roomID
                   block:(void (^)(RTMACKModel *model))block;

/// 主播开启一起看
/// @param roomID RoomID
/// @param urlString URL string
/// @param videoDirection Video direction
/// @param block Callback
+ (void)requestJoinWatch:(NSString *)roomID
               urlString:(NSString *)urlString
          videoDirection:(LiveShareVideoDirection)videoDirection
                   block:(void (^)(LiveShareRoomModel *roomModel,
                                   RTMACKModel *model))block;

/// 主播退出一起看
/// @param roomID RoomID
/// @param block Callback
+ (void)requestLeaveWatch:(NSString *)roomID
                    block:(void (^)(LiveShareRoomModel *roomModel,
                                    RTMACKModel *model))block;

/// 主播改变播放链接
/// @param roomID RoomID
/// @param urlString URL string
/// @param videoDirection Video direction
/// @param block Callback
+ (void)requestChangeVideo:(NSString *)roomID
                 urlString:(NSString *)urlString
            videoDirection:(LiveShareVideoDirection)videoDirection
                     block:(void (^)(LiveShareRoomModel *roomModel,
                                     RTMACKModel *model))block;

/// 发消息
/// @param roomID Room ID
/// @param message Message
/// @param block Callback
+ (void)sendMessage:(NSString *)roomID
            message:(NSString *)message
              block:(void (^)(RTMACKModel *model))block;

/// 改变媒体状态
/// @param roomID RoomID
/// @param enableMic 麦克风状态
/// @param enableCamera 摄像头状态
/// @param block Callback
+ (void)requestChangeMediaStatus:(NSString *)roomID
                             mic:(BOOL)enableMic
                          camera:(BOOL)enableCamera
                           block:(void (^)(LiveShareUserModel *userModel,
                                           RTMACKModel *model))block;

/// 清理用户遗留状态
/// @param block Callback
+ (void)clearUser:(void (^)(RTMACKModel *model))block;

/// 断网重连
/// @param block Callback
+ (void)reconnectWithBlock:(void (^)(LiveShareRoomModel *roomModel,
                                     NSArray<LiveShareUserModel *> *userList,
                                     RTMACKModel *model))block;

/// 获取房间内观众列表
/// @param block Callback
+ (void)getUserListStatusWithBlock:(void (^)(NSArray<LiveShareUserModel *> *userList,
                                             RTMACKModel *model))block;

#pragma mark - Notification Message

/// 用户进房通知
/// @param block Callback
+ (void)onUserJoinedBlock:(void (^)(LiveShareUserModel *userModel))block;

/// 用户离房通知
/// @param block Callback
+ (void)onUserLeavedBlock:(void (^)(LiveShareUserModel *userModel))block;

/// 房间状态改变通知
/// @param block Callback
+ (void)onUpdateRoomSceneWithBlock:
    (void (^)(NSString *roomID, LiveShareRoomStatus roomStatus,
              NSString *userID, NSString *videoURL,
              LiveShareVideoDirection videoDirection))block;

/// 房间直播源改变
/// @param block Callback
+ (void)onRoomVideoURLUpdatedBlock:
    (void (^)(NSString *roomID, NSString *videoURL, NSString *userID,
              LiveShareVideoDirection videoDirection))block;

/// 用户媒体状态改变
/// @param block Callback
+ (void)onUserMediaUpdatedBlock:(void (^)(NSString *roomID,
                                          LiveShareUserModel *userModel))block;

/// 收到用户消息
/// @param block Callback
+ (void)onReceivedUserMessageBlock:(void (^)(LiveShareUserModel *userModel,
                                             NSString *message))block;

/// 房间关闭
/// @param block Callback
+ (void)onRoomClosedBlock:(void (^)(NSString *roomID,
                                    LiveShareRoomCloseType type))block;

@end

NS_ASSUME_NONNULL_END
