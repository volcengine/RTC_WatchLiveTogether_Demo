// 
// Copyright (c) 2023 Beijing Volcano Engine Technology Ltd.
// SPDX-License-Identifier: MIT
// 

#import "LiveShareRoomViewController+Listener.h"
#import "LiveShareRTSManager.h"

@implementation LiveShareRoomViewController (Listener)

- (void)addListener {
    __weak typeof(self) weakSelf = self;
    // 添加用户进房通知
    [LiveShareRTSManager onUserJoinedBlock:^(LiveShareUserModel * _Nonnull userModel) {
        [weakSelf onUserJoined:userModel];
    }];
    // 添加用户离房通知
    [LiveShareRTSManager onUserLeavedBlock:^(LiveShareUserModel * _Nonnull userModel) {
        [weakSelf onUserLeaved:userModel];
    }];
    // 添加房间状态改变通知
    [LiveShareRTSManager onUpdateRoomSceneWithBlock:^(NSString * _Nonnull roomID, LiveShareRoomStatus roomStatus, NSString * _Nonnull userID, NSString * _Nonnull videoURL, LiveShareVideoDirection videoDirection) {
        [weakSelf onUpdateRoomScene:roomID scene:roomStatus videoURL:videoURL videoDirection:videoDirection];
    }];
    // 添加房主更新URL通知
    [LiveShareRTSManager onRoomVideoURLUpdatedBlock:^(NSString * _Nonnull roomID, NSString * _Nonnull videoURL, NSString * _Nonnull userID, LiveShareVideoDirection videoDirection) {
        [weakSelf onRoomVideoURLUpdated:roomID userID:userID videoURL:videoURL videoDorection:videoDirection];
    }];
    // 添加用户媒体状态改变通知
    [LiveShareRTSManager onUserMediaUpdatedBlock:^(NSString * _Nonnull roomID, LiveShareUserModel * _Nonnull userModel) {
        [weakSelf onUserMediaUpdated:roomID userModel:userModel];
    }];
    // 添加用户发送消息通知
    [LiveShareRTSManager onReceivedUserMessageBlock:^(LiveShareUserModel * _Nonnull userModel, NSString * _Nonnull message) {
        [weakSelf onReceivedUserMessage:userModel message:message];
    }];
    // 添加房主关闭房间通知
    [LiveShareRTSManager onRoomClosedBlock:^(NSString * _Nonnull roomID, LiveShareRoomCloseType type) {
        [weakSelf onRoomClosed:roomID type:type];
    }];
}

@end
