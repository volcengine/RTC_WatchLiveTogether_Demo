// 
// Copyright (c) 2023 Beijing Volcano Engine Technology Ltd.
// SPDX-License-Identifier: MIT
// 

#import "LiveShareDataManager.h"

static LiveShareDataManager *manager = nil;
static dispatch_once_t onceToken;

@interface LiveShareDataManager ()

@property (nonatomic, strong) LiveShareUserModel *fullUserModel;

@property (nonatomic, copy) NSArray<LiveShareUserModel *> *userList;

@property (nonatomic, strong) LiveShareUserModel *localUserModel;

@end

@implementation LiveShareDataManager

+ (instancetype)shared {
    
    dispatch_once(&onceToken, ^{
        manager = [[LiveShareDataManager alloc] init];
        [manager initData];
    });
    return manager;
}

+ (void)destroyDataManager {
    manager = nil;
    onceToken = 0;
}

// 初始化数据
- (void)initData {
    self.userList = [NSMutableArray array];
}

- (void)setRoomModel:(LiveShareRoomModel *)roomModel {
    _roomModel = roomModel;
    
    _isHost = [roomModel.hostUid isEqualToString:[LocalUserComponent userModel].uid];
}

// 添加用户数组
// @param userList User list
- (void)addUserList:(NSArray<LiveShareUserModel *> *)userList {
    
    NSMutableArray *array = userList.mutableCopy;
    
    for (int i = 0; i < array.count; i++) {
        LiveShareUserModel *model = array[i];
        if ([model.uid isEqualToString:[LocalUserComponent userModel].uid]) {
            self.localUserModel = model;
            [array removeObjectAtIndex:i];
            break;
        }
    }
    self.userList = array.copy;
}
// 新用户加入
// @param userModel User model
- (void)addUser:(LiveShareUserModel *)userModel {
    NSMutableArray *array = self.userList.mutableCopy;
    NSUInteger index = [array indexOfObject:userModel];
    if (index != NSNotFound) {
        [array replaceObjectAtIndex:index withObject:userModel];
    }
    else {
        [array addObject:userModel];
    }
    self.userList = array.copy;
}
// 用户离开
// @param userModel User model
- (void)removeUser:(LiveShareUserModel *)userModel {
    NSMutableArray *array = self.userList.mutableCopy;
    [array removeObject:userModel];
    self.userList = array.copy;
}
// 获取全屏展示的用户
- (LiveShareUserModel *)getFullUserModel {
    NSUInteger index = [self.userList indexOfObject:self.fullUserModel];
    if (index == NSNotFound) {
        self.fullUserModel = self.localUserModel;
    }
    else {
        self.fullUserModel = self.userList[index];
    }
    return self.fullUserModel;
}
// 获取除全屏用户外的用户列表
- (NSArray<LiveShareUserModel *> *)getUserListWithoutFullUserList {
    NSMutableArray *array = self.userList.mutableCopy;
    [array removeObject:self.fullUserModel];
    return array.copy;
}
// 获取全部用户列表
- (NSArray<LiveShareUserModel *> *)getAllUserList {
    return self.userList;
}
// 交换全屏用户
// @param model User model
- (void)changeFullUserModelWithModel:(LiveShareUserModel *)model {
    self.fullUserModel = model;
}

// 用户媒体状态更新
// @param userModel User model
- (void)updateUserMedia:(LiveShareUserModel *)userModel {
    
    if ([userModel.uid isEqualToString:[LocalUserComponent userModel].uid]) {
        self.localUserModel = userModel;
    }
    else {
        NSUInteger index = [self.userList indexOfObject:userModel];
        if (index == NSNotFound) {
            return;
        }
        NSMutableArray *array = self.userList.mutableCopy;
        [array replaceObjectAtIndex:index withObject:userModel];
        self.userList = array.copy;
    }
}

- (LiveShareUserModel *)getLocalUserModel {
    return self.localUserModel;
}

@end
