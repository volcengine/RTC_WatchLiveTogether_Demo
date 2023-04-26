// 
// Copyright (c) 2023 Beijing Volcano Engine Technology Ltd.
// SPDX-License-Identifier: MIT
// 

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LiveShareTextInputComponent : NSObject

@property(nonatomic, copy) void (^clickSenderBlock)(NSString *text);

- (void)showWithRoomModel:(LiveShareRoomModel *)roomModel;

@end

NS_ASSUME_NONNULL_END
