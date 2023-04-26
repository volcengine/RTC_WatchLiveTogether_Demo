// 
// Copyright (c) 2023 Beijing Volcano Engine Technology Ltd.
// SPDX-License-Identifier: MIT
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
