// 
// Copyright (c) 2023 Beijing Volcano Engine Technology Ltd.
// SPDX-License-Identifier: MIT
// 

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 媒体状态同步模型
 */
@interface LiveShareMediaModel : NSObject

@property(nonatomic, assign) BOOL enableAudio;

@property(nonatomic, assign) BOOL enableVideo;

+ (instancetype)shared;

- (void)resetMediaStatus;

@end

NS_ASSUME_NONNULL_END
