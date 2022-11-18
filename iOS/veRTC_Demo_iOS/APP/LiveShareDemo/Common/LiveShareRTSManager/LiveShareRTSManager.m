//
//  LiveShareControlComponments.m
//  veRTC_Demo
//
//

#import "LiveShareRTSManager.h"
#import "LiveShareRTCManager.h"
#import "JoinRTSParams.h"

@implementation LiveShareRTSManager

+ (void)requestJoinRoomWithRoomID:(NSString *)roomID
                            block:(void(^)(LiveShareRoomModel *roomModel, NSArray<LiveShareUserModel *> *userList, RTMACKModel *model))block {
    
    int mic = [LiveShareMediaModel shared].enableAudio? 1 : 0;
    int camera = [LiveShareMediaModel shared].enableVideo? 1 : 0;
    
    NSDictionary *dic = @{
        @"room_id" : roomID,
        @"user_name" : [LocalUserComponent userModel].name,
        @"mic" : @(mic),
        @"camera" : @(camera)
    };
    dic = [JoinRTSParams addTokenToParams:dic];
    
    [[LiveShareRTCManager shareRtc] emitWithAck:@"twvJoinRoom"
                                           with:dic
                                          block:^(RTMACKModel * _Nonnull ackModel) {
        LiveShareRoomModel *roomModel = nil;
        NSArray *userList = nil;
        if ([LiveShareRTSManager ackModelResponseClass:ackModel]) {
            roomModel = [LiveShareRoomModel yy_modelWithJSON:ackModel.response[@"room"]];
            userList = [NSArray yy_modelArrayWithClass:[LiveShareUserModel class] json:ackModel.response[@"user_list"]];
        }
        if (block) {
            block(roomModel, userList, ackModel);
        }
        NSLog(@"[%@]-twvJoinRoom %@ \n %@", [self class], dic, ackModel.response);
    }];
}

/// 离开房间
/// @param roomID RoomID
/// @param block Callback
+ (void)requestLeaveRoom:(NSString *)roomID block:(nonnull void (^)(RTMACKModel * _Nonnull))block {
    NSDictionary *dic = @{
        @"room_id" : roomID
    };
    dic = [JoinRTSParams addTokenToParams:dic];
    
    [[LiveShareRTCManager shareRtc] emitWithAck:@"twvLeaveRoom"
                                           with:dic
                                          block:^(RTMACKModel * _Nonnull ackModel) {
        if (block) {
            block(ackModel);
        }
        NSLog(@"[%@]-twvLeaveRoom %@ \n %@", [self class], dic, ackModel.response);
    }];
}

/// 开启一起看
/// @param roomID RoomID
/// @param urlString URL string
/// @param videoDirection Video direction
/// @param block Callback
+ (void)requestJoinWatch:(NSString *)roomID
               urlString:(NSString *)urlString
          videoDirection:(LiveShareVideoDirection)videoDirection
                   block:(void(^)(LiveShareRoomModel *roomModel, RTMACKModel *model))block {
    
    NSDictionary *dic = @{
        @"room_id" : roomID,
        @"url" : urlString,
        @"compose" : @(videoDirection)
    };
    dic = [JoinRTSParams addTokenToParams:dic];
    
    [[LiveShareRTCManager shareRtc] emitWithAck:@"twvJoinTw"
                                           with:dic
                                          block:^(RTMACKModel * _Nonnull ackModel) {
        LiveShareRoomModel *roomModel = nil;
        if ([LiveShareRTSManager ackModelResponseClass:ackModel]) {
            roomModel = [LiveShareRoomModel yy_modelWithJSON:ackModel.response[@"room"]];
        }
        if (block) {
            block(roomModel, ackModel);
        }
        NSLog(@"[%@]-twvJoinTw %@ \n %@", [self class], dic, ackModel.response);
    }];
}

/// 主播退出一起看
/// @param roomID RoomID
/// @param block Callback
+ (void)requestLeaveWatch:(NSString *)roomID
                    block:(void(^)(LiveShareRoomModel *roomModel, RTMACKModel *model))block {
    NSDictionary *dic = @{
        @"room_id" : roomID,
    };
    dic = [JoinRTSParams addTokenToParams:dic];
    
    [[LiveShareRTCManager shareRtc] emitWithAck:@"twvLeaveTw"
                                           with:dic
                                          block:^(RTMACKModel * _Nonnull ackModel) {
        LiveShareRoomModel *roomModel = nil;
        if ([LiveShareRTSManager ackModelResponseClass:ackModel]) {
            roomModel = [LiveShareRoomModel yy_modelWithJSON:ackModel.response[@"room"]];
        }
        if (block) {
            block(roomModel, ackModel);
        }
        NSLog(@"[%@]-twvLeaveTw %@ \n %@", [self class], dic, ackModel.response);
    }];
}

/// 主播改变播放链接
/// @param roomID RoomID
/// @param urlString URL string
/// @param videoDirection Video direction
/// @param block Callback
+ (void)requestChangeVideo:(NSString *)roomID
                 urlString:(NSString *)urlString
               videoDirection:(LiveShareVideoDirection)videoDirection
                        block:(void(^)(LiveShareRoomModel *roomModel, RTMACKModel *model))block {
    
    NSDictionary *dic = @{
        @"room_id" : roomID,
        @"url" : urlString,
        @"compose" : @(videoDirection)
    };
    dic = [JoinRTSParams addTokenToParams:dic];
    
    [[LiveShareRTCManager shareRtc] emitWithAck:@"twvSetVideoUrl"
                                           with:dic
                                          block:^(RTMACKModel * _Nonnull ackModel) {
        LiveShareRoomModel *roomModel = nil;
        if ([LiveShareRTSManager ackModelResponseClass:ackModel]) {
            roomModel = [LiveShareRoomModel yy_modelWithJSON:ackModel.response[@"room"]];
        }
        if (block) {
            block(roomModel, ackModel);
        }
        NSLog(@"[%@]-twvSetVideoUrl %@ \n %@", [self class], dic, ackModel.response);
    }];
}

/// 发消息
/// @param roomID Room ID
/// @param message Message
/// @param block Callback
+ (void)sendMessage:(NSString *)roomID
            message:(NSString *)message
              block:(void (^)(RTMACKModel *model))block {
    
    NSString *encodedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,(CFStringRef)message,NULL,NULL,kCFStringEncodingUTF8));
    
    NSDictionary *dic = @{@"room_id" : roomID,
                          @"message" : encodedString};
    dic = [JoinRTSParams addTokenToParams:dic];
    
    [[LiveShareRTCManager shareRtc] emitWithAck:@"twvSendMsg" with:dic block:^(RTMACKModel * _Nonnull ackModel) {
        if (block) {
            block(ackModel);
        }
        NSLog(@"[%@]-twvSendMsg %@ \n %@", [self class], dic, ackModel.response);
    }];
}

/// 改变媒体状态
/// @param roomID RoomID
/// @param enableMic 麦克风状态
/// @param enableCamera 摄像头状态
/// @param block Callback
+ (void)requestChangeMediaStatus:(NSString *)roomID
                             mic:(BOOL)enableMic
                          camera:(BOOL)enableCamera
                           block:(void(^)(LiveShareUserModel *userModel, RTMACKModel *model))block {
    NSString *mic = enableMic? @"1" : @"0";
    NSString *camera = enableCamera? @"1" : @"0";
    
    NSDictionary *dic = @{
        @"room_id" : roomID,
        @"mic" : mic,
        @"camera" : camera
    };
    dic = [JoinRTSParams addTokenToParams:dic];
    
    [[LiveShareRTCManager shareRtc] emitWithAck:@"twvUpdateMedia"
                                           with:dic
                                          block:^(RTMACKModel * _Nonnull ackModel) {
        LiveShareUserModel *userModel = nil;
        if ([LiveShareRTSManager ackModelResponseClass:ackModel]) {
            userModel = [LiveShareUserModel yy_modelWithJSON:ackModel.response[@"user"]];
        }
        if (block) {
            block(userModel, ackModel);
        }
        NSLog(@"[%@]-twvUpdateMedia %@ \n %@", [self class], dic, ackModel.response);
    }];
}

/// 清理用户遗留状态
/// @param block Callback
+ (void)clearUser:(void (^)(RTMACKModel *model))block {
    NSDictionary *dic = [JoinRTSParams addTokenToParams:nil];
    
    [[LiveShareRTCManager shareRtc] emitWithAck:@"twvClearUser" with:dic block:^(RTMACKModel * _Nonnull ackModel) {
        
        if (block) {
            block(ackModel);
        }
        NSLog(@"[%@]-twvClearUser %@ \n %@", [self class], dic, ackModel.response);
    }];
}

#pragma mark - Notification Message

/// 用户进房通知
/// @param block Callback
+ (void)onUserJoinedBlock:(void(^)(LiveShareUserModel *userModel))block {
    [[LiveShareRTCManager shareRtc] onSceneListener:@"twvOnJoinRoom"
                                              block:^(RTMNoticeModel * _Nonnull
                                                      noticeModel) {
        LiveShareUserModel *userModel = nil;
        if (noticeModel.data && [noticeModel.data isKindOfClass:[NSDictionary class]]) {
            userModel = [LiveShareUserModel yy_modelWithJSON:noticeModel.data[@"user"]];
        }
        if (block) {
            block(userModel);
        }
        NSLog(@"[%@]-twvOnJoinRoom %@", [self class], noticeModel.data);
    }];
}

/// 用户离房通知
/// @param block Callback
+ (void)onUserLeavedBlock:(void(^)(LiveShareUserModel *userModel))block {
    [[LiveShareRTCManager shareRtc] onSceneListener:@"twvOnLeaveRoom"
                                              block:^(RTMNoticeModel * _Nonnull
                                                      noticeModel) {
        LiveShareUserModel *userModel = nil;
        
        if (noticeModel.data && [noticeModel.data isKindOfClass:[NSDictionary class]]) {
            userModel = [LiveShareUserModel yy_modelWithJSON:noticeModel.data[@"user"]];
        }
        if (block) {
            block(userModel);
        }
        NSLog(@"[%@]-twvOnLeaveRoom %@", [self class], noticeModel.data);
    }];
}

/// 房间状态改变通知
/// @param block Callback
+ (void)onUpdateRoomSceneWithBlock:(void(^)(NSString *roomID, LiveShareRoomStatus roomStatus, NSString *userID,  NSString *videoURL, LiveShareVideoDirection videoDirection))block {
    [[LiveShareRTCManager shareRtc] onSceneListener:@"twvOnUpdateRoomScene"
                                              block:^(RTMNoticeModel * _Nonnull
                                                      noticeModel) {
        NSString *roomID = @"";
        NSString *userID = @"";
        LiveShareRoomStatus roomStatus = LiveShareRoomStatusChat;
        NSString *videoURL = @"";
        LiveShareVideoDirection videoDirection = LiveShareVideoDirectionHorizontal;
        if (noticeModel.data && [noticeModel.data isKindOfClass:[NSDictionary class]]) {
            roomID = [NSString stringWithFormat:@"%@", noticeModel.data[@"room_id"]];
            roomStatus = [noticeModel.data[@"room_scene"] integerValue];
            userID = [NSString stringWithFormat:@"%@", noticeModel.data[@"user_id"]];
            videoURL = [NSString stringWithFormat:@"%@", noticeModel.data[@"url"]];
            videoDirection = [noticeModel.data[@"compose"] integerValue];
        }
        if (block) {
            block(roomID, roomStatus, userID, videoURL, videoDirection);
        }
        NSLog(@"[%@]-twvOnUpdateRoomScene %@", [self class], noticeModel.data);
    }];
}

/// 房间直播源改变
/// @param block Callback
+ (void)onRoomVideoURLUpdatedBlock:(void(^)(NSString *roomID, NSString *videoURL, NSString *userID, LiveShareVideoDirection videoDirection))block {
    [[LiveShareRTCManager shareRtc] onSceneListener:@"twvOnUpdateRoomVideoUrl"
                                              block:^(RTMNoticeModel * _Nonnull
                                                      noticeModel) {
        NSString *roomID = @"";
        NSString *userID = @"";
        NSString *videoURL = @"";
        LiveShareVideoDirection videoDirection = LiveShareVideoDirectionHorizontal;
        
        if (noticeModel.data && [noticeModel.data isKindOfClass:[NSDictionary class]]) {
            roomID = [NSString stringWithFormat:@"%@", noticeModel.data[@"room_id"]];
            userID = [NSString stringWithFormat:@"%@", noticeModel.data[@"user_id"]];
            videoURL = [NSString stringWithFormat:@"%@", noticeModel.data[@"url"]];
            videoDirection = [noticeModel.data[@"compose"] integerValue];
        }
        if (block) {
            block(roomID, videoURL, userID, videoDirection);
        }
        NSLog(@"[%@]-twvOnUpdateRoomVideoUrl %@", [self class], noticeModel.data);
    }];
}

/// 用户媒体状态改变
/// @param block Callback
+ (void)onUserMediaUpdatedBlock:(void(^)(NSString *roomID, LiveShareUserModel *userModel))block {
    [[LiveShareRTCManager shareRtc] onSceneListener:@"twvOnUpdateRoomMedia"
                                              block:^(RTMNoticeModel * _Nonnull
                                                      noticeModel) {
        NSString *roomID = @"";
        LiveShareUserModel *userModel = nil;
        
        if (noticeModel.data && [noticeModel.data isKindOfClass:[NSDictionary class]]) {
            roomID = [NSString stringWithFormat:@"%@", noticeModel.data[@"room_id"]];
            userModel = [LiveShareUserModel yy_modelWithJSON:noticeModel.data[@"user"]];
        }
        if (block) {
            block(roomID, userModel);
        }
        NSLog(@"[%@]-twvOnUpdateRoomMedia %@", [self class], noticeModel.data);
    }];
}

/// 收到用户消息
/// @param block Callback
+ (void)onReceivedUserMessageBlock:(void(^)(LiveShareUserModel *userModel, NSString *message))block {
    [[LiveShareRTCManager shareRtc] onSceneListener:@"twvOnSendMessage"
                                              block:^(RTMNoticeModel * _Nonnull
                                                      noticeModel) {
        NSString *message = @"";
        LiveShareUserModel *userModel = nil;
        
        if (noticeModel.data && [noticeModel.data isKindOfClass:[NSDictionary class]]) {
            message = [NSString stringWithFormat:@"%@", noticeModel.data[@"message"]];
            message = [message stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            
            userModel  = [LiveShareUserModel yy_modelWithJSON:noticeModel.data[@"user"]];
        }
        if (block) {
            block(userModel, message);
        }
        NSLog(@"[%@]-twvOnSendMessage %@", [self class], noticeModel.data);
    }];
}

/// 房间关闭
/// @param block Callback
+ (void)onRoomClosedBlock:(void(^)(NSString *roomID, LiveShareRoomCloseType type))block {
    [[LiveShareRTCManager shareRtc] onSceneListener:@"twvOnCloseRoom"
                                              block:^(RTMNoticeModel * _Nonnull
                                                      noticeModel) {
        NSString *roomID = @"";
        LiveShareRoomCloseType type = LiveShareRoomCloseTypeByHost;
        if (noticeModel.data && [noticeModel.data isKindOfClass:[NSDictionary class]]) {
            roomID = [NSString stringWithFormat:@"%@", noticeModel.data[@"room_id"]];
            type = [noticeModel.data[@"type"] integerValue];
        }
        if (block) {
            block(roomID, type);
        }
        NSLog(@"[%@]-twvOnCloseRoom %@", [self class], noticeModel.data);
    }];
}

#pragma mark - tool

+ (BOOL)ackModelResponseClass:(RTMACKModel *)ackModel {
    if ([ackModel.response isKindOfClass:[NSDictionary class]]) {
        return YES;
    } else {
        return NO;
    }
}

@end
