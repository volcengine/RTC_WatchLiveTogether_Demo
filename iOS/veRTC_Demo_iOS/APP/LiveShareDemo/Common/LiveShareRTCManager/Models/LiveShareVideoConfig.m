//
//  LiveShareVideoConfig.m
//  veRTC_Demo
//
//

#import "LiveShareVideoConfig.h"

@implementation LiveShareVideoConfig

+ (CGSize)defaultVideoSize {
    return CGSizeMake(480, 640);
}

+ (CGSize)watchingVideoSize {
    return CGSizeMake(240, 240);
}

+ (NSInteger)frameRate {
    return 15;
}

+ (NSInteger)maxKbps {
    return -1;
}

@end
