// 
// Copyright (c) 2023 Beijing Volcano Engine Technology Ltd.
// SPDX-License-Identifier: MIT
// 

#import <UIKit/UIKit.h>
@class LiveShareRoomModel;

NS_ASSUME_NONNULL_BEGIN

@interface LiveSharePlayViewController : UIViewController

// 退出一起看到创建房间页面
- (void)popToCreateRoomViewController;

// 退出一起看到聊天页面
- (void)popToRoomViewController;

// 房主更新播放URL
- (void)updateVideoURL;

// 更新用户渲染视图
- (void)updateUserVideoRender;

// 添加消息
// @param imModel IM model
- (void)addIMModel:(BaseIMModel *)imModel;

// 用户媒体状态更新
// @param roomID RoomID
// @param userModel User model
- (void)onUserMediaUpdated:(NSString *)roomID
                 userModel:(LiveShareUserModel *)userModel;

- (void)updateLocalUserVolume:(NSInteger)volume;

- (void)updateRemoteUserVolume:(NSDictionary *)volumeDict;

// 销毁播放资源
- (void)destroy;

@end

NS_ASSUME_NONNULL_END
