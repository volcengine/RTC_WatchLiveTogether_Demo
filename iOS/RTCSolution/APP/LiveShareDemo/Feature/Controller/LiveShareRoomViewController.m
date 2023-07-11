// 
// Copyright (c) 2023 Beijing Volcano Engine Technology Ltd.
// SPDX-License-Identifier: MIT
// 

#import "LiveShareRoomViewController.h"
#import "LiveShareRoomViewController+Listener.h"
#import "LiveShareUserListComponent.h"
#import "LiveShareBottomButtonsView.h"
#import "LiveShareInputURLView.h"
#import "LiveShareNavView.h"
#import "LiveShareRTCManager.h"
#import "LiveShareRTSManager.h"
#import "LiveShareMediaModel.h"
#import "BytedEffectProtocol.h"

@interface LiveShareRoomViewController ()
<
LiveShareBottomButtonsViewDelegate,
LiveShareRTCManagerDelegate
>

@property (nonatomic, strong) LiveShareNavView *navView;
@property (nonatomic, strong) LiveShareBottomButtonsView *buttonsView;
@property (nonatomic, strong) BytedEffectProtocol *beautyCompoments;
@property (nonatomic, strong) LiveShareUserListComponent *userListComponent;

@end

@implementation LiveShareRoomViewController

- (instancetype)init {
    if (self = [super init]) {
        [UIApplication sharedApplication].idleTimerDisabled = YES;
        [self addListener];
        [[LiveShareRTCManager shareRtc] bindCanvasViewWithUid:[LocalUserComponent userModel].uid];
        [LiveShareRTCManager shareRtc].delegate = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    [self setupViews];
    // 开启美颜
    [self.beautyCompoments resume];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.buttonsView.enableVideo = [LiveShareMediaModel shared].enableVideo;
    self.buttonsView.enableAudio = [LiveShareMediaModel shared].enableAudio;
    // 根据预览页配置，开启/关闭音频推流。
    // 因为麦克风采集频繁开启/关闭影响通话效果，所以采用控制音频推流方案。
    [[LiveShareRTCManager shareRtc] publishAudioStream:[LiveShareMediaModel shared].enableAudio];
    // 根据预览页配置，开启/关闭相机采集
    [[LiveShareRTCManager shareRtc] switchVideoCapture:[LiveShareMediaModel shared].enableVideo];
    [self updateUserVideoRender];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [LiveShareMediaModel shared].enableVideo = self.buttonsView.enableVideo;
    [LiveShareMediaModel shared].enableAudio = self.buttonsView.enableAudio;
}

- (void)viewDidLayoutSubviews {
    [self.navView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.equalTo(self.view);
        make.height.mas_equalTo([DeviceInforTool getStatusBarHight] + 44);
    }];
    [self.userListComponent layoutScrollDirectionHorizontal];
}

#pragma mark - RTS Listener

- (void)onUserJoined:(LiveShareUserModel *)userModel {
    // 屏蔽自己进房。自己进房已在进房接口添加
    if ([userModel.uid isEqualToString:[LocalUserComponent userModel].uid]) {
        return;
    }

    [[LiveShareDataManager shared] addUser:userModel];
    if (self.playController) {
        [self.playController updateUserVideoRender];
        NSString *message = [NSString stringWithFormat:@"%@ %@",
                             userModel.name,
                             LocalizedString(@"live_joined_the_room")];
        BaseIMModel *model = [[BaseIMModel alloc] init];
        model.message = message;
        [self.playController addIMModel:model];
    } else {
        [self updateUserVideoRender];
    }
}

- (void)onUserLeaved:(LiveShareUserModel *)userModel {
    if ([userModel.uid isEqualToString:[LocalUserComponent userModel].uid]) {
        if (self.playController) {
            [self.playController popToCreateRoomViewController];
        } else {
            [self quitRoom];
        }
        return;
    }

    [[LiveShareDataManager shared] removeUser:userModel];
    if (self.playController) {
        [self.playController updateUserVideoRender];

        NSString *message = [NSString stringWithFormat:@"%@ %@",
                             userModel.name,
                             LocalizedString(@"live_left_room")];
        BaseIMModel *model = [[BaseIMModel alloc] init];
        model.message = message;
        [self.playController addIMModel:model];
    } else {
        [self updateUserVideoRender];
    }
}

- (void)onUpdateRoomScene:(NSString *)roomID scene:(LiveShareRoomStatus)scene videoURL:(NSString *)videoURL videoDirection:(LiveShareVideoDirection)videoDirection {
    if ([LiveShareDataManager shared].isHost) {
        return;
    }

    [LiveShareDataManager shared].roomModel.roomStatus = scene;
    // 改变场景为聊天
    if (scene == LiveShareRoomStatusChat && self.playController) {
        [self.playController popToRoomViewController];
        return;
    }
    // 改变场景为一起看
    if (scene == LiveShareRoomStatusShare && !self.playController) {
        [LiveShareDataManager shared].roomModel.videoURL = videoURL;
        [LiveShareDataManager shared].roomModel.videoDirection = videoDirection;
        [self pushPlayViewController];
        return;
    }
}

- (void)onRoomVideoURLUpdated:(NSString *)roomID userID:(NSString *)userID videoURL:(NSString *)videoURL videoDorection:(LiveShareVideoDirection)videoDirection {
    if ([LiveShareDataManager shared].isHost) {
        return;
    }
    [LiveShareDataManager shared].roomModel.videoURL = videoURL;
    [LiveShareDataManager shared].roomModel.videoDirection = videoDirection;
    [self.playController updateVideoURL];
}

- (void)onUserMediaUpdated:(NSString *)roomID userModel:(LiveShareUserModel *)userModel {
    [[LiveShareDataManager shared] updateUserMedia:userModel];
    if (self.playController) {
        [self.playController onUserMediaUpdated:roomID userModel:userModel];
    } else {
        [self updateUserVideoRender];
    }
}

- (void)onReceivedUserMessage:(LiveShareUserModel *)userModel message:(NSString *)message {
    // 屏蔽自己发的消息，在发送时已在本地添加了。
    if ([userModel.uid isEqualToString:[LocalUserComponent userModel].uid]) {
        return;
    }

    BaseIMModel *model = [[BaseIMModel alloc] init];
    NSString *imMessage = [NSString stringWithFormat:@"%@：%@",
                                                     userModel.name,
                                                     message];
    model.message = imMessage;
    [self.playController addIMModel:model];
}

- (void)onRoomClosed:(NSString *)roomID type:(LiveShareRoomCloseType)type {
    if (type == LiveShareRoomCloseTypeReview) {
        [[ToastComponent shareToastComponent] showWithMessage:LocalizedString(@"live_ended_please_enter_new") delay:0.8];
    } else {
        if ([LiveShareDataManager shared].isHost) {
            if (type == LiveShareRoomCloseTypeTimeout) {
                [[ToastComponent shareToastComponent] showWithMessage:LocalizedString(@"duration_live_has_eached_minutes") delay:0.8];
            } else {
                [[ToastComponent shareToastComponent] showWithMessage:LocalizedString(@"room_is_closed") delay:0.8];
            }
        } else {
            [[ToastComponent shareToastComponent] showWithMessage:LocalizedString(@"room_is_closed") delay:0.8];
        }
    }
    
    if (self.playController) {
        [self.playController popToCreateRoomViewController];
    } else {
        [self quitRoom];
    }
}

#pragma mark - Load Data

- (void)reconnectLiveRoom {
    __weak __typeof(self) wself = self;
    [LiveShareRTSManager reconnectWithBlock:^(LiveShareRoomModel * _Nonnull roomModel,
                                              NSArray<LiveShareUserModel *> * _Nonnull userList,
                                              RTSACKModel * _Nonnull model) {
        if (model.result) {
            [[LiveShareDataManager shared] addUserList:userList];
            [LiveShareDataManager shared].roomModel = roomModel;
            if (wself.playController) {
                [wself.playController updateUserVideoRender];
            } else {
                [wself updateUserVideoRender];
            }
        } else if (model.code == RTSStatusCodeUserIsInactive ||
                   model.code == RTSStatusCodeRoomDisbanded ||
                   model.code == RTSStatusCodeUserNotFound) {
            if (wself.playController) {
                [wself.playController popToCreateRoomViewController];
            } else {
                [wself quitRoom];
            }
            [[ToastComponent shareToastComponent] showWithMessage:model.message delay:0.8];
        }
    }];
}

- (void)loadDataWithGetUserList {
    __weak __typeof(self) wself = self;
    [LiveShareRTSManager getUserListStatusWithBlock:^(NSArray<LiveShareUserModel *> * _Nonnull userList, RTSACKModel * _Nonnull model) {
        [[LiveShareDataManager shared] addUserList:userList];
        if (wself.playController) {
            [wself.playController updateUserVideoRender];
        } else {
            [wself updateUserVideoRender];
        }
    }];
}

#pragma mark - LiveShareBottomButtonsViewDelegate

- (void)liveShareBottomButtonsView:(LiveShareBottomButtonsView *)view didClickButtonType:(LiveShareButtonType)type {
    switch (type) {
        case LiveShareButtonTypeAudio: {
            [self updateMediaWithMic:view.enableAudio camera:view.enableVideo];

            [[LiveShareRTCManager shareRtc] publishAudioStream:view.enableAudio];
        } break;

        case LiveShareButtonTypeVideo: {
            [self updateMediaWithMic:view.enableAudio camera:view.enableVideo];

            [[LiveShareRTCManager shareRtc] switchVideoCapture:view.enableVideo];
        } break;

        case LiveShareButtonTypeBeauty: {
            if (self.beautyCompoments) {
                [self.beautyCompoments showWithView:self.view
                                       dismissBlock:^(BOOL result){}];
            } else {
                [[ToastComponent shareToastComponent] showWithMessage:LocalizedString(@"not_support_beauty_error")];
            }
        } break;

        case LiveShareButtonTypeWatch: {
            LiveShareInputURLView *inputView = [[LiveShareInputURLView alloc] init];
            [inputView showInview:self.view];
            __weak typeof(self) weakSelf = self;
            inputView.onUserInputVideoURLBlock = ^(NSString *_Nonnull videoURL, LiveShareVideoDirection videoDirection) {
              [LiveShareDataManager shared].roomModel.videoURL = videoURL;
              [LiveShareDataManager shared].roomModel.videoDirection = videoDirection;

              [weakSelf pushPlayViewController];
            };
        } break;

        default:
            break;
    }
}

#pragma mark - LiveShareRTCManagerDelegate

- (void)liveShareRTCManager:(LiveShareRTCManager *)manager
         onRoomStateChanged:(RTCJoinModel *)joinModel {
    if (joinModel.errorCode == 0) {
        if (joinModel.joinType == 0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self loadDataWithGetUserList];
            });
        } else {
            // 断网重连
            [self reconnectLiveRoom];
        }
    }
}

- (void)liveShareRTCManager:(LiveShareRTCManager *)manager onFirstRemoteVideoFrameDecoded:(NSString *)userID {
    if (self.playController) {
        [self.playController updateUserVideoRender];
    } else {
        [self updateUserVideoRender];
    }
}

- (void)liveShareRTCManager:(LiveShareRTCManager *)manager onLocalAudioPropertiesReport:(NSInteger)volume {
    if (self.playController) {
        [self.playController updateLocalUserVolume:volume];
    } else {
        [self.userListComponent updateLocalUserVolume:volume];
    }
}

- (void)liveShareRTCManager:(LiveShareRTCManager *)manager onReportRemoteUserAudioVolume:(NSDictionary<NSString *,NSNumber *> *)volumeInfo {
    if (self.playController) {
        [self.playController updateRemoteUserVolume:volumeInfo];
    } else {
        [self.userListComponent updateRemoteUserVolume:volumeInfo];
    }
}

#pragma mark - Private Action

- (void)setupViews {
    [self userListComponent];
    
    [self.view addSubview:self.navView];
    [self.view addSubview:self.buttonsView];
    [self.buttonsView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.mas_equalTo(-10 - [DeviceInforTool getVirtualHomeHeight]);
    }];
}

- (void)pushPlayViewController {
    LiveSharePlayViewController *ctrl = [[LiveSharePlayViewController alloc] init];
    self.playController = ctrl;
    [self.navigationController pushViewController:ctrl animated:YES];
}

- (void)updateUserVideoRender {
    [self.userListComponent updateData];
}

- (void)updateMediaWithMic:(BOOL)enableMic camera:(BOOL)enableCamera {
    [LiveShareRTSManager requestChangeMediaStatus:[LiveShareDataManager shared].roomModel.roomID mic:enableMic camera:enableCamera block:^(LiveShareUserModel * _Nonnull userModel, RTSACKModel * _Nonnull model) {
        if (!model.result) {
            [[ToastComponent shareToastComponent] showWithMessage:model.message];
        }
    }];
}

- (void)leaveButtonClick {
    if ([LiveShareDataManager shared].isHost) {
        __weak typeof(self) weakSelf = self;
        AlertActionModel *alertCancelModel = [[AlertActionModel alloc] init];
        alertCancelModel.title = LocalizedString(@"cancel");
        AlertActionModel *alertModel = [[AlertActionModel alloc] init];
        alertModel.title = LocalizedString(@"ok");
        alertModel.alertModelClickBlock = ^(UIAlertAction *_Nonnull action) {
          if ([action.title isEqualToString:LocalizedString(@"ok")]) {
              [weakSelf requestLeaveRoom];
          }
        };
        [[AlertActionManager shareAlertActionManager] showWithMessage:LocalizedString(@"are_you_sure_to_exit_room") actions:@[ alertCancelModel, alertModel ]];
    } else {
        [self requestLeaveRoom];
    }
}

- (void)requestLeaveRoom {
    [LiveShareRTSManager requestLeaveRoom:[LiveShareDataManager shared].roomModel.roomID block:^(RTSACKModel * _Nonnull model) {
        if (!model.result) {
            [[ToastComponent shareToastComponent] showWithMessage:model.message];
        }
    }];
    [self quitRoom];
}

- (void)quitRoom {
    [self.navigationController popViewControllerAnimated:YES];
    [[LiveShareRTCManager shareRtc] leaveRTCRoom];
    [LiveShareDataManager destroyDataManager];
}

#pragma mark - Getter

- (BytedEffectProtocol *)beautyCompoments {
    if (!_beautyCompoments) {
        _beautyCompoments = [[BytedEffectProtocol alloc] initWithRTCEngineKit:[LiveShareRTCManager shareRtc].rtcEngineKit];
    }
    return _beautyCompoments;
}

- (LiveShareBottomButtonsView *)buttonsView {
    if (!_buttonsView) {
        _buttonsView = [[LiveShareBottomButtonsView alloc] initWithType:LiveShareButtonViewTypeRoom];
        _buttonsView.delegate = self;
    }
    return _buttonsView;
}

- (LiveShareNavView *)navView {
    if (!_navView) {
        _navView = [[LiveShareNavView alloc] init];
        _navView.title = [NSString stringWithFormat:LocalizedString(@"live_room_id_:%@"), [LiveShareDataManager shared].roomModel.roomID];
        __weak typeof(self) weakSelf = self;
        _navView.leaveButtonTouchBlock = ^{
            [weakSelf leaveButtonClick];
        };
    }
    return _navView;
}

- (LiveShareUserListComponent *)userListComponent {
    if (!_userListComponent) {
        _userListComponent = [[LiveShareUserListComponent alloc] initWithSuperview:self.view isRoomVC:YES];
        _userListComponent.shouldSwitchFullUser = YES;
    }
    return _userListComponent;
}

- (void)dealloc {
    [[LiveShareRTCManager shareRtc] leaveRTCRoom];
    [LiveShareDataManager destroyDataManager];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    
    [[AlertActionManager shareAlertActionManager] dismiss:nil];
    
    if (self.playController) {
        [self.playController destroy];
    }
    [[LiveShareRTCManager shareRtc] leaveRTCRoom];
}

@end
