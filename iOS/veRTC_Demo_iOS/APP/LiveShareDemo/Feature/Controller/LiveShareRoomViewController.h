//
//  LiveShareChatRoomViewController.h
//  veRTC_Demo
//
//

#import "LiveSharePlayViewController.h"
#import "LiveShareRTSManager.h"
#import "LiveShareRoomModel.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LiveShareRoomViewController : UIViewController

@property(nonatomic, weak) LiveSharePlayViewController *playController;

- (instancetype)initWithRoomModel:(LiveShareRoomModel *)roomModel;

/// 新用户进房
/// @param userModel User model
- (void)onUserJoined:(LiveShareUserModel *)userModel;

/// 用户退房
/// @param userModel User model
- (void)onUserLeaved:(LiveShareUserModel *)userModel;

/// 房间状态改变
/// @param roomID RoomID
/// @param scene Scene
/// @param videoURL Video URL
/// @param videoDirection Video direction
- (void)onUpdateRoomScene:(NSString *)roomID
                    scene:(LiveShareRoomStatus)scene
                 videoURL:(NSString *)videoURL
           videoDirection:(LiveShareVideoDirection)videoDirection;

/// 房间直播源变更
/// @param roomID RoomID
/// @param userID UserID
/// @param videoURL Video URL
/// @param videoDirection Video direction
- (void)onRoomVideoURLUpdated:(NSString *)roomID
                       userID:(NSString *)userID
                     videoURL:(NSString *)videoURL
               videoDorection:(LiveShareVideoDirection)videoDirection;

/// 用户媒体状态更新
/// @param roomID RoomID
/// @param userModel User model
- (void)onUserMediaUpdated:(NSString *)roomID
                 userModel:(LiveShareUserModel *)userModel;

/// 收到用户消息
/// @param userModel User model
/// @param message Message
- (void)onReceivedUserMessage:(LiveShareUserModel *)userModel
                      message:(NSString *)message;

/// 房间关闭
/// @param roomID RoomID
/// @param type type
- (void)onRoomClosed:(NSString *)roomID type:(LiveShareRoomCloseType)type;

@end

NS_ASSUME_NONNULL_END
