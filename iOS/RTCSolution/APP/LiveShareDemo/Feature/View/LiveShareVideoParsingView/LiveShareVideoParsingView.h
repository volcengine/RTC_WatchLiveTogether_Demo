// 
// Copyright (c) 2023 Beijing Volcano Engine Technology Ltd.
// SPDX-License-Identifier: MIT
// 

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// 直播URL解析中View
@interface LiveShareVideoParsingView : UIView

// 取消直播URL解析Block
@property(nonatomic, copy) void (^onCancelParsingBlock)(void);

// 展示直播URL解析Loading
// @param view Super view
- (void)showInview:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
