//
//  LiveSharePlayVolumeView.m
//  veRTC_Demo
//
//

#import "LiveShareVolumeView.h"
#import "UIColor+String.h"
#import "LiveShareRTCManager.h"

@interface LiveShareVolumeView ()

@property (nonatomic, strong) UIView *backView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *videoLabel;
@property (nonatomic, strong) UILabel *callLabel;
@property (nonatomic, strong) UISlider *videoSlider;
@property (nonatomic, strong) UISlider *callSlider;
@property (nonatomic, strong) UILabel *videoValueLabel;
@property (nonatomic, strong) UILabel *callValueLabel;
@property (nonatomic, strong) UILabel *audioDuckingLabel;
@property (nonatomic, strong) UISwitch *audioDuckingSwitch;
@property (nonatomic, strong) UIButton *closeButton;

@property (nonatomic, assign) NSTimeInterval lastTime;

@end

@implementation LiveShareVolumeView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:UIScreen.mainScreen.bounds]) {
        [self setupViews];
    }
    return self;
}

- (void)setupViews {
    [self addSubview:self.backView];
    [self addSubview:self.contentView];
    [self.backView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self);
        make.top.equalTo(self.mas_bottom);
    }];
    [self.contentView addSubview:self.audioDuckingLabel];
    [self.contentView addSubview:self.audioDuckingSwitch];
    [self.contentView addSubview:self.closeButton];
    [self.contentView addSubview:self.videoLabel];
    [self.contentView addSubview:self.videoSlider];
    [self.contentView addSubview:self.videoValueLabel];
    [self.contentView addSubview:self.callLabel];
    [self.contentView addSubview:self.callSlider];
    [self.contentView addSubview:self.callValueLabel];
    
    [self.audioDuckingLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(30);
        make.left.equalTo(self.contentView).offset(16);
    }];
    [self.audioDuckingSwitch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.audioDuckingLabel.mas_right).offset(12);
        make.centerY.equalTo(self.audioDuckingLabel);
    }];
    [self.videoLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.audioDuckingLabel.mas_bottom).offset(30);
        make.left.equalTo(self.contentView).offset(16);
    }];
    [self.videoSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.videoLabel.mas_bottom).offset(0);
        make.left.equalTo(self.videoLabel);
        make.right.equalTo(self.videoValueLabel.mas_left).offset(-15);
        make.height.mas_equalTo(60);
    }];
    [self.videoValueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.contentView).offset(-16);
        make.centerY.equalTo(self.videoSlider);
        make.width.mas_equalTo(40);
    }];
    [self.callLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.videoSlider.mas_bottom);
        make.left.equalTo(self.videoLabel);
    }];
    [self.callSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.callLabel.mas_bottom);
        make.left.equalTo(self.callLabel);
        make.right.equalTo(self.callValueLabel.mas_left).offset(-15);
        make.height.mas_equalTo(60);
        make.bottom.equalTo(self.contentView).offset(-[DeviceInforTool getVirtualHomeHeight]);
    }];
    [self.callValueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.videoValueLabel);
        make.centerY.equalTo(self.callSlider);
        make.width.mas_equalTo(40);
    }];
    
    [self.closeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView).offset(-16);
        make.size.mas_equalTo(CGSizeMake(16, 16));
    }];
    
    self.videoSlider.value = [LiveShareRTCManager shareRtc].audioMixingVolume;
    self.videoValueLabel.text = [NSString stringWithFormat:@"%.0f%%", self.videoSlider.value*200];
    self.callSlider.value = [LiveShareRTCManager shareRtc].recordingVolume;
    self.callValueLabel.text = [NSString stringWithFormat:@"%.0f%%", self.callSlider.value*200];
    self.audioDuckingSwitch.on = [LiveShareRTCManager shareRtc].enableAudioDucking;
}

#pragma mark - publicMethods
- (void)showinView:(UIView *)parentView {
    if (!parentView) {
        parentView = [DeviceInforTool topViewController].view;
    }
    [parentView addSubview:self];
    [self layoutIfNeeded];
    [UIView animateWithDuration:0.25 animations:^{
        [self.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.right.bottom.equalTo(self);
        }];
        [self layoutIfNeeded];
    }];
}

#pragma mark - actions
- (void)backViewTouch {
    [UIView animateWithDuration:0.25 animations:^{
        [self.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self);
            make.top.equalTo(self.mas_bottom);
        }];
        [self layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

- (void)videoSliderValueChanged:(UISlider *)slider {
    CGFloat value = slider.value;
    self.videoValueLabel.text = [NSString stringWithFormat:@"%.0f%%", value*200];
    
    NSTimeInterval time = [NSDate date].timeIntervalSince1970;
    if (time - _lastTime > 0.3) {
        _lastTime = time;
        [LiveShareRTCManager shareRtc].audioMixingVolume = value;
    }
}

- (void)videoSliderTouchUpInSide:(UISlider *)slider {
    [LiveShareRTCManager shareRtc].audioMixingVolume = slider.value;
}

- (void)callSliderValueChanged:(UISlider *)slider {
    CGFloat value = slider.value;
    self.callValueLabel.text = [NSString stringWithFormat:@"%.0f%%", value*200];
    [LiveShareRTCManager shareRtc].recordingVolume = value;
}

- (void)audioDuckingSwitchValueChanged:(UISwitch *)sw {
    [LiveShareRTCManager shareRtc].enableAudioDucking = sw.isOn;
}

#pragma mark - getter
- (UIView *)backView {
    if (!_backView) {
        _backView = [[UIView alloc] init];
        [_backView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backViewTouch)]];
    }
    return _backView;
}

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc] init];
        _contentView.backgroundColor = [[UIColor colorFromHexString:@"#0E0825F2"] colorWithAlphaComponent:0.95];
    }
    return _contentView;
}

- (UILabel *)videoLabel {
    if (!_videoLabel) {
        _videoLabel = [[UILabel alloc] init];
        _videoLabel.font = [UIFont systemFontOfSize:18];
        _videoLabel.textColor = [UIColor colorFromHexString:@"#E5E6EB"];
        _videoLabel.text = veString(@"video_volume");
    }
    return _videoLabel;
}

- (UISlider *)videoSlider {
    if (!_videoSlider) {
        _videoSlider = [[UISlider alloc] init];
        _videoSlider.minimumValue = 0;
        _videoSlider.maximumValue = 1.0;
        _videoSlider.value = 0.5;
        [_videoSlider addTarget:self action:@selector(videoSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        [_videoSlider addTarget:self action:@selector(videoSliderTouchUpInSide:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _videoSlider;
}

- (UILabel *)callLabel {
    if (!_callLabel) {
        _callLabel = [[UILabel alloc] init];
        _callLabel.font = [UIFont systemFontOfSize:18];
        _callLabel.textColor = [UIColor colorFromHexString:@"#E5E6EB"];
        _callLabel.text = veString(@"call_volume");
    }
    return _callLabel;
}

- (UISlider *)callSlider {
    if (!_callSlider) {
        _callSlider = [[UISlider alloc] init];
        _callSlider.minimumValue = 0;
        _callSlider.maximumValue = 1.0;
        _callSlider.value = 0.5;
        [_callSlider addTarget:self action:@selector(callSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    }
    return _callSlider;
}

- (UILabel *)videoValueLabel {
    if (!_videoValueLabel) {
        _videoValueLabel = [[UILabel alloc] init];
        _videoValueLabel.font = [UIFont systemFontOfSize:12];
        _videoValueLabel.textColor = UIColor.whiteColor;
        _videoValueLabel.textAlignment = NSTextAlignmentCenter;
        _videoValueLabel.text = @"100%";
    }
    return _videoValueLabel;
}

- (UILabel *)callValueLabel {
    if (!_callValueLabel) {
        _callValueLabel = [[UILabel alloc] init];
        _callValueLabel.font = [UIFont systemFontOfSize:12];
        _callValueLabel.textColor = UIColor.whiteColor;
        _callValueLabel.textAlignment = NSTextAlignmentCenter;
        _callValueLabel.text = @"100%";
    }
    return _callValueLabel;
}

- (UILabel *)audioDuckingLabel {
    if (!_audioDuckingLabel) {
        _audioDuckingLabel = [[UILabel alloc] init];
        _audioDuckingLabel.font = [UIFont systemFontOfSize:18];
        _audioDuckingLabel.textColor = [UIColor colorFromHexString:@"#E5E6EB"];
        _audioDuckingLabel.text = veString(@"audio_ducking");
    }
    return _audioDuckingLabel;
}

- (UISwitch *)audioDuckingSwitch {
    if (!_audioDuckingSwitch) {
        _audioDuckingSwitch = [[UISwitch alloc] init];
        _audioDuckingSwitch.onTintColor = UIColor.blueColor;
        [_audioDuckingSwitch addTarget:self action:@selector(audioDuckingSwitchValueChanged:) forControlEvents:UIControlEventValueChanged];
    }
    return _audioDuckingSwitch;
}

- (UIButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [[UIButton alloc] init];
        [_closeButton setImage:[UIImage imageNamed:@"live_share_close_volume" bundleName:HomeBundleName] forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(backViewTouch) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}

@end
