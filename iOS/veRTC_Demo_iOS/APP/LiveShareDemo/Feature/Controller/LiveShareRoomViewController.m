//
//  LiveShareChatRoomViewController.m
//  veRTC_Demo
//
//

#import "LiveShareRoomViewController.h"
#import "LiveShareRoomViewController+Listener.h"
#import "LiveShareBottomButtonsView.h"
#import "LiveShareNavView.h"
#import "LiveShareUserListComponent.h"
#import "LiveShareInputURLView.h"


#import "LiveShareRTCManager.h"
#import "SystemAuthority.h"
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
        
        [[LiveShareRTCManager shareRtc] bindCanvasViewWithUid:[LocalUserComponent userModel].uid];
        
        [self addListener];
        __weak __typeof(self) wself = self;
        [LiveShareRTCManager shareRtc].delegate = self;
        [LiveShareRTCManager shareRtc].rtcJoinRoomBlock = ^(NSString * _Nonnull roomId, NSInteger errorCode, NSInteger joinType) {
            if (errorCode == 0 && joinType != 0) {
                // 断网重连
                [wself reconnectLiveRoom];
            }
        };
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    [self setupViews];
    
    // resume local render effect
    [self.beautyCompoments resumeLocalEffect];
    
    [self loadDataWithGetUserList];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.buttonsView.enableVideo = [LiveShareMediaModel shared].enableVideo;
    self.buttonsView.enableAudio = [LiveShareMediaModel shared].enableAudio;
    [[LiveShareRTCManager shareRtc] muteLocalAudio:![LiveShareMediaModel shared].enableAudio];
    [[LiveShareRTCManager shareRtc] enableLocalVideo:[LiveShareMediaModel shared].enableVideo];
    
    // show local render view
    [self updateUserVideoRender];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [LiveShareMediaModel shared].enableVideo = self.buttonsView.enableVideo;
    [LiveShareMediaModel shared].enableAudio = self.buttonsView.enableAudio;
}

#pragma mark - LiveShareBottomButtonsViewDelegate

- (void)liveShareBottomButtonsView:(LiveShareBottomButtonsView *)view didClickButtonType:(LiveShareButtonType)type {
    switch (type) {
        case LiveShareButtonTypeAudio: {
            [self updateMediaWithMic:view.enableAudio camera:view.enableVideo];

            [[LiveShareRTCManager shareRtc] muteLocalAudio:!view.enableAudio];
        } break;

        case LiveShareButtonTypeVideo: {
            [self updateMediaWithMic:view.enableAudio camera:view.enableVideo];

            [[LiveShareRTCManager shareRtc] enableLocalVideo:view.enableVideo];
        } break;

        case LiveShareButtonTypeBeauty: {
            if (self.beautyCompoments) {
                [self.beautyCompoments showWithType:EffectBeautyRoleTypeHost
                                      fromSuperView:self.view
                                       dismissBlock:^(BOOL result){
                                       }];
            } else {
                [[ToastComponent shareToastComponent] showWithMessage:veString(@"open_souurce_code_beauty_tip")];
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

#pragma mark - notices
/// 新用户进房
/// @param userModel User model
- (void)onUserJoined:(LiveShareUserModel *)userModel {
    /// 自己进房已在进房接口添加
    if ([userModel.uid isEqualToString:[LocalUserComponent userModel].uid]) {
        return;
    }

    [[LiveShareDataManager shared] addUser:userModel];
    if (self.playController) {
        [self.playController updateUserVideoRender];

        LiveShareIMModel *model = [[LiveShareIMModel alloc] init];
        model.userModel = userModel;
        model.isJoin = YES;
        [self.playController addIMModel:model];
    } else {
        [self updateUserVideoRender];
    }
}

/// 用户退房
/// @param userModel User model
- (void)onUserLeaved:(LiveShareUserModel *)userModel {
    /// 审核被离房
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

        LiveShareIMModel *model = [[LiveShareIMModel alloc] init];
        model.userModel = userModel;
        model.isJoin = NO;
        [self.playController addIMModel:model];
    } else {
        [self updateUserVideoRender];
    }
}

/// 房间状态改变
/// @param roomID RoomID
/// @param scene Scene
/// @param videoURL Video URL
/// @param videoDirection Video direction
- (void)onUpdateRoomScene:(NSString *)roomID scene:(LiveShareRoomStatus)scene videoURL:(NSString *)videoURL videoDirection:(LiveShareVideoDirection)videoDirection {
    /// 主播在接口请求处处理
    if ([LiveShareDataManager shared].isHost) {
        return;
    }

    [LiveShareDataManager shared].roomModel.roomStatus = scene;

    /// 改变场景为聊天
    if (scene == LiveShareRoomStatusChat && self.playController) {
        [self.playController popToRoomViewController];
        return;
    }
    /// 改变场景为一起看
    if (scene == LiveShareRoomStatusShare && !self.playController) {
        [LiveShareDataManager shared].roomModel.videoURL = videoURL;
        [LiveShareDataManager shared].roomModel.videoDirection = videoDirection;
        [self pushPlayViewController];
        return;
    }
}

/// 房间直播源变更
/// @param roomID RoomID
/// @param userID UserID
/// @param videoURL Video URL
/// @param videoDirection Video direction
- (void)onRoomVideoURLUpdated:(NSString *)roomID userID:(NSString *)userID videoURL:(NSString *)videoURL videoDorection:(LiveShareVideoDirection)videoDirection {
    /// 主播在接口请求处处理
    if ([LiveShareDataManager shared].isHost) {
        return;
    }
    
    [LiveShareDataManager shared].roomModel.videoURL = videoURL;
    [LiveShareDataManager shared].roomModel.videoDirection = videoDirection;
    
    [self.playController updateVideoURL];
}

/// 用户媒体状态更新
/// @param roomID RoomID
/// @param userModel User model
- (void)onUserMediaUpdated:(NSString *)roomID userModel:(LiveShareUserModel *)userModel {
    // 更新数据源
    [[LiveShareDataManager shared] updateUserMedia:userModel];

    if (self.playController) {
        [self.playController onUserMediaUpdated:roomID userModel:userModel];
    } else {
        [self updateUserVideoRender];
    }
}

/// 收到用户消息
/// @param userModel User model
/// @param message Message
- (void)onReceivedUserMessage:(LiveShareUserModel *)userModel message:(NSString *)message {
    /// 自己发的消息不处理，发送时已经添加了
    if ([userModel.uid isEqualToString:[LocalUserComponent userModel].uid]) {
        return;
    }

    LiveShareIMModel *model = [[LiveShareIMModel alloc] init];
    NSString *imMessage = [NSString stringWithFormat:@"%@：%@",
                                                     userModel.name,
                                                     message];
    model.userModel = userModel;
    model.message = imMessage;

    [self.playController addIMModel:model];
}

/// 房间关闭
/// @param roomID RoomID
/// @param type type
- (void)onRoomClosed:(NSString *)roomID type:(LiveShareRoomCloseType)type {
    if (self.playController) {
        [self.playController popToCreateRoomViewController];
    } else {
        [self quitRoom];
    }
    
    if (type == LiveShareRoomCloseTypeReview) {
        [[ToastComponent shareToastComponent] showWithMessage:veString(@"live_closed_review") delay:0.8];
    } else {
        if ([LiveShareDataManager shared].isHost) {
            if (type == LiveShareRoomCloseTypeTimeout) {
                [[ToastComponent shareToastComponent] showWithMessage:veString(@"live_closed_timeout") delay:0.8];
            } else {
                [[ToastComponent shareToastComponent] showWithMessage:veString(@"live_closed_host") delay:0.8];
            }
        } else {
            [[ToastComponent shareToastComponent] showWithMessage:veString(@"live_closed_host") delay:0.8];
        }
    }
}

#pragma mark - load Data

- (void)reconnectLiveRoom {
    __weak __typeof(self) wself = self;
    [LiveShareRTSManager reconnectWithBlock:^(LiveShareRoomModel * _Nonnull roomModel,
                                              NSArray<LiveShareUserModel *> * _Nonnull userList,
                                              RTMACKModel * _Nonnull model) {
        if (model.result) {
            [[LiveShareDataManager shared] addUserList:userList];
            [LiveShareDataManager shared].roomModel = roomModel;
            if (wself.playController) {
                [wself.playController updateUserVideoRender];
            } else {
                [wself updateUserVideoRender];
            }
        } else if (model.code == RTMStatusCodeUserIsInactive ||
                   model.code == RTMStatusCodeRoomDisbanded ||
                   model.code == RTMStatusCodeUserNotFound) {
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
    [LiveShareRTSManager getUserListStatusWithBlock:^(NSArray<LiveShareUserModel *> * _Nonnull userList, RTMACKModel * _Nonnull model) {
        [[LiveShareDataManager shared] addUserList:userList];
        [wself updateUserVideoRender];
    }];
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

/// 更新媒体状态
/// @param enableMic 麦克风是否开启
/// @param enableCamera 摄像头是否开启
- (void)updateMediaWithMic:(BOOL)enableMic camera:(BOOL)enableCamera {
    [LiveShareRTSManager requestChangeMediaStatus:[LiveShareDataManager shared].roomModel.roomID mic:enableMic camera:enableCamera block:^(LiveShareUserModel * _Nonnull userModel, RTMACKModel * _Nonnull model) {
        if (!model.result) {
            [[ToastComponent shareToastComponent] showWithMessage:model.message];
        }
    }];
}

#pragma mark - actions
- (void)leaveButtonClick {
    if ([LiveShareDataManager shared].isHost) {
        __weak typeof(self) weakSelf = self;
        AlertActionModel *alertCancelModel = [[AlertActionModel alloc] init];
        alertCancelModel.title = veString(@"cancel");
        AlertActionModel *alertModel = [[AlertActionModel alloc] init];
        alertModel.title = veString(@"sure");
        alertModel.alertModelClickBlock = ^(UIAlertAction *_Nonnull action) {
          if ([action.title isEqualToString:veString(@"sure")]) {
              [weakSelf requestLeaveRoom];
          }
        };
        [[AlertActionManager shareAlertActionManager] showWithMessage:veString(@"exit_and_dismiss_room") actions:@[ alertCancelModel, alertModel ]];
    } else {
        [self requestLeaveRoom];
    }
}

- (void)requestLeaveRoom {
    [LiveShareRTSManager requestLeaveRoom:[LiveShareDataManager shared].roomModel.roomID block:^(RTMACKModel * _Nonnull model) {
        if (!model.result) {
            [[ToastComponent shareToastComponent] showWithMessage:model.message];
        }
    }];
    [self quitRoom];
}

- (void)quitRoom {
    [self.navigationController popViewControllerAnimated:YES];
    [[LiveShareRTCManager shareRtc] leaveChannel];
    [LiveShareDataManager destroyDataManager];
}

- (void)dealloc {
    [[LiveShareRTCManager shareRtc] leaveChannel];
    [LiveShareDataManager destroyDataManager];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    
    [[AlertActionManager shareAlertActionManager] dismiss:nil];
    
    if (self.playController) {
        [self.playController destroy];
    }
    [[LiveShareRTCManager shareRtc] leaveChannel];
}

#pragma mark - getter

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
        _navView.title = [NSString stringWithFormat:@"房间ID : %@", [LiveShareDataManager shared].roomModel.roomID];
        __weak typeof(self) weakSelf = self;
        _navView.leaveButtonTouchBlock = ^{
            [weakSelf leaveButtonClick];
        };
    }
    return _navView;
}

- (LiveShareUserListComponent *)userListComponent {
    if (!_userListComponent) {
        _userListComponent = [[LiveShareUserListComponent alloc] initWithSuperview:self.view];
        _userListComponent.shouldSwitchFullUser = YES;
    }
    return _userListComponent;
}

@end
