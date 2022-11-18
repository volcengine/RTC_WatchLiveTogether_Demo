//
//  LiveSharePreViewViewController.m
//  veRTC_Demo
//
//

#import "LiveShareCreateRoomViewController.h"
#import "LiveShareRoomViewController.h"

#import "LiveShareCreateRoomButtonsView.h"
#import "LiveShareCreateRoomTipView.h"


#import "SystemAuthority.h"
#import "LiveShareRTCManager.h"
#import "LiveShareRoomModel.h"
#import "LiveShareMediaModel.h"
#import "LiveShareRTSManager.h"
#import <TTSDK/TTSDKManager.h>
#import "BytedEffectProtocol.h"

#define TEXTFIELD_MAX_LENGTH 18

@interface LiveShareCreateRoomViewController ()
<
UITextFieldDelegate,
LiveShareCreateRoomButtonsViewDelegate,
UIGestureRecognizerDelegate
>

/// UI
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIButton *enterRoomBtn;
@property (nonatomic, strong) UIView *roomTextView;
@property (nonatomic, strong) UITextField *roomIdTextField;
@property (nonatomic, strong) UIImageView *emptImageView;
@property (nonatomic, strong) UIView *videoView;
@property (nonatomic, strong) LiveShareCreateRoomButtonsView *buttonsView;
@property (nonatomic, strong) LiveShareCreateRoomTipView *tipView;
@property (nonatomic, strong) UIView *buttonBackView;

@property (nonatomic, strong) BytedEffectProtocol *beautyCompoments;

@property (nonatomic, strong) UITapGestureRecognizer *tap;

@end

@implementation LiveShareCreateRoomViewController

- (instancetype)init {
    if (self = [super init]) {
        
        [[LiveShareMediaModel shared] resetMediaStatus];
        
        /// 第一次进入，使用默认美颜效果
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [self.beautyCompoments resetLocalModelArray];
            [self initTTSDK];
        });
        
    }
    return self;
}

- (void)initTTSDK {
    NSString *APPID = TTAPPID;
    NSString *licenseFileName = TTLicenseName;
    NSString *appName = @"vertc";
    NSString *channel = @"App Store";
    
    TTSDKConfiguration *configuration = [TTSDKConfiguration defaultConfigurationWithAppID:APPID];
    configuration.appName = appName;
    configuration.channel = channel;
    configuration.bundleID = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    NSString *licenseFilePath = [[NSBundle mainBundle]
                                 pathForResource:licenseFileName
                                 ofType:@"lic"];
    configuration.licenseFilePath = licenseFilePath;
    [TTSDKManager startWithConfiguration:configuration];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor grayColor];
    
    [self initUIComponents];
    
    [self.beautyCompoments resumeLocalEffect];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyBoardDidShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyBoardDidHide:) name:UIKeyboardWillHideNotification object:nil];
    
    [[LiveShareRTCManager shareRtc] enableLocalVideo:YES];
    [[LiveShareRTCManager shareRtc] enableLocalAudio:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    
    [[LiveShareRTCManager shareRtc] updateCameraID:YES];
    [[LiveShareRTCManager shareRtc] setLocalPreView:self.videoView];
    [[LiveShareRTCManager shareRtc] enableLocalVideo:YES];
    self.videoView.hidden = ![LiveShareMediaModel shared].enableVideo;
    self.emptImageView.hidden = [LiveShareMediaModel shared].enableVideo;
    
    self.buttonsView.enableVideo = [LiveShareMediaModel shared].enableVideo;
    self.buttonsView.enableAudio = [LiveShareMediaModel shared].enableAudio;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [LiveShareMediaModel shared].enableVideo = self.buttonsView.enableVideo;
    [LiveShareMediaModel shared].enableAudio = self.buttonsView.enableAudio;
}

#pragma mark - 通知
- (void)keyBoardDidShow:(NSNotification *)notifiction {
    CGRect keyboardRect = [[notifiction.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    [UIView animateWithDuration:0.25 animations:^{
        [self.enterRoomBtn mas_updateConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.view).offset(-keyboardRect.size.height - 80/2);
        }];
    }];
    self.emptImageView.hidden = YES;
    [self.view layoutIfNeeded];
}

- (void)keyBoardDidHide:(NSNotification *)notifiction {
    
    [UIView animateWithDuration:0.25 animations:^{
        [self.enterRoomBtn mas_updateConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.view).offset(-41 - [DeviceInforTool getVirtualHomeHeight]);
        }];
    }];
    self.emptImageView.hidden = self.buttonsView.enableVideo;
    [self.view layoutIfNeeded];
}

#pragma mark - UITextField delegate

- (void)roomNumTextFieldChange:(UITextField *)textField {
    [self updateTextFieldChange:textField];
}

- (void)updateTextFieldChange:(UITextField *)textField {
    NSInteger tagNum = 3001;
    UILabel *label = [self.view viewWithTag:tagNum];
    
    NSString *message = @"";
    BOOL isExceedMaximLength = NO;
    if (textField.text.length > TEXTFIELD_MAX_LENGTH) {
        textField.text = [textField.text substringToIndex:TEXTFIELD_MAX_LENGTH];
        isExceedMaximLength = YES;
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismissErrorLabel:) object:textField];
    BOOL isIllegal = NO;
    isIllegal = ![LocalUserComponent isMatchRoomID:textField.text];
    if (isIllegal || isExceedMaximLength) {
        if (isIllegal) {
            message = veString(@"room_id_rules");
        } else if (isExceedMaximLength) {
            [self performSelector:@selector(dismissErrorLabel:) withObject:textField afterDelay:2];
            message = veString(@"room_id_length_limit");
        } else {
            message = @"";
        }
    } else {
        message = @"";
    }
    label.text = message;
}

- (void)dismissErrorLabel:(UITextField *)textField {
    NSInteger tagNum = 3001;
    UILabel *label = [self.view viewWithTag:tagNum];
    label.text = @"";
}

#pragma mark - LiveShareCreateRoomButtonsViewDelegate
- (void)liveShareCreateRoomButtonsView:(LiveShareCreateRoomButtonsView *)view didClickButtonType:(LiveShareButtonType)type {
    switch (type) {
        case LiveShareButtonTypeAudio: {
            [LiveShareMediaModel shared].enableAudio = view.enableAudio;
        }
            break;
            
        case LiveShareButtonTypeVideo: {
                BOOL isEnableVideo = view.enableVideo;
                [LiveShareMediaModel shared].enableVideo = view.enableVideo;
                self.videoView.hidden = !isEnableVideo;
                self.emptImageView.hidden = isEnableVideo;
                [[LiveShareRTCManager shareRtc] enableLocalVideo:isEnableVideo];
        }
            break;
            
        case LiveShareButtonTypeBeauty: {
            if (self.beautyCompoments) {
                self.contentView.hidden = YES;
                __weak __typeof(self) wself = self;
                [self.beautyCompoments showWithType:EffectBeautyRoleTypeHost fromSuperView:self.view dismissBlock:^(BOOL result) {
                    wself.contentView.hidden = NO;
                }];
            } else {
                [[ToastComponent shareToastComponent] showWithMessage:veString(@"open_souurce_code_beauty_tip")];
            }
        }
            break;
            
        default:
            break;
    }
}

#pragma mark - actions

- (void)tapGestureAction:(id)sender {
    [self.roomIdTextField resignFirstResponder];
}

- (void)onClickEnterRoom:(UIButton *)sender {
    NSString *roomID = self.roomIdTextField.text;
    if (roomID.length <= 0 || ![LocalUserComponent isMatchRoomID:roomID]) {
        return;
    }
    roomID = [NSString stringWithFormat:@"twv_%@", roomID];
    [PublicParameterComponent share].roomId = roomID;
    [self.view endEditing:YES];
    sender.userInteractionEnabled = NO;
    
    [[ToastComponent shareToastComponent] showLoading];
    __weak typeof(self) weakSelf = self;
    [LiveShareRTSManager clearUser:^(RTMACKModel * _Nonnull model) {
        [LiveShareRTSManager requestJoinRoomWithRoomID:roomID
                                                 block:^(LiveShareRoomModel * _Nonnull roomModel,
                                                         NSArray<LiveShareUserModel *> * _Nonnull userList,
                                                         RTMACKModel * _Nonnull model) {
            [[ToastComponent shareToastComponent] dismiss];
            if (model.result) {
                [[LiveShareDataManager shared] addUserList:userList];
                [LiveShareDataManager shared].roomModel = roomModel;
                [weakSelf jumpToRoomViewController:roomModel];
            } else if (model.code == 414) {
                [[ToastComponent shareToastComponent] showWithMessage:veString(@"user_already_in_room")];
            } else if (model.code == 507) {
                [[ToastComponent shareToastComponent] showWithMessage:veString(@"room_is_full")];
            } else {
                [[ToastComponent shareToastComponent] showWithMessage:model.message];
            }
            sender.userInteractionEnabled = YES;
        }];
    }];
}

- (void)jumpToRoomViewController:(LiveShareRoomModel *)roomModel {
    
    [[LiveShareRTCManager shareRtc] joinChannelWithToken:roomModel.rtcToken roomID:roomModel.roomID uid:[LocalUserComponent userModel].uid];
    
    LiveShareRoomViewController *roomViewController = [[LiveShareRoomViewController alloc] init];
    
    if (roomModel.videoURL.length > 0 && roomModel.roomStatus == LiveShareRoomStatusShare) {
        LiveSharePlayViewController *playController = [[LiveSharePlayViewController alloc] init];
        roomViewController.playController = playController;
        
        NSMutableArray *viewControllers = self.navigationController.viewControllers.mutableCopy;
        [viewControllers addObjectsFromArray:@[roomViewController, playController]];
        [self.navigationController setViewControllers:viewControllers animated:YES];
    } else {
        [self.navigationController pushViewController:roomViewController animated:YES];
    }
}


#pragma mark - privateMethods

- (void)addErrorLabel:(UIView *)view tag:(NSInteger)tag {
    UILabel *label = [[UILabel alloc] init];
    label.tag = tag;
    label.font = [UIFont systemFontOfSize:14];
    label.text = @"";
    label.textColor = [UIColor colorFromHexString:@"#F53F3F"];
    [self.view addSubview:label];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(view);
        make.top.mas_equalTo(view.mas_bottom).offset(4);
    }];
}

- (void)initUIComponents {
    [self.view addSubview:self.videoView];
    [self.videoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    [self.view addSubview:self.contentView];
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    [self.contentView addSubview:self.closeButton];
    [self.closeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(30 + [DeviceInforTool getStatusBarHight]);
        make.right.equalTo(self.view).offset(-17);
    }];
    
    [self.contentView addSubview:self.tipView];
    [self.tipView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.closeButton.mas_bottom).offset(8);
    }];
    
    [self.contentView addSubview:self.emptImageView];
    [self.emptImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(120);
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.view).offset(128/2 + [DeviceInforTool getStatusBarHight] + 50);
    }];
    
    [self.contentView addGestureRecognizer:self.tap];
    
    [self.contentView addSubview:self.enterRoomBtn];
    [self.enterRoomBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(227, 50));
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(-41 - [DeviceInforTool getVirtualHomeHeight]);
    }];
    
    [self.contentView addSubview:self.buttonBackView];
    [self.buttonBackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.contentView);
        make.bottom.equalTo(self.enterRoomBtn.mas_top).offset(-7);
        make.size.mas_equalTo(CGSizeMake(267, 175));
    }];
    
    [self.contentView addSubview:self.buttonsView];
    [self.buttonsView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.contentView);
        make.bottom.equalTo(self.buttonBackView).offset(-20);
    }];
    
    [self.contentView addSubview:self.roomTextView];
    [self.roomTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(227, 45));
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.buttonsView.mas_top).offset(-32);
    }];
    
    [self addErrorLabel:self.roomIdTextField tag:3001];
}

- (void)closeButtonClick {
    [self.navigationController popViewControllerAnimated:YES];
    [[LiveShareRTCManager shareRtc] disconnect];
}

#pragma mark - getter

- (UIView *)roomTextView {
    if (!_roomTextView) {
        _roomTextView = [[UIView alloc] init];
        
        UIView *lineView = [[UIView alloc] init];
        lineView.backgroundColor = [UIColor.whiteColor colorWithAlphaComponent:0.76];
        [_roomTextView addSubview:lineView];
        [lineView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.bottom.equalTo(_roomTextView);
            make.height.mas_equalTo(0.5);
        }];
        
        [_roomTextView addSubview:self.roomIdTextField];
        [self.roomIdTextField mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(_roomTextView);
            make.left.equalTo(_roomTextView).offset(12.5);
            make.right.equalTo(_roomTextView).offset(-12.5);
        }];
    }
    return _roomTextView;
}

- (UITextField *)roomIdTextField {
    if (!_roomIdTextField) {
        _roomIdTextField = [[UITextField alloc] init];
        _roomIdTextField.delegate = self;
        [_roomIdTextField setBackgroundColor:[UIColor clearColor]];
        [_roomIdTextField setTextColor:[UIColor whiteColor]];
        _roomIdTextField.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
        [_roomIdTextField addTarget:self action:@selector(roomNumTextFieldChange:) forControlEvents:UIControlEventEditingChanged];
        NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:veString(@"room_id_placeholder") attributes:@{NSForegroundColorAttributeName : [UIColor colorFromHexString:@"#86909C"]}];
        _roomIdTextField.attributedPlaceholder = attrString;
    }
    return _roomIdTextField;
}

- (UIButton *)enterRoomBtn {
    if (!_enterRoomBtn) {
        _enterRoomBtn = [[UIButton alloc] init];
        _enterRoomBtn.backgroundColor = [UIColor colorFromHexString:@"#1664FF"];
        _enterRoomBtn.layer.masksToBounds = YES;
        _enterRoomBtn.layer.cornerRadius = 50/2;
        _enterRoomBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        [_enterRoomBtn setTitle:veString(@"enter_room") forState:UIControlStateNormal];
        [_enterRoomBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        _enterRoomBtn.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
        [_enterRoomBtn addTarget:self action:@selector(onClickEnterRoom:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _enterRoomBtn;
}

- (UIView *)videoView {
    if (!_videoView) {
        _videoView = [[UIView alloc] init];
    }
    return _videoView;
}

- (UITapGestureRecognizer *)tap {
    if (!_tap) {
        _tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                       action:@selector(tapGestureAction:)];
    }
    return _tap;
}

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc] init];
    }
    return _contentView;
}

- (UIImageView *)emptImageView {
    if (!_emptImageView) {
        _emptImageView = [[UIImageView alloc] init];
        _emptImageView.image = [UIImage imageNamed:@"meeting_login_empt" bundleName:HomeBundleName];
        _emptImageView.hidden = YES;
    }
    return _emptImageView;
}

- (void)dealloc {
    [[LiveShareRTCManager shareRtc] disconnect];
    [PublicParameterComponent clear];
}

- (LiveShareCreateRoomButtonsView *)buttonsView {
    if (!_buttonsView) {
        _buttonsView = [[LiveShareCreateRoomButtonsView alloc] init];
        _buttonsView.delegate = self;
    }
    return _buttonsView;
}

- (BytedEffectProtocol *)beautyCompoments {
    if (!_beautyCompoments) {
        _beautyCompoments = [[BytedEffectProtocol alloc] initWithRTCEngineKit:[LiveShareRTCManager shareRtc].rtcEngineKit];
    }
    return _beautyCompoments;
}

- (UIButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [[UIButton alloc] init];
        [_closeButton setImage:[UIImage imageNamed:@"live_share_close_room" bundleName:HomeBundleName] forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(closeButtonClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}

- (LiveShareCreateRoomTipView *)tipView {
    if (!_tipView) {
        _tipView = [[LiveShareCreateRoomTipView alloc] init];
        _tipView.message = veString(@"experience_time_tips");
    }
    return _tipView;
}

- (UIView *)buttonBackView {
    if (!_buttonBackView) {
        _buttonBackView = [[UIView alloc] init];
        _buttonBackView.layer.cornerRadius = 15;
        _buttonBackView.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.2];
    }
    return _buttonBackView;
}

@end
