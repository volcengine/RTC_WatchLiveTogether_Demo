//
//  LiveShareInputURLView.h
//  LiveShareDemo
//
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 输入URL、选择横竖屏
@interface LiveShareInputURLView : UIView

@property(nonatomic, copy) void (^onUserInputVideoURLBlock)
    (NSString *videoURL, LiveShareVideoDirection videoDirection);

- (void)showInview:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
