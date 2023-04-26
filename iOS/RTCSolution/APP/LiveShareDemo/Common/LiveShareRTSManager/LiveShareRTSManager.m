// 
// Copyright (c) 2023 Beijing Volcano Engine Technology Ltd.
// SPDX-License-Identifier: MIT
// 

#import "LiveShareRTSManager.h"
#import "LiveShareRTCManager.h"
#import "JoinRTSParams.h"

@implementation LiveShareRTSManager

+ (void)requestJoinRoomWithRoomID:(NSString *)roomID
                            block:(void(^)(LiveShareRoomModel *roomModel,
                                           NSArray<LiveShareUserModel *> *userList,
                                           RTSACKModel *model))block {
    
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
                                          block:^(RTSACKModel * _Nonnull ackModel) {
        LiveShareRoomModel *roomModel = nil;
        NSArray *userList = nil;
        if ([LiveShareRTSManager ackModelResponseClass:ackModel]) {
            roomModel = [LiveShareRoomModel yy_modelWithJSON:ackModel.response[@"room"]];
            userList = [NSArray yy_modelArrayWithClass:[LiveShareUserModel class] json:ackModel.response[@"user_list"]];
        }
        if (block) {
            block(roomModel, userList, ackModel);
        }
    }];
}

+ (void)requestLeaveRoom:(NSString *)roomID block:(nonnull void (^)(RTSACKModel * _Nonnull))block {
    NSDictionary *dic = @{
        @"room_id" : roomID
    };
    dic = [JoinRTSParams addTokenToParams:dic];
    
    [[LiveShareRTCManager shareRtc] emitWithAck:@"twvLeaveRoom"
                                           with:dic
                                          block:^(RTSACKModel * _Nonnull ackModel) {
        if (block) {
            block(ackModel);
        }
    }];
}

+ (void)requestJoinWatch:(NSString *)roomID
               urlString:(NSString *)urlString
          videoDirection:(LiveShareVideoDirection)videoDirection
                   block:(void(^)(LiveShareRoomModel *roomModel, RTSACKModel *model))block {
    
    NSDictionary *dic = @{
        @"room_id" : roomID,
        @"url" : urlString,
        @"compose" : @(videoDirection)
    };
    dic = [JoinRTSParams addTokenToParams:dic];
    
    [[LiveShareRTCManager shareRtc] emitWithAck:@"twvJoinTw"
                                           with:dic
                                          block:^(RTSACKModel * _Nonnull ackModel) {
        LiveShareRoomModel *roomModel = nil;
        if ([LiveShareRTSManager ackModelResponseClass:ackModel]) {
            roomModel = [LiveShareRoomModel yy_modelWithJSON:ackModel.response[@"room"]];
        }
        if (block) {
            block(roomModel, ackModel);
        }
    }];
}

+ (void)requestLeaveWatch:(NSString *)roomID
                    block:(void(^)(LiveShareRoomModel *roomModel, RTSACKModel *model))block {
    NSDictionary *dic = @{
        @"room_id" : roomID,
    };
    dic = [JoinRTSParams addTokenToParams:dic];
    
    [[LiveShareRTCManager shareRtc] emitWithAck:@"twvLeaveTw"
                                           with:dic
                                          block:^(RTSACKModel * _Nonnull ackModel) {
        LiveShareRoomModel *roomModel = nil;
        if ([LiveShareRTSManager ackModelResponseClass:ackModel]) {
            roomModel = [LiveShareRoomModel yy_modelWithJSON:ackModel.response[@"room"]];
        }
        if (block) {
            block(roomModel, ackModel);
        }
    }];
}

+ (void)requestChangeVideo:(NSString *)roomID
                 urlString:(NSString *)urlString
               videoDirection:(LiveShareVideoDirection)videoDirection
                        block:(void(^)(LiveShareRoomModel *roomModel, RTSACKModel *model))block {
    
    NSDictionary *dic = @{
        @"room_id" : roomID,
        @"url" : urlString,
        @"compose" : @(videoDirection)
    };
    dic = [JoinRTSParams addTokenToParams:dic];
    
    [[LiveShareRTCManager shareRtc] emitWithAck:@"twvSetVideoUrl"
                                           with:dic
                                          block:^(RTSACKModel * _Nonnull ackModel) {
        LiveShareRoomModel *roomModel = nil;
        if ([LiveShareRTSManager ackModelResponseClass:ackModel]) {
            roomModel = [LiveShareRoomModel yy_modelWithJSON:ackModel.response[@"room"]];
        }
        if (block) {
            block(roomModel, ackModel);
        }
    }];
}

+ (void)sendMessage:(NSString *)roomID
            message:(NSString *)message
              block:(void (^)(RTSACKModel *model))block {
    
    NSString *encodedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,(CFStringRef)message,NULL,NULL,kCFStringEncodingUTF8));
    
    NSDictionary *dic = @{@"room_id" : roomID,
                          @"message" : encodedString};
    dic = [JoinRTSParams addTokenToParams:dic];
    
    [[LiveShareRTCManager shareRtc] emitWithAck:@"twvSendMsg" with:dic block:^(RTSACKModel * _Nonnull ackModel) {
        if (block) {
            block(ackModel);
        }
    }];
}

+ (void)requestChangeMediaStatus:(NSString *)roomID
                             mic:(BOOL)enableMic
                          camera:(BOOL)enableCamera
                           block:(void(^)(LiveShareUserModel *userModel, RTSACKModel *model))block {
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
                                          block:^(RTSACKModel * _Nonnull ackModel) {
        LiveShareUserModel *userModel = nil;
        if ([LiveShareRTSManager ackModelResponseClass:ackModel]) {
            userModel = [LiveShareUserModel yy_modelWithJSON:ackModel.response[@"user"]];
        }
        if (block) {
            block(userModel, ackModel);
        }
    }];
}

+ (void)clearUser:(void (^)(RTSACKModel *model))block {
    NSDictionary *dic = [JoinRTSParams addTokenToParams:nil];
    
    [[LiveShareRTCManager shareRtc] emitWithAck:@"twvClearUser" with:dic block:^(RTSACKModel * _Nonnull ackModel) {
        
        if (block) {
            block(ackModel);
        }
    }];
}

+ (void)reconnectWithBlock:(void (^)(LiveShareRoomModel *roomModel,
                                     NSArray<LiveShareUserModel *> *userList,
                                     RTSACKModel *model))block {
    NSDictionary *dic = [JoinRTSParams addTokenToParams:nil];
    
    [[LiveShareRTCManager shareRtc] emitWithAck:@"twvReconnect"
                                           with:dic
                                          block:^(RTSACKModel * _Nonnull ackModel) {
        LiveShareRoomModel *roomModel = nil;
        NSArray *userList = nil;
        if ([LiveShareRTSManager ackModelResponseClass:ackModel]) {
            roomModel = [LiveShareRoomModel yy_modelWithJSON:ackModel.response[@"room"]];
            userList = [NSArray yy_modelArrayWithClass:[LiveShareUserModel class] json:ackModel.response[@"user_list"]];
        }
        if (block) {
            block(roomModel, userList, ackModel);
        }
    }];
}

+ (void)getUserListStatusWithBlock:(void (^)(NSArray<LiveShareUserModel *> *userList,
                                             RTSACKModel *model))block {
    NSDictionary *dic = [JoinRTSParams addTokenToParams:nil];
    
    [[LiveShareRTCManager shareRtc] emitWithAck:@"twvGetUserList"
                                           with:dic
                                          block:^(RTSACKModel * _Nonnull ackModel) {
        NSArray *userList = nil;
        if ([LiveShareRTSManager ackModelResponseClass:ackModel]) {
            userList = [NSArray yy_modelArrayWithClass:[LiveShareUserModel class] json:ackModel.response[@"user_list"]];
        }
        if (block) {
            block(userList, ackModel);
        }
    }];
}

#pragma mark - Notification Message

+ (void)onUserJoinedBlock:(void(^)(LiveShareUserModel *userModel))block {
    [[LiveShareRTCManager shareRtc] onSceneListener:@"twvOnJoinRoom"
                                              block:^(RTSNoticeModel * _Nonnull
                                                      noticeModel) {
        LiveShareUserModel *userModel = nil;
        if (noticeModel.data && [noticeModel.data isKindOfClass:[NSDictionary class]]) {
            userModel = [LiveShareUserModel yy_modelWithJSON:noticeModel.data[@"user"]];
        }
        if (block) {
            block(userModel);
        }
    }];
}

+ (void)onUserLeavedBlock:(void(^)(LiveShareUserModel *userModel))block {
    [[LiveShareRTCManager shareRtc] onSceneListener:@"twvOnLeaveRoom"
                                              block:^(RTSNoticeModel * _Nonnull
                                                      noticeModel) {
        LiveShareUserModel *userModel = nil;
        
        if (noticeModel.data && [noticeModel.data isKindOfClass:[NSDictionary class]]) {
            userModel = [LiveShareUserModel yy_modelWithJSON:noticeModel.data[@"user"]];
        }
        if (block) {
            block(userModel);
        }
    }];
}

+ (void)onUpdateRoomSceneWithBlock:(void(^)(NSString *roomID, LiveShareRoomStatus roomStatus, NSString *userID,  NSString *videoURL, LiveShareVideoDirection videoDirection))block {
    [[LiveShareRTCManager shareRtc] onSceneListener:@"twvOnUpdateRoomScene"
                                              block:^(RTSNoticeModel * _Nonnull
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
    }];
}

+ (void)onRoomVideoURLUpdatedBlock:(void(^)(NSString *roomID, NSString *videoURL, NSString *userID, LiveShareVideoDirection videoDirection))block {
    [[LiveShareRTCManager shareRtc] onSceneListener:@"twvOnUpdateRoomVideoUrl"
                                              block:^(RTSNoticeModel * _Nonnull
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
    }];
}

+ (void)onUserMediaUpdatedBlock:(void(^)(NSString *roomID, LiveShareUserModel *userModel))block {
    [[LiveShareRTCManager shareRtc] onSceneListener:@"twvOnUpdateRoomMedia"
                                              block:^(RTSNoticeModel * _Nonnull
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
    }];
}

+ (void)onReceivedUserMessageBlock:(void(^)(LiveShareUserModel *userModel, NSString *message))block {
    [[LiveShareRTCManager shareRtc] onSceneListener:@"twvOnSendMessage"
                                              block:^(RTSNoticeModel * _Nonnull
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
    }];
}

+ (void)onRoomClosedBlock:(void(^)(NSString *roomID, LiveShareRoomCloseType type))block {
    [[LiveShareRTCManager shareRtc] onSceneListener:@"twvOnCloseRoom"
                                              block:^(RTSNoticeModel * _Nonnull
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
    }];
}

#pragma mark - Tool

+ (BOOL)ackModelResponseClass:(RTSACKModel *)ackModel {
    if ([ackModel.response isKindOfClass:[NSDictionary class]]) {
        return YES;
    } else {
        return NO;
    }
}

@end
