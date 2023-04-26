// 
// Copyright (c) 2023 Beijing Volcano Engine Technology Ltd.
// SPDX-License-Identifier: MIT
// 

#import "LiveShareBottomButtonsView.h"
#import <UIKit/UIKit.h>
@class LiveShareCreateRoomButtonsView;

NS_ASSUME_NONNULL_BEGIN

@protocol LiveShareCreateRoomButtonsViewDelegate <NSObject>

- (void)liveShareCreateRoomButtonsView:(LiveShareCreateRoomButtonsView *)view
                    didClickButtonType:(LiveShareButtonType)type;

@end

@interface LiveShareCreateRoomButtonsView : UIView

@property(nonatomic, weak) id<LiveShareCreateRoomButtonsViewDelegate> delegate;

@property(nonatomic, assign) BOOL enableAudio;
@property(nonatomic, assign) BOOL enableVideo;

@end

NS_ASSUME_NONNULL_END
