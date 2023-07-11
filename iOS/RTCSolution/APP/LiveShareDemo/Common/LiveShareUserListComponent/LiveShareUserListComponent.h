// 
// Copyright (c) 2023 Beijing Volcano Engine Technology Ltd.
// SPDX-License-Identifier: MIT
// 

#import "LiveShareUserModel.h"
#import <Foundation/Foundation.h>
@class LiveShareUserListComponent;

NS_ASSUME_NONNULL_BEGIN

@interface LiveShareUserListComponent : NSObject

/// 滑动方向
@property(nonatomic, assign) UICollectionViewScrollDirection scrollDirection;

/// 是否允许切换用户到全屏
@property(nonatomic, assign) BOOL shouldSwitchFullUser;

/// 全屏视频数据源
@property(nonatomic, strong) LiveShareUserModel *_Nullable fullUserModel;

/// Initialization
/// @param superView Super view
- (instancetype)initWithSuperview:(UIView *)superView isRoomVC:(BOOL)isRoomVC;

- (void)updateData;

- (void)updateLocalUserVolume:(NSInteger)volume;

- (void)updateRemoteUserVolume:(NSDictionary *)volumeDict;

// 设置水平方向布局
- (void)layoutScrollDirectionHorizontal;

@end

NS_ASSUME_NONNULL_END
