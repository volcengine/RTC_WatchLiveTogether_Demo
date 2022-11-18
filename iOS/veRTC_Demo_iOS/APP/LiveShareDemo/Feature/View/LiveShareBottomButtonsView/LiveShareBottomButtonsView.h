//
//  LiveShareBottomButtonsView.h
//  veRTC_Demo
//
//

#import <UIKit/UIKit.h>
@class LiveShareBottomButtonsView;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, LiveShareButtonType) {
  LiveShareButtonTypeAudio = 1,
  LiveShareButtonTypeVideo = 2,
  LiveShareButtonTypeBeauty = 3,
  LiveShareButtonTypeWatch = 4,
  LiveShareButtonTypeSetting = 5,
};

typedef NS_ENUM(NSInteger, LiveShareButtonViewType) {
  LiveShareButtonViewTypePreView,
  LiveShareButtonViewTypeRoom,
  LiveShareButtonViewTypeWatch,
};

@protocol LiveShareBottomButtonsViewDelegate <NSObject>

/// 按钮点击回调
/// @param view LiveShareBottomButtonsView
/// @param type Type
- (void)liveShareBottomButtonsView:(LiveShareBottomButtonsView *)view
                didClickButtonType:(LiveShareButtonType)type;

@end

/// 底部按钮View
@interface LiveShareBottomButtonsView : UIView

@property(nonatomic, weak) id<LiveShareBottomButtonsViewDelegate> delegate;

/// 麦克风显示状态
@property(nonatomic, assign) BOOL enableAudio;
/// 摄像头显示状态
@property(nonatomic, assign) BOOL enableVideo;

/// initialize
/// @param type Type
- (instancetype)initWithType:(LiveShareButtonViewType)type;

@end

NS_ASSUME_NONNULL_END
