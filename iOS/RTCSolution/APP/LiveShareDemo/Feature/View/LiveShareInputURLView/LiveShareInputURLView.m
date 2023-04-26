// 
// Copyright (c) 2023 Beijing Volcano Engine Technology Ltd.
// SPDX-License-Identifier: MIT
// 

#import "LiveShareInputURLView.h"

@interface LiveShareInputURLView ()

@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIView *textFieldView;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UIButton *horizontalButton;
@property (nonatomic, strong) UILabel *horizontalLabel;
@property (nonatomic, strong) UIButton *verticalButton;
@property (nonatomic, strong) UILabel *verticalLabel;
@property (nonatomic, strong) UIButton *watchButton;

@property (nonatomic, assign) LiveShareVideoDirection videoDirection;

@end

@implementation LiveShareInputURLView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        self.videoDirection = LiveShareVideoDirectionHorizontal;
        
        [self setupViews];
        
        [self addNotification];
    }
    return self;
}

#pragma mark - Private Action

- (void)setupViews {
    [self addSubview:self.backgroundView];
    [self addSubview:self.contentView];
    [self.contentView addSubview:self.textFieldView];
    [self.contentView addSubview:self.horizontalButton];
    [self.contentView addSubview:self.verticalButton];
    [self.contentView addSubview:self.horizontalLabel];
    [self.contentView addSubview:self.verticalLabel];
    [self.contentView addSubview:self.watchButton];
    
    [self.backgroundView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    [self.textFieldView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.equalTo(self.contentView).offset(30);
        make.right.equalTo(self.contentView).offset(-30);
        make.height.mas_equalTo(50);
    }];
    [self.horizontalButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.textFieldView.mas_bottom).offset(40);
        make.right.equalTo(self.contentView.mas_centerX).offset(-50);
        make.size.mas_equalTo(CGSizeMake(50, 50));
    }];
    [self.horizontalLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.horizontalButton.mas_bottom).offset(12);
        make.centerX.equalTo(self.horizontalButton);
    }];
    [self.verticalButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.textFieldView.mas_bottom).offset(40);
        make.left.equalTo(self.contentView.mas_centerX).offset(50);
        make.size.mas_equalTo(CGSizeMake(50, 50));
    }];
    [self.verticalLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.verticalButton.mas_bottom).offset(12);
        make.centerX.equalTo(self.verticalButton);
    }];
    [self.watchButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.contentView);
        make.bottom.equalTo(self.contentView).offset(-23 - [DeviceInforTool getVirtualHomeHeight]);
        make.size.mas_equalTo(CGSizeMake(320, 50));
    }];
}

- (void)addNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyBoardDidShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyBoardDidHide:) name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark - Notify
- (void)keyBoardDidShow:(NSNotification *)notifiction {
    CGRect keyboardRect = [[notifiction.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    [UIView animateWithDuration:0.25 animations:^{
        self.contentView.bottom = SCREEN_HEIGHT - keyboardRect.size.height + (self.contentView.height - 80);
    }];
}

- (void)keyBoardDidHide:(NSNotification *)notifiction {
    
    [UIView animateWithDuration:0.25 animations:^{
        self.contentView.bottom = SCREEN_HEIGHT;
    }];
}

#pragma mark - Private Action

- (void)setVideoDirection:(LiveShareVideoDirection)videoDirection {
    if (_videoDirection == videoDirection) {
        return;
    }
    _videoDirection = videoDirection;
    
    self.horizontalButton.selected = NO;
    self.verticalButton.selected = NO;
    self.horizontalLabel.textColor = [UIColor colorFromHexString:@"#86909C"];
    self.verticalLabel.textColor = [UIColor colorFromHexString:@"#86909C"];
    if (videoDirection == LiveShareVideoDirectionHorizontal) {
        self.horizontalButton.selected = YES;
        self.horizontalLabel.textColor = [UIColor colorFromHexString:@"#4080FF"];
    }
    else {
        self.verticalButton.selected = YES;
        self.verticalLabel.textColor = [UIColor colorFromHexString:@"#4080FF"];
    }
}

- (void)dismissView {
    [UIView animateWithDuration:0.25 animations:^{
        self.contentView.top = SCREEN_HEIGHT;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

#pragma mark - Publish Action

- (void)showInview:(UIView *)view {
    [view addSubview:self];
    self.frame = view.bounds;
    
    [UIView animateWithDuration:0.25 animations:^{
        self.contentView.bottom = SCREEN_HEIGHT;
    }];
}

#pragma mark - Actions

- (void)backgrounvViewTouch {
    if (self.textField.isFirstResponder) {
        [self.textField resignFirstResponder];
    }
    else {
        [self dismissView];
    }
}

- (void)horizontalButtonClick {
    self.videoDirection = LiveShareVideoDirectionHorizontal;
}

- (void)verticalButtonClick {
    self.videoDirection = LiveShareVideoDirectionVertical;
}

- (void)watchButtonClick {
    NSString *urlString = self.textField.text;
    if (urlString.length == 0) {
        [[ToastComponent shareToastComponent] showWithMessage:LocalizedString(@"please_enter_copyrighted_live_url")];
        return;
    }
    
    [self dismissView];
    
    if (self.onUserInputVideoURLBlock) {
        self.onUserInputVideoURLBlock(urlString, self.videoDirection);
    }
}

#pragma mark - Getter

- (UIView *)backgroundView {
    if (!_backgroundView) {
        _backgroundView = [[UIView alloc] init];
        [_backgroundView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgrounvViewTouch)]];
    }
    return _backgroundView;
}

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT, SCREEN_WIDTH, 306 + [DeviceInforTool getVirtualHomeHeight])];
        _contentView.backgroundColor = [UIColor colorFromHexString:@"#272E3B"];
        
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:_contentView.bounds byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:CGSizeMake(4, 4)];
        CAShapeLayer *layer = [[CAShapeLayer alloc] init];
        layer.frame = _contentView.bounds;
        layer.path = path.CGPath;
        _contentView.layer.mask = layer;
        
    }
    return _contentView;
}

- (UIView *)textFieldView {
    if (!_textFieldView) {
        _textFieldView = [[UIView alloc] init];
        _textFieldView.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.3];
        _textFieldView.layer.cornerRadius = 4;
        
        [_textFieldView addSubview:self.textField];
        [self.textField mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_textFieldView).offset(16);
            make.right.equalTo(_textFieldView).offset(-16);
            make.centerY.equalTo(_textFieldView);
            make.height.equalTo(_textFieldView.mas_height);
        }];
    }
    return _textFieldView;
}

- (UITextField *)textField {
    if (!_textField) {
        _textField = [[UITextField alloc] init];
        [_textField setBackgroundColor:[UIColor clearColor]];
        [_textField setTextColor:[UIColor whiteColor]];
        _textField.clearButtonMode = UITextFieldViewModeAlways;
        _textField.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
        NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:LocalizedString(@"please_enter_url") attributes:@{NSForegroundColorAttributeName : [UIColor colorFromHexString:@"#86909C"]}];
        _textField.attributedPlaceholder = attrString;
    }
    return _textField;
}

- (UIButton *)horizontalButton {
    if (!_horizontalButton) {
        _horizontalButton = [[UIButton alloc] init];
        [_horizontalButton setImage:[UIImage imageNamed:@"live_share_horizontal_off" bundleName:HomeBundleName] forState:UIControlStateNormal];
        [_horizontalButton setImage:[UIImage imageNamed:@"live_share_horizontal_on" bundleName:HomeBundleName] forState:UIControlStateSelected];
        [_horizontalButton addTarget:self action:@selector(horizontalButtonClick) forControlEvents:UIControlEventTouchUpInside];
        _horizontalButton.selected = YES;
    }
    return _horizontalButton;
}

- (UILabel *)horizontalLabel {
    if (!_horizontalLabel) {
        _horizontalLabel = [[UILabel alloc] init];
        _horizontalLabel.font = [UIFont systemFontOfSize:16];
        _horizontalLabel.textColor = [UIColor colorFromHexString:@"#4080FF"];
        _horizontalLabel.text = LocalizedString(@"landscape_mode");
    }
    return _horizontalLabel;
}

- (UIButton *)verticalButton {
    if (!_verticalButton) {
        _verticalButton = [[UIButton alloc] init];
        [_verticalButton setImage:[UIImage imageNamed:@"live_share_vertical_off" bundleName:HomeBundleName] forState:UIControlStateNormal];
        [_verticalButton setImage:[UIImage imageNamed:@"live_share_vertical_on" bundleName:HomeBundleName] forState:UIControlStateSelected];
        [_verticalButton addTarget:self action:@selector(verticalButtonClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _verticalButton;
}

- (UILabel *)verticalLabel {
    if (!_verticalLabel) {
        _verticalLabel = [[UILabel alloc] init];
        _verticalLabel.font = [UIFont systemFontOfSize:16];
        _verticalLabel.textColor = [UIColor colorFromHexString:@"#86909C"];
        _verticalLabel.text = LocalizedString(@"portrait_mode");
    }
    return _verticalLabel;
}

- (UIButton *)watchButton {
    if (!_watchButton) {
        _watchButton = [[UIButton alloc] init];
        _watchButton.backgroundColor = [UIColor colorFromHexString:@"#165DFF"];
        _watchButton.layer.cornerRadius = 25;
        [_watchButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        [_watchButton setTitle:LocalizedString(@"live_together") forState:UIControlStateNormal];
        [_watchButton addTarget:self action:@selector(watchButtonClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _watchButton;
}

@end
