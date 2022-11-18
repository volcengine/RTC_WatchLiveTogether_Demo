//
//  LiveShareDataManager.h
//  LiveShareDemo
//
//

#import "LiveShareRoomModel.h"
#import "LiveShareUserModel.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LiveShareDataManager : NSObject

@property(nonatomic, strong) LiveShareRoomModel *roomModel;

@property(nonatomic, assign, readonly) BOOL isHost;

+ (instancetype)shared;

+ (void)destroyDataManager;

/// 添加用户数组
/// @param userList User list
- (void)addUserList:(NSArray<LiveShareUserModel *> *)userList;

/// 新用户加入
/// @param userModel User model
- (void)addUser:(LiveShareUserModel *)userModel;

/// 用户离开
/// @param userModel User model
- (void)removeUser:(LiveShareUserModel *)userModel;

/// 获取全屏展示的用户
- (LiveShareUserModel *)getFullUserModel;

- (LiveShareUserModel *)getLocalUserModel;

/// 获取除全屏用户外的用户列表
- (NSArray<LiveShareUserModel *> *)getUserListWithoutFullUserList;

/// 获取全部用户列表
- (NSArray<LiveShareUserModel *> *)getAllUserList;

/// 交换全屏用户
/// @param model User model
- (void)changeFullUserModelWithModel:(LiveShareUserModel *)model;

/// 用户媒体状态更新
/// @param userModel User model
- (void)updateUserMedia:(LiveShareUserModel *)userModel;

@end

NS_ASSUME_NONNULL_END
