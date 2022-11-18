//
//  LiveShareMediaModel.m
//  veRTC_Demo
//
//

#import "LiveShareMediaModel.h"

@implementation LiveShareMediaModel

+ (instancetype)shared {
    static LiveShareMediaModel *model = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        model = [[LiveShareMediaModel alloc] init];
    });
    return model;
}

- (void)resetMediaStatus {
    self.enableAudio = YES;
    self.enableVideo = YES;
}

@end
