// 
// Copyright (c) 2023 Beijing Volcano Engine Technology Ltd.
// SPDX-License-Identifier: MIT
// 

#import "LiveShareVideoConfigModel.h"

@implementation LiveShareVideoConfigModel

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
