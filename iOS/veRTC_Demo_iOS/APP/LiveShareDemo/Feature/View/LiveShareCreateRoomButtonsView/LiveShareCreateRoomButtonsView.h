//
//  FeedShareBottomButtonsView.h
//  veRTC_Demo
//
//  Created by bytedance on 2022/1/5.
//  Copyright © 2022 bytedance. All rights reserved.
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
