// 
// Copyright (c) 2023 Beijing Volcano Engine Technology Ltd.
// SPDX-License-Identifier: MIT
// 

#import <Foundation/Foundation.h>
@class LiveShareVideoComponent;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, LiveShareVideoState) {
  // 加载成功
  LiveShareVideoStateSuccess,
  // 加载失败
  LiveShareVideoStateFailure,
  // 播放完成
  LiveShareVideoStateCompleted,
};

@protocol LiveShareVideoComponentDelegate <NSObject>

// 直播加载状态回调
// @param videoComponent LiveShareVideoComponent
// @param state LiveShareVideoState
// @param error Error
- (void)liveShareVideoComponent:(LiveShareVideoComponent *)videoComponent
            onVideoStateChanged:(LiveShareVideoState)state
                          error:(NSError *)error;

@end

// 直播播放组件
@interface LiveShareVideoComponent : NSObject

@property(nonatomic, weak) id<LiveShareVideoComponentDelegate> delegate;

- (instancetype)initWithSuperview:(UIView *)superView;

// 开始播放
// @param urlString URL string
- (void)playWihtURLString:(NSString *)urlString;

// 停止播放
- (void)stop;

// 关闭播放器
- (void)close;

@end

NS_ASSUME_NONNULL_END
