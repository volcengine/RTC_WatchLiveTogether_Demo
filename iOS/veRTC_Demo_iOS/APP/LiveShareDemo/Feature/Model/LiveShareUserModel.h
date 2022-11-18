//
//  LiveShareUserModel.h
//  LiveShareDemo
//
//

#import "BaseUserModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, LiveShareUserMic) {
  LiveShareUserMicOff = 0,
  LiveShareUserMicOn = 1,
};

typedef NS_ENUM(NSInteger, LiveShareUserCamera) {
  LiveShareUserCameraOff = 0,
  LiveShareUserCameraOn = 1,
};

@interface LiveShareUserModel : BaseUserModel

@property(nonatomic, copy) NSString *roomID;

@property(nonatomic, assign) LiveShareUserMic mic;

@property(nonatomic, assign) LiveShareUserCamera camera;

@end

NS_ASSUME_NONNULL_END
