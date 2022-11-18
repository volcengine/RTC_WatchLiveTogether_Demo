//
//  LiveShareTextInputCompoments.h
//  veRTC_Demo
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LiveShareTextInputComponent : NSObject

@property(nonatomic, copy) void (^clickSenderBlock)(NSString *text);

- (void)showWithRoomModel:(LiveShareRoomModel *)roomModel;

@end

NS_ASSUME_NONNULL_END
