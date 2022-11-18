//
//  LiveShareNavView.h
//  veRTC_Demo
//
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LiveShareNavView : UIView

@property(nonatomic, copy) NSString *title;
@property(nonatomic, copy) void (^leaveButtonTouchBlock)(void);

@end

NS_ASSUME_NONNULL_END
