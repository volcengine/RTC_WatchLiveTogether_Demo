//
//  LiveShareMediaModel.h
//  veRTC_Demo
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 媒体状态同步
@interface LiveShareMediaModel : NSObject

/// 是否开启麦克风
@property(nonatomic, assign) BOOL enableAudio;

/// 是否开启摄像头
@property(nonatomic, assign) BOOL enableVideo;

+ (instancetype)shared;

- (void)resetMediaStatus;

@end

NS_ASSUME_NONNULL_END
