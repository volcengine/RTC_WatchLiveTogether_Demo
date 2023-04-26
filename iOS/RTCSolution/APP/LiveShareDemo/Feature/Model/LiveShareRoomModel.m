// 
// Copyright (c) 2023 Beijing Volcano Engine Technology Ltd.
// SPDX-License-Identifier: MIT
// 

#import "LiveShareRoomModel.h"

@implementation LiveShareRoomModel

+ (NSDictionary *)modelCustomPropertyMapper {
    return @{@"appID" : @"app_id",
             @"roomID" : @"room_id",
             @"hostUid" : @"host_user_id",
             @"hostName" : @"host_user_name",
             @"roomStatus" : @"scene",
             @"rtcToken" : @"rtc_token",
             @"videoURL" : @"video_url",
             @"videoDirection" : @"compose"
    };
}

- (instancetype)init {
    if (self = [super init]) {
        self.roomStatus = LiveShareRoomStatusChat;
    }
    return self;
}

@end
