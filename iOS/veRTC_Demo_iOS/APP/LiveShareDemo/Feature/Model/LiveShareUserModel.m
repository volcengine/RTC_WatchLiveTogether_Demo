//
//  LiveShareUserModel.m
//  LiveShareDemo
//
//

#import "LiveShareUserModel.h"

@implementation LiveShareUserModel

+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"roomID" : @"room_id",
        @"uid" : @"user_id",
        @"name" : @"user_name",
    };
}

- (BOOL)isEqual:(LiveShareUserModel *)object {
    if (self == object) {
        return YES;
    }
    if (![object isKindOfClass:[LiveShareUserModel class]]) {
        return NO;
    }
    
    if ([object.uid isEqualToString:self.uid]) {
        return YES;
    }
    return NO;
}

@end
