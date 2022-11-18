//
//  LiveShareIMCompoments.h
//  veRTC_Demo
//
//

#import "LiveShareIMModel.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LiveShareIMComponent : NSObject

@property(nonatomic, assign) BOOL hidden;

- (instancetype)initWithSuperView:(UIView *)superView;

- (void)addIM:(LiveShareIMModel *)model;

@end

NS_ASSUME_NONNULL_END
