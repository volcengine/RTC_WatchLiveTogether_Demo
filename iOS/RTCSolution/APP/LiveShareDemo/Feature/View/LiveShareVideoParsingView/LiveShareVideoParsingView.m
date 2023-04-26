// 
// Copyright (c) 2023 Beijing Volcano Engine Technology Ltd.
// SPDX-License-Identifier: MIT
// 

#import "LiveShareVideoParsingView.h"

@interface LiveShareVideoParsingView ()

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, strong) UILabel *tipLabel;
@property (nonatomic, strong) UIView *lineView;
@property (nonatomic, strong) UIButton *button;

@end

@implementation LiveShareVideoParsingView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupViews];
    }
    return self;
}

- (void)setupViews {
    [self addSubview:self.contentView];
    [self.contentView addSubview:self.activityIndicatorView];
    [self.contentView addSubview:self.tipLabel];
    [self.contentView addSubview:self.lineView];
    [self.contentView addSubview:self.button];
    
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
        make.height.mas_equalTo(104);
    }];
    [self.activityIndicatorView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(21);
        make.centerY.equalTo(self.tipLabel);
        make.size.mas_equalTo(CGSizeMake(15, 15));
    }];
    [self.tipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.activityIndicatorView.mas_right).offset(8);
        make.right.equalTo(self.contentView).offset(-21);
        make.top.equalTo(self.contentView);
        make.height.mas_equalTo(52);
    }];
    [self.lineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.contentView);
        make.centerY.equalTo(self.contentView);
        make.height.mas_equalTo(0.5);
    }];
    [self.button mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.contentView);
        make.top.equalTo(self.lineView.mas_bottom);
    }];
}

- (void)showInview:(UIView *)view {
    self.frame = view.bounds;
    [view addSubview:self];
    [self.activityIndicatorView startAnimating];
}

- (void)buttonClick {
    [self removeFromSuperview];
    if (self.onCancelParsingBlock) {
        self.onCancelParsingBlock();
    }
}

#pragma mark - Getter 
- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc] init];
        _contentView.backgroundColor = UIColor.grayColor;
        _contentView.layer.cornerRadius = 6;
    }
    return _contentView;
}

- (UIActivityIndicatorView *)activityIndicatorView {
    if (!_activityIndicatorView) {
        _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    }
    return _activityIndicatorView;
}

- (UILabel *)tipLabel {
    if (!_tipLabel) {
        _tipLabel = [[UILabel alloc] init];
        _tipLabel.font = [UIFont systemFontOfSize:15];
        _tipLabel.textColor = UIColor.whiteColor;
        _tipLabel.text = LocalizedString(@"please_wait_parsing_url");
    }
    return _tipLabel;
}

- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [[UIView alloc] init];
        _lineView.backgroundColor = [UIColor.whiteColor colorWithAlphaComponent:0.4];
    }
    return _lineView;
}

- (UIButton *)button {
    if (!_button) {
        _button = [[UIButton alloc] init];
        _button.titleLabel.font = [UIFont systemFontOfSize:15];
        [_button setTitle:LocalizedString(@"cancel") forState:UIControlStateNormal];
        [_button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        [_button addTarget:self action:@selector(buttonClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _button;
}

@end
