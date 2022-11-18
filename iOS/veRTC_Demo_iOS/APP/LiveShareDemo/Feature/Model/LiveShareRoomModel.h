//
//  LiveShareRoomModel.h
//  veRTC_Demo
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, LiveShareRoomStatus) {
  LiveShareRoomStatusChat = 1,
  LiveShareRoomStatusShare = 2,
};

/// 视频方向
typedef NS_ENUM(NSInteger, LiveShareVideoDirection) {
  /// 横屏视频
  LiveShareVideoDirectionHorizontal = 1,
  /// 竖屏视频
  LiveShareVideoDirectionVertical = 2,
};

@interface LiveShareRoomModel : NSObject

@property(nonatomic, copy) NSString *appID;
@property(nonatomic, copy) NSString *roomID;
@property(nonatomic, copy) NSString *hostUid;
@property(nonatomic, copy) NSString *hostName;
@property(nonatomic, assign) LiveShareRoomStatus roomStatus;
@property(nonatomic, copy) NSString *rtcToken;

/// 视频播放链接
@property(nonatomic, copy) NSString *videoURL;

/// 视频方向
@property(nonatomic, assign) LiveShareVideoDirection videoDirection;

@end

NS_ASSUME_NONNULL_END
