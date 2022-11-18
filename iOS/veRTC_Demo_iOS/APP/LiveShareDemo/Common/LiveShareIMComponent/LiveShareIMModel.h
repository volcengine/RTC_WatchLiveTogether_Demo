//
//  LiveShareIMModel.h
//  veRTC_Demo
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LiveShareIMModel : NSObject

@property(nonatomic, assign) BOOL isJoin;

@property(nonatomic, strong) NSString *message;

@property(nonatomic, strong) LiveShareUserModel *userModel;

@end

NS_ASSUME_NONNULL_END
