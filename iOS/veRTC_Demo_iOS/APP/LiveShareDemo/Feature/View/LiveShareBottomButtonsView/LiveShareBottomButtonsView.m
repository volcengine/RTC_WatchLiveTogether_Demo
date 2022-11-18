//
//  LiveShareBottomButtonsView.m
//  veRTC_Demo
//
//

#import "LiveShareBottomButtonsView.h"

@interface LiveShareBottomButtonsView ()

@property (nonatomic, assign) LiveShareButtonViewType type;

@property (nonatomic, copy) NSArray<UIButton *> *buttonArray;

@end

@implementation LiveShareBottomButtonsView

- (instancetype)initWithType:(LiveShareButtonViewType)type {
    if (self = [super init]) {
        self.type = type;
        [self setupViews];
    }
    return self;
}

- (void)setupViews {
    
    NSArray *buttonTypeArray = [self getButtonTypeArray];
    CGFloat spaceWitdh = [self getItemSpaceWidth];
    CGFloat itemWidth = (self.type == LiveShareButtonViewTypeWatch) ? 36 : 44;
    NSMutableArray<UIButton *> *buttonArray = [NSMutableArray array];
    
    for (int i = 0; i < buttonTypeArray.count; i++) {
        LiveShareButtonType type = [buttonTypeArray[i] integerValue];
        
        UIButton *button = [[UIButton alloc] init];
        button.tag = type;
        [button setImage:[UIImage imageNamed:[self getNormalImageNameWithButtonType:type] bundleName:HomeBundleName] forState:UIControlStateNormal];
        [button setImage:[UIImage imageNamed:[self getSelectedImageNameWithButtonType:type] bundleName:HomeBundleName] forState:UIControlStateSelected];
        [button addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:button];
        [buttonArray addObject:button];
        
        [button mas_makeConstraints:^(MASConstraintMaker *make) {
            if (i == 0) {
                make.left.equalTo(self);
            } else {
                make.left.equalTo(buttonArray[i - 1].mas_right).offset(spaceWitdh);
            }
            make.centerY.equalTo(self);
            make.size.mas_equalTo(CGSizeMake(itemWidth, itemWidth));
            make.top.bottom.equalTo(self);
            if (i == buttonTypeArray.count - 1) {
                make.right.equalTo(self);
            }
        }];
    }
    
    self.buttonArray = buttonArray;
}

#pragma mark - action
- (void)buttonClick:(UIButton *)button {
    LiveShareButtonType type = button.tag;
    button.selected = !button.selected;
    if ([self.delegate respondsToSelector:@selector(liveShareBottomButtonsView:didClickButtonType:)]) {
        [self.delegate liveShareBottomButtonsView:self didClickButtonType:type];
    }
}

#pragma mark - publicMethods

/// 获取麦克风显示状态
- (BOOL)enableAudio {
    for (UIButton *button in self.buttonArray) {
        if (button.tag == LiveShareButtonTypeAudio) {
            return !button.selected;
        }
    }
    return NO;
}
/// 获取摄像头显示状态
- (BOOL)enableVideo {
    for (UIButton *button in self.buttonArray) {
        if (button.tag == LiveShareButtonTypeVideo) {
            return !button.selected;
        }
    }
    return NO;
}

/// 设置麦克风显示状态
/// @param enableAudio 麦克风是否开启
- (void)setEnableAudio:(BOOL)enableAudio {
    
    for (UIButton *button in self.buttonArray) {
        if (button.tag == LiveShareButtonTypeAudio) {
            button.selected = !enableAudio;
        }
    }
}
/// 设置摄像头显示状态
/// @param enableVideo 摄像头是否开启
- (void)setEnableVideo:(BOOL)enableVideo {
    
    for (UIButton *button in self.buttonArray) {
        if (button.tag == LiveShareButtonTypeVideo) {
            button.selected = !enableVideo;
        }
    }
}

#pragma mark - privateMethods
- (NSArray *)getButtonTypeArray {
    NSArray *array = @[];
    if (self.type == LiveShareButtonViewTypePreView) {
        array = @[
            @(LiveShareButtonTypeAudio),
            @(LiveShareButtonTypeVideo),
            @(LiveShareButtonTypeBeauty),
        ];
    }
    else if (self.type == LiveShareButtonViewTypeRoom) {
        if ([LiveShareDataManager shared].isHost) {
            array = @[
                @(LiveShareButtonTypeAudio),
                @(LiveShareButtonTypeVideo),
                @(LiveShareButtonTypeBeauty),
                @(LiveShareButtonTypeWatch),
            ];
        }
        else {
            array = @[
                @(LiveShareButtonTypeAudio),
                @(LiveShareButtonTypeVideo),
                @(LiveShareButtonTypeBeauty),
            ];
        }
    }
    else {
        if ([LiveShareDataManager shared].isHost) {
            array = @[
                @(LiveShareButtonTypeAudio),
                @(LiveShareButtonTypeVideo),
                @(LiveShareButtonTypeBeauty),
                @(LiveShareButtonTypeWatch),
                @(LiveShareButtonTypeSetting),
            ];
        }
        else {
            array = @[
                @(LiveShareButtonTypeAudio),
                @(LiveShareButtonTypeVideo),
                @(LiveShareButtonTypeBeauty),
                @(LiveShareButtonTypeSetting),
            ];
        }
        
    }
    return array;
}

- (NSString *)getNormalImageNameWithButtonType:(LiveShareButtonType)buttonType {
    NSString *imageName = @"";
    switch (buttonType) {
        case LiveShareButtonTypeAudio:
            imageName = @"live_share_mic_on";
            break;
        case LiveShareButtonTypeVideo:
            imageName = @"live_share_camera_on";
            break;
        case LiveShareButtonTypeBeauty:
            imageName = @"live_share_beauty";
            break;
        case LiveShareButtonTypeWatch:
            imageName = @"live_share_watch";
            break;
        case LiveShareButtonTypeSetting:
            imageName = @"live_share_setting";
            break;
            
        default:
            break;
    }
    return imageName;
}

- (NSString *)getSelectedImageNameWithButtonType:(LiveShareButtonType)buttonType {
    NSString *imageName = @"";
    switch (buttonType) {
        case LiveShareButtonTypeAudio:
            imageName = @"live_share_mic_off";
            break;
        case LiveShareButtonTypeVideo:
            imageName = @"live_share_camera_off";
            break;
        case LiveShareButtonTypeBeauty:
            imageName = @"live_share_beauty";
            break;
        case LiveShareButtonTypeWatch:
            imageName = @"live_share_watch";
            break;
        case LiveShareButtonTypeSetting:
            imageName = @"live_share_setting";
            break;
            
        default:
            break;
    }
    return imageName;
}


/// 获取按钮间距
- (CGFloat)getItemSpaceWidth {
    switch (self.type) {
        case LiveShareButtonViewTypePreView:
            return 60;
            break;
        case LiveShareButtonViewTypeRoom:
            return 16;
            break;
        case LiveShareButtonViewTypeWatch:
            return 10;
            break;
            
        default:
            break;
    }
    return 0;;
}

#pragma mark - getter

@end
