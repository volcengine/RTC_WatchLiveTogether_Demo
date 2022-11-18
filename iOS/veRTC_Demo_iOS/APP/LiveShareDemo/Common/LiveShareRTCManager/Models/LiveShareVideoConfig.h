//
//  LiveShareVideoConfig.h
//  veRTC_Demo
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LiveShareVideoConfig : NSObject

/// 聊天页面分辨率
+ (CGSize)defaultVideoSize;

/// 一起看页面分辨率
+ (CGSize)watchingVideoSize;

/// 帧率
+ (NSInteger)frameRate;

/// 码率
+ (NSInteger)maxKbps;

@end

NS_ASSUME_NONNULL_END
