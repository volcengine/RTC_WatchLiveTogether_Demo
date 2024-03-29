// 
// Copyright (c) 2023 Beijing Volcano Engine Technology Ltd.
// SPDX-License-Identifier: MIT
// 

#import "LiveShareCreateRoomButtonsView.h"

@interface LiveShareCreateRoomButtonsView ()

@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, strong) UIButton *audioButton;
@property (nonatomic, strong) UIButton *videoButton;
@property (nonatomic, strong) UIButton *beautyButton;

@end

@implementation LiveShareCreateRoomButtonsView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupViews];
    }
    return self;
}

- (void)setupViews {
    [self addSubview:self.contentView];
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    
    self.audioButton = [[UIButton alloc] init];
    self.audioButton.tag = LiveShareButtonTypeAudio;
    [self.audioButton setImage:[UIImage imageNamed:@"live_share_room_mic" bundleName:HomeBundleName] forState:UIControlStateNormal];
    [self.audioButton setImage:[UIImage imageNamed:@"live_share_room_mic_s" bundleName:HomeBundleName] forState:UIControlStateSelected];
    
    self.videoButton = [[UIButton alloc] init];
    self.videoButton.tag = LiveShareButtonTypeVideo;
    [self.videoButton setImage:[UIImage imageNamed:@"live_share_room_video" bundleName:HomeBundleName] forState:UIControlStateNormal];
    [self.videoButton setImage:[UIImage imageNamed:@"live_share_room_video_s" bundleName:HomeBundleName] forState:UIControlStateSelected];
    
    self.beautyButton = [[UIButton alloc] init];
    self.beautyButton.tag = LiveShareButtonTypeBeauty;
    [self.beautyButton setImage:[UIImage imageNamed:@"live_share_create_beauty" bundleName:HomeBundleName] forState:UIControlStateNormal];
    [self.beautyButton setImage:[UIImage imageNamed:@"live_share_create_beauty" bundleName:HomeBundleName] forState:UIControlStateHighlighted];
    
    UILabel *audioLabel = [self createLabelWithTitle:LocalizedString(@"microphone")];
    UILabel *videoLabel = [self createLabelWithTitle:LocalizedString(@"camera")];
    UILabel *beautyLabel = [self createLabelWithTitle:LocalizedString(@"effect_button_message")];
    
    [self.contentView addSubview:self.audioButton];
    [self.contentView addSubview:audioLabel];
    [self.contentView addSubview:self.videoButton];
    [self.contentView addSubview:videoLabel];
    [self.contentView addSubview:self.beautyButton];
    [self.contentView addSubview:beautyLabel];
    
    [self.audioButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.equalTo(self.contentView);
        make.size.mas_equalTo(CGSizeMake(44, 44));
    }];
    [audioLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.audioButton.mas_bottom).offset(12);
        make.centerX.equalTo(self.audioButton);
        make.bottom.equalTo(self.contentView);
    }];
    [self.videoButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView);
        make.left.equalTo(self.audioButton.mas_right).offset(60);
        make.size.mas_equalTo(CGSizeMake(44, 44));
    }];
    [videoLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.videoButton.mas_bottom).offset(12);
        make.centerX.equalTo(self.videoButton);
        make.bottom.equalTo(self.contentView);
    }];
    [self.beautyButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView);
        make.left.equalTo(self.videoButton.mas_right).offset(60);
        make.right.equalTo(self.contentView);
        make.size.mas_equalTo(CGSizeMake(44, 44));
    }];
    [beautyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.beautyButton.mas_bottom).offset(12);
        make.centerX.equalTo(self.beautyButton);
        make.bottom.equalTo(self.contentView);
    }];
   
   
    NSArray *buttons = @[self.audioButton, self.videoButton, self.beautyButton];
    for (UIButton *button in buttons) {
        button.adjustsImageWhenHighlighted = NO;
        [button addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
        [self updateButtonColor:button];
        [button mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake(44, 44));
        }];
    }
}

- (void)updateButtonColor:(UIButton *)button {
    [button setImageEdgeInsets:UIEdgeInsetsMake(11, 11, 11, 11)];
    button.imageView.contentMode = UIViewContentModeScaleAspectFit;
    button.backgroundColor = [UIColor colorWithWhite:1 alpha:0.1];
    button.layer.masksToBounds = YES;
    button.layer.cornerRadius = 44/2;
}

- (UILabel *)createLabelWithTitle:(NSString *)title {
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont systemFontOfSize:12];
    label.textColor = UIColor.whiteColor;
    label.text = title;
    return label;
}

#pragma mark - Action

- (void)buttonClick:(UIButton *)button {
    LiveShareButtonType type = button.tag;
    if (type == LiveShareButtonTypeAudio || type == LiveShareButtonTypeVideo) {
        button.selected = !button.selected;
    }
    if ([self.delegate respondsToSelector:@selector(liveShareCreateRoomButtonsView:didClickButtonType:)]) {
        [self.delegate liveShareCreateRoomButtonsView:self didClickButtonType:type];
    }
}

- (BOOL)enableAudio {
    return !self.audioButton.isSelected;
}

- (void)setEnableAudio:(BOOL)enableAudio {
    self.audioButton.selected = !enableAudio;
}

- (BOOL)enableVideo {
    return !self.videoButton.isSelected;
}

- (void)setEnableVideo:(BOOL)enableVideo {
    self.videoButton.selected = !enableVideo;
}

#pragma mark - Getter

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc] init];
    }
    return _contentView;
}

@end
