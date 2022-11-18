//
//  LiveSharePlayViewController.m
//  veRTC_Demo
//
//

#import "LiveSharePlayViewController.h"
#import "LiveShareNavView.h"
#import "LiveShareBottomButtonsView.h"
#import "LiveShareVolumeView.h"
#import "LiveShareIMComponent.h"
#import "LiveShareTextInputComponent.h"
#import "LiveShareVideoComponent.h"
#import "LiveShareUserListComponent.h"

#import "LiveShareRoomModel.h"
#import "LiveShareRTCManager.h"
#import "SystemAuthority.h"
#import "LiveShareMediaModel.h"
#import "LiveShareRTSManager.h"
#import "BytedEffectProtocol.h"
#import "UIViewController+Orientation.h"
#import "LiveShareVideoParsingView.h"
#import "LiveShareInputURLView.h"

@interface LiveSharePlayViewController ()
<
LiveShareBottomButtonsViewDelegate,
LiveShareVideoComponentDelegate
>

@property (nonatomic, strong) LiveShareNavView *navView;
@property (nonatomic, strong) LiveShareBottomButtonsView *buttonsView;
@property (nonatomic, strong) LiveShareVolumeView *volumeView;
@property (nonatomic, strong) UIView *inputMessageView;
@property (nonatomic, strong) UIView *fullScreenView;
@property (nonatomic, strong) LiveShareVideoParsingView *videoParsingView;

@property (nonatomic, strong) BytedEffectProtocol *beautyCompoments;
@property (nonatomic, strong) LiveShareTextInputComponent *textInputCompoments;
@property (nonatomic, strong) LiveShareIMComponent *imCompoments;
@property (nonatomic, strong) LiveShareVideoComponent *videoComponent;
@property (nonatomic, strong) LiveShareUserListComponent *userListComponent;
/// 返回竖屏状态
@property (nonatomic, strong) UIButton *backButton;

@end

@implementation LiveSharePlayViewController

- (void)dealloc {
    [self destroy];
    [[LiveShareRTCManager shareRtc] stopAudioMixing];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    [self setupViews];
    
    // resume local render effect
    [self.beautyCompoments resumeLocalEffect];
    
    [[LiveShareRTCManager shareRtc] startAudioMixing];
    
    [self addOrientationNotice];
    
    [self handelPortraitUI];
    
    [self startPlayVideo];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
    
    self.buttonsView.enableVideo = [LiveShareMediaModel shared].enableVideo;
    self.buttonsView.enableAudio = [LiveShareMediaModel shared].enableAudio;
    [[LiveShareRTCManager shareRtc] muteLocalAudio:![LiveShareMediaModel shared].enableAudio];
    [[LiveShareRTCManager shareRtc] enableLocalVideo:[LiveShareMediaModel shared].enableVideo];
    
    [self updateUserVideoRender];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [LiveShareMediaModel shared].enableVideo = self.buttonsView.enableVideo;
    [LiveShareMediaModel shared].enableAudio = self.buttonsView.enableAudio;
    
    [self setAllowAutoRotate:ScreenOrientationPortrait];
    [self setScreenPortrait];
}

#pragma mark - LiveShareBottomButtonsViewDelegate
- (void)liveShareBottomButtonsView:(LiveShareBottomButtonsView *)view didClickButtonType:(LiveShareButtonType)type {
    switch (type) {
        case LiveShareButtonTypeAudio: {
            
            [self updateMediaWithMic:view.enableAudio camera:view.enableVideo];
            
            [[LiveShareRTCManager shareRtc] muteLocalAudio:!view.enableAudio];
        }
            break;
            
        case LiveShareButtonTypeVideo: {
            
            [self updateMediaWithMic:view.enableAudio camera:view.enableVideo];
            
            [[LiveShareRTCManager shareRtc] enableLocalVideo:view.enableVideo];
        }
            break;
            
        case LiveShareButtonTypeBeauty: {
            if (self.beautyCompoments) {
                [self.beautyCompoments showWithType:EffectBeautyRoleTypeHost fromSuperView:self.view dismissBlock:^(BOOL result) {
                    
                }];
            } else {
                [[ToastComponent shareToastComponent] showWithMessage:veString(@"open_souurce_code_beauty_tip")];
            }
        }
            break;
            
        case LiveShareButtonTypeSetting: {
            [self.volumeView showinView:self.view];
        }
            break;
        case LiveShareButtonTypeWatch: {
            LiveShareInputURLView *inputView = [[LiveShareInputURLView alloc] init];
            [inputView showInview:self.view];
            __weak typeof(self) weakSelf = self;
            inputView.onUserInputVideoURLBlock = ^(NSString * _Nonnull videoURL, LiveShareVideoDirection videoDirection) {
                [LiveShareDataManager shared].roomModel.videoURL = videoURL;
                [LiveShareDataManager shared].roomModel.videoDirection = videoDirection;
                [weakSelf updateVideoURL];
                
                [weakSelf requestChangeLiveURLToServer];
            };
        }
            break;
            
        default:
            break;
    }
}

#pragma mark - LiveShareVideoComponentDelegate
- (void)liveShareVideoComponent:(LiveShareVideoComponent *)videoComponent onVideoStateChanged:(LiveShareVideoState)state error:(NSError *)error {
    
    if (![LiveShareDataManager shared].isHost) {
        return;
    }
    
    switch (state) {
        case LiveShareVideoStateSuccess: {
            [self handleVideoLoadSuccess];
        }
            break;
        case LiveShareVideoStateFailure: {
            [self handleVideoLoadFailure];
        }
            break;
        case LiveShareVideoStateCompleted: {
            [self handleVideoPlayComplete];
        }
            break;
            
        default:
            break;
    }
}

#pragma mark - orientation

/// 横竖屏切换通知
/// @param isLandscape 是否是横屏
- (void)orientationDidChang:(BOOL)isLandscape {
    if (isLandscape) {
        [self handleLandscapeUI];
    }
    else {
        [self handelPortraitUI];
    }
}

/// 竖屏状态UI展示
- (void)handelPortraitUI {
    self.backButton.hidden = YES;
    self.fullScreenView.hidden = ([LiveShareDataManager shared].roomModel.videoDirection == LiveShareVideoDirectionVertical);
    self.userListComponent.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
    self.imCompoments.hidden = NO;
    self.inputMessageView.hidden = NO;
    self.buttonsView.hidden = NO;
    self.navView.hidden = NO;
    
    /// 横屏视频支持旋转
    if ([LiveShareDataManager shared].roomModel.videoDirection == LiveShareVideoDirectionHorizontal) {
        [self setAllowAutoRotate:ScreenOrientationLandscapeAndPortrait];
    }
}

/// 横屏状态UI展示
- (void)handleLandscapeUI {
    self.backButton.hidden = NO;
    self.fullScreenView.hidden = YES;
    self.userListComponent.scrollDirection = UICollectionViewScrollDirectionVertical;
    
    self.imCompoments.hidden = YES;
    self.inputMessageView.hidden = YES;
    self.buttonsView.hidden = YES;
    self.navView.hidden = YES;
}

#pragma mark - privateMethods

/// UI初始化
- (void)setupViews {
    
    [self videoComponent];
    [self imCompoments];
    [self userListComponent];
    
    [self.view addSubview:self.inputMessageView];
    [self.view addSubview:self.buttonsView];
    [self.view addSubview:self.fullScreenView];
    [self.view addSubview:self.backButton];
    
    [self.view addSubview:self.navView];
    
    [self.buttonsView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.view).offset(-12);
        make.bottom.mas_equalTo(-10 - [DeviceInforTool getVirtualHomeHeight]);
    }];
    [self.inputMessageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(12);
        make.height.mas_equalTo(36);
        make.right.equalTo(self.buttonsView.mas_left).offset(-10);
        make.centerY.equalTo(self.buttonsView);
    }];
    [self.fullScreenView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.view).offset(-10);
        make.bottom.equalTo(self.view).offset(-236);
        make.height.mas_equalTo(27);
    }];
    [self.backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(30);
        make.left.equalTo(self.view).offset(16 + [DeviceInforTool getStatusBarHight]);
        make.size.mas_equalTo(CGSizeMake(32, 32));
    }];
}

- (void)startPlayVideo {
    
    /// 主播端展示解析中Loading
    if ([LiveShareDataManager shared].isHost) {
        self.videoParsingView = [[LiveShareVideoParsingView alloc] init];
        [self.videoParsingView showInview:self.view];
        __weak typeof(self) weakSelf = self;
        self.videoParsingView.onCancelParsingBlock = ^{
            [weakSelf.videoComponent stop];
            [weakSelf removeVideoParsingView];
            if ([LiveShareDataManager shared].roomModel.roomStatus == LiveShareRoomStatusChat) {
                /// 观众还没有进入一起看，主播直接退出一起看
                [weakSelf popToRoomViewController];
            }
        };
    }
    
    [self.videoComponent playWihtURLString:[LiveShareDataManager shared].roomModel.videoURL];
}

/// 移除URL解析中Loading
- (void)removeVideoParsingView {
    if (self.videoParsingView) {
        [self.videoParsingView removeFromSuperview];
        self.videoParsingView = nil;
    }
}

/// 直播视频加载成功
- (void)handleVideoLoadSuccess {
    [self removeVideoParsingView];
    
    if ([LiveShareDataManager shared].roomModel.roomStatus == LiveShareRoomStatusChat) {
        /// 不是一起看状态，则发起一起看
        [self requestStartShareToServer];
    }
}

- (void)requestChangeLiveURLToServer {
    [LiveShareRTSManager requestChangeVideo:[LiveShareDataManager shared].roomModel.roomID
                                  urlString:[LiveShareDataManager shared].roomModel.videoURL
                             videoDirection:[LiveShareDataManager shared].roomModel.videoDirection
                                      block:^(LiveShareRoomModel * _Nonnull roomModel, RTMACKModel * _Nonnull model) {
        if (!model.result) {
            [[ToastComponent shareToastComponent] showWithMessage:model.message];
        }
    }];
}

- (void)requestStartShareToServer {
    
    __weak typeof(self) weakSelf = self;
    [LiveShareRTSManager requestJoinWatch:[LiveShareDataManager shared].roomModel.roomID
                                urlString:[LiveShareDataManager shared].roomModel.videoURL
                           videoDirection:[LiveShareDataManager shared].roomModel.videoDirection
                                    block:^(LiveShareRoomModel * _Nonnull roomModel, RTMACKModel * _Nonnull model) {
        if (!model.result) {
            NSString *message = model.message;
            if (model.code == 649) {
                message = veString(@"same_live_url_tip");
            }
            
            AlertActionModel *alertModel = [[AlertActionModel alloc] init];
            alertModel.title = veString(@"sure");
            alertModel.alertModelClickBlock = ^(UIAlertAction * _Nonnull action) {
                if ([action.title isEqualToString:veString(@"sure")]) {
                    /// 观众还没有进入一起看，主播直接退出一起看
                    [weakSelf popToRoomViewController];
                }
            };
            [[AlertActionManager shareAlertActionManager] showWithMessage:veString(@"url_parsing_failed") actions:@[alertModel]];
        }
        else {
            [LiveShareDataManager shared].roomModel.roomStatus = LiveShareRoomStatusShare;
        }
    }];
}

/// 直播视频加载失败
- (void)handleVideoLoadFailure {
    [self removeVideoParsingView];
    
    __weak typeof(self) weakSelf = self;
    AlertActionModel *alertModel = [[AlertActionModel alloc] init];
    alertModel.title = veString(@"sure");
    alertModel.alertModelClickBlock = ^(UIAlertAction * _Nonnull action) {
        if ([action.title isEqualToString:veString(@"sure")]) {
            if ([LiveShareDataManager shared].roomModel.roomStatus == LiveShareRoomStatusChat) {
                /// 观众还没有进入一起看，主播直接退出一起看
                [weakSelf popToRoomViewController];
            }
        }
    };
    [[AlertActionManager shareAlertActionManager] showWithMessage:veString(@"url_parsing_failed") actions:@[alertModel]];
    
}
/// 直播视频播放完成
- (void)handleVideoPlayComplete {
    [[ToastComponent shareToastComponent] showWithMessage:veString(@"live_broadcast_ended")];
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

/// 设置为竖屏
- (void)setScreenPortrait {
    [self setDeviceInterfaceOrientation:UIDeviceOrientationPortrait];
}

/// 设置为横屏
- (void)setScreenLandcape {
    [self setDeviceInterfaceOrientation:UIDeviceOrientationLandscapeLeft];
}

#pragma mark - publicMethods
/// 房主更新播放URL
- (void)updateVideoURL {
    [self setScreenPortrait];
    
    [self handelPortraitUI];
    
    [self startPlayVideo];
}

/// 更新用户渲染视图
- (void)updateUserVideoRender {
    [self.userListComponent updateData];
//    self.userListComponent.dataArray = [[LiveShareDataManager shared] getAllUserList];
}

/// 添加消息
/// @param imModel IM model
- (void)addIMModel:(LiveShareIMModel *)imModel {
    [self.imCompoments addIM:imModel];
}

/// 用户媒体状态更新
/// @param roomID RoomID
/// @param userModel User model
- (void)onUserMediaUpdated:(NSString *)roomID userModel:(LiveShareUserModel *)userModel {
    [self updateUserVideoRender];
}

- (void)updateLocalUserVolume:(NSInteger)volume {
    [self.userListComponent updateLocalUserVolume:volume];
}

- (void)updateRemoteUserVolume:(NSDictionary *)volumeDict {
    [self.userListComponent updateRemoteUserVolume:volumeDict];
}

/// 销毁播放资源
- (void)destroy {
    [_videoComponent close];
    _videoComponent = nil;
}

#pragma mark - actions
- (void)quitButtonClick {
    
    if ([LiveShareDataManager shared].isHost) {
        
        /// 一起看进行中离开，需要关闭一起看状态
        if ([LiveShareDataManager shared].roomModel.roomStatus == LiveShareRoomStatusShare) {
            [LiveShareRTSManager requestLeaveWatch:[LiveShareDataManager shared].roomModel.roomID
                                             block:^(LiveShareRoomModel * _Nonnull roomModel, RTMACKModel * _Nonnull model) {
                if (!model.result) {
                    [[ToastComponent shareToastComponent] showWithMessage:model.message];
                }
            }];
        }
        
        [LiveShareDataManager shared].roomModel.roomStatus = LiveShareRoomStatusChat;
        [self popToRoomViewController];
    }
    else {
        [LiveShareRTSManager requestLeaveRoom:[LiveShareDataManager shared].roomModel.roomID block:^(RTMACKModel * _Nonnull model) {
            if (!model.result) {
                [[ToastComponent shareToastComponent] showWithMessage:model.message];
            }
        }];
        [self popToCreateRoomViewController];
    }
}

- (void)popToRoomViewController {
    [self destroy];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)popToCreateRoomViewController {
    
    [[LiveShareRTCManager shareRtc] leaveChannel];
    [LiveShareDataManager destroyDataManager];
    [self destroy];
    
    UIViewController *jumpVC = nil;
    for (UIViewController *vc in self.navigationController.viewControllers) {
        if ([NSStringFromClass([vc class]) isEqualToString:@"LiveShareCreateRoomViewController"]) {
            jumpVC = vc;
            break;
        }
    }
    if (jumpVC) {
        [self.navigationController popToViewController:jumpVC animated:YES];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)inputMessageViewClick {
    [self.textInputCompoments showWithRoomModel:[LiveShareDataManager shared].roomModel];
    __weak __typeof(self) wself = self;
    self.textInputCompoments.clickSenderBlock = ^(NSString * _Nonnull text) {
        LiveShareIMModel *model = [[LiveShareIMModel alloc] init];
        NSString *message = [NSString stringWithFormat:@"%@：%@",
                             [LocalUserComponent userModel].name,
                             text];
        model.message = message;
        [wself.imCompoments addIM:model];
    };
}

- (void)fullScreenViewClick {
    [self setScreenLandcape];
}

- (void)backButtonClick {
    [self setScreenPortrait];
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
        _buttonsView = [[LiveShareBottomButtonsView alloc] initWithType:LiveShareButtonViewTypeWatch];
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
            [weakSelf quitButtonClick];
        };
    }
    return _navView;
}

- (LiveShareVolumeView *)volumeView {
    if (!_volumeView) {
        _volumeView = [[LiveShareVolumeView alloc] init];
    }
    return _volumeView;
}

- (UIView *)inputMessageView {
    if (!_inputMessageView) {
        _inputMessageView = [[UIView alloc] init];
        _inputMessageView.backgroundColor = [UIColor.whiteColor colorWithAlphaComponent:0.1];
        _inputMessageView.layer.cornerRadius = 18;
        [_inputMessageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(inputMessageViewClick)]];
        
        UILabel *label = [[UILabel alloc] init];
        label.font = [UIFont systemFontOfSize:14];
        label.textColor = [UIColor.whiteColor colorWithAlphaComponent:0.7];
        label.text = veString(@"say_something");
        [_inputMessageView addSubview:label];
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_inputMessageView).offset(12);
            make.centerY.equalTo(_inputMessageView);
        }];
    }
    return _inputMessageView;
}

- (LiveShareIMComponent *)imCompoments {
    if (!_imCompoments) {
        _imCompoments = [[LiveShareIMComponent alloc] initWithSuperView:self.view];
    }
    return _imCompoments;
}

- (LiveShareTextInputComponent *)textInputCompoments {
    if (!_textInputCompoments) {
        _textInputCompoments = [[LiveShareTextInputComponent alloc] init];
    }
    return _textInputCompoments;
}

- (LiveShareVideoComponent *)videoComponent {
    if (!_videoComponent) {
        _videoComponent = [[LiveShareVideoComponent alloc] initWithSuperview:self.view];
        _videoComponent.delegate = self;
    }
    return _videoComponent;
}

- (UIView *)fullScreenView {
    if (!_fullScreenView) {
        _fullScreenView = [[UIView alloc] init];
        _fullScreenView.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.5];
        _fullScreenView.layer.cornerRadius = 4;
        [_fullScreenView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(fullScreenViewClick)]];
        
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"live_share_full_screen_icon" bundleName:HomeBundleName]];
        UILabel *label = [[UILabel alloc] init];
        label.font = [UIFont systemFontOfSize:11];
        label.textColor = UIColor.whiteColor;
        label.text = veString(@"enter_full_screen");
        
        [_fullScreenView addSubview:imageView];
        [_fullScreenView addSubview:label];
        [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_fullScreenView).offset(7);
            make.centerY.equalTo(_fullScreenView);
            make.size.mas_equalTo(CGSizeMake(12, 12));
        }];
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(imageView.mas_right).offset(5);
            make.centerY.equalTo(_fullScreenView);
            make.right.equalTo(_fullScreenView).offset(-7);
        }];
    }
    return _fullScreenView;
}

- (UIButton *)backButton {
    if (!_backButton) {
        _backButton = [[UIButton alloc] init];
        [_backButton setImage:[UIImage imageNamed:@"live_share_close_room_icon" bundleName:HomeBundleName] forState:UIControlStateNormal];
        [_backButton addTarget:self action:@selector(backButtonClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backButton;
}

- (LiveShareUserListComponent *)userListComponent {
    if (!_userListComponent) {
        _userListComponent = [[LiveShareUserListComponent alloc] initWithSuperview:self.view];
        _userListComponent.shouldSwitchFullUser = NO;
    }
    return _userListComponent;
}

@end
