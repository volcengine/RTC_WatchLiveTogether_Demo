// 
// Copyright (c) 2023 Beijing Volcano Engine Technology Ltd.
// SPDX-License-Identifier: MIT
// 

#import "LiveShareDemo.h"
#import "LiveShareRTCManager.h"
#import "LiveShareCreateRoomViewController.h"
#import "JoinRTSInputModel.h"
#import "JoinRTSParams.h"

@implementation LiveShareDemo

- (void)pushDemoViewControllerBlock:(void (^)(BOOL result))block {
    [super pushDemoViewControllerBlock:block];
    
    // 获取登录 RTS 参数
    JoinRTSInputModel *inputModel = [[JoinRTSInputModel alloc] init];
    inputModel.scenesName = self.scenesName;
    inputModel.loginToken = [LocalUserComponent userModel].loginToken;
    __weak __typeof(self) wself = self;
    [JoinRTSParams getJoinRTSParams:inputModel
                             block:^(JoinRTSParamsModel * _Nonnull model) {
        [wself joinRTS:model block:block];
    }];
}

- (void)joinRTS:(JoinRTSParamsModel * _Nonnull)model
          block:(void (^)(BOOL result))block{
    if (!model) {
        [[ToastComponent shareToastComponent] showWithMessage:LocalizedString(@"connection_failed")];
        if (block) {
            block(NO);
        }
        return;
    }
    [[LiveShareRTCManager shareRtc] connect:model.appId
                                   RTSToken:model.RTSToken
                                  serverUrl:model.serverUrl
                                  serverSig:model.serverSignature
                                        bid:model.bid
                                      block:^(BOOL result) {
        if (result) {
            LiveShareCreateRoomViewController *next = [[LiveShareCreateRoomViewController alloc] init];
            UIViewController *topVC = [DeviceInforTool topViewController];
            [topVC.navigationController pushViewController:next animated:YES];
        } else {
            [[ToastComponent shareToastComponent] showWithMessage:LocalizedString(@"connection_failed")];
        }
        if (block) {
            block(result);
        }
    }];
}

@end
