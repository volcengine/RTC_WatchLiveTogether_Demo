// 
// Copyright (c) 2023 Beijing Volcano Engine Technology Ltd.
// SPDX-License-Identifier: MIT
// 

#import "LiveShareNavView.h"

#import "LiveShareRTCManager.h"

@interface LiveShareNavView()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *cameraButton;
@property (nonatomic, strong) UIButton *leaveButton;

@end

@implementation LiveShareNavView

+ (CGFloat)viewHeight {
    return [DeviceInforTool getStatusBarHight] + 44;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, [LiveShareNavView viewHeight])]) {
        [self setupViews];
    }
    return self;
}

- (void)setupViews {
    [self addSubview:self.titleLabel];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self);
        make.centerX.equalTo(self);
        make.height.mas_equalTo(44);
    }];
    [self addSubview:self.cameraButton];
    [self.cameraButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(23);
        make.centerY.equalTo(self.titleLabel);
        make.size.mas_equalTo(CGSizeMake(24, 24));
    }];
    [self addSubview:self.leaveButton];
    [self.leaveButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-23);
        make.centerY.equalTo(self.titleLabel);
        make.size.mas_equalTo(CGSizeMake(24, 24));
    }];
}

- (void)setTitle:(NSString *)title {
    _title = title;
    
    _titleLabel.text = [title stringByReplacingOccurrencesOfString:@"twv_" withString:@""];
}

#pragma mark - Actions

- (void)cameraButtonClick {
    [[LiveShareRTCManager shareRtc] switchCamera];
}

- (void)leaveButtonClick {
    if (self.leaveButtonTouchBlock) {
        self.leaveButtonTouchBlock();
    }
}

#pragma mark - Getter
- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:16];
        _titleLabel.textColor = UIColor.whiteColor;
    }
    return _titleLabel;
}

- (UIButton *)cameraButton {
    if (!_cameraButton) {
        _cameraButton = [[UIButton alloc] init];
        [_cameraButton setImage:[UIImage imageNamed:@"live_share_room_switch_camera" bundleName:HomeBundleName] forState:UIControlStateNormal];
        [_cameraButton addTarget:self action:@selector(cameraButtonClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cameraButton;
}

- (UIButton *)leaveButton {
    if (!_leaveButton) {
        _leaveButton = [[UIButton alloc] init];
        [_leaveButton setImage:[UIImage imageNamed:@"live_share_room_hangup" bundleName:HomeBundleName] forState:UIControlStateNormal];
        [_leaveButton addTarget:self action:@selector(leaveButtonClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _leaveButton;
}


@end
