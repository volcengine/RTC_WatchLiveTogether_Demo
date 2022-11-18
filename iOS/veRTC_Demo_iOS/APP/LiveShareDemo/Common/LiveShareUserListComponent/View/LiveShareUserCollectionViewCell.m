//
//  LiveShareUserCollectionViewCell.m
//  
//
//

#import "LiveShareUserCollectionViewCell.h"
#import "LiveShareRTCManager.h"

@interface LiveShareUserCollectionViewCell ()

@property (nonatomic, strong) UIView *videoView;
@property (nonatomic, strong) UIImageView *micImageView;

@end

@implementation LiveShareUserCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupViews];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.volume = 0;
}

#pragma mark - privateMethods
- (void)setupViews {
    self.contentView.layer.cornerRadius = 4;
    self.contentView.layer.masksToBounds = YES;
    self.contentView.layer.borderWidth = 2;
    self.contentView.layer.borderColor = [UIColor clearColor].CGColor;
    self.contentView.backgroundColor = UIColor.grayColor;
    
    [self.contentView addSubview:self.videoView];
    [self.contentView addSubview:self.micImageView];
    
    [self.videoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView);
    }];
    [self.micImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.right.equalTo(self.contentView);
        make.size.mas_equalTo(CGSizeMake(24, 24));
    }];
}

- (void)updateUI {
    UIView *videoView = [[LiveShareRTCManager shareRtc] getStreamViewWithUid:self.userModel.uid];
    if (videoView) {
        videoView.hidden = NO;
        [self.videoView addSubview:videoView];
        [videoView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.videoView);
        }];
    }
    self.videoView.hidden = (self.userModel.camera == LiveShareUserCameraOff);
    self.micImageView.hidden = (self.userModel.mic == LiveShareUserMicOn);
}

#pragma mark - publicMethods
- (void)setUserModel:(LiveShareUserModel *)userModel {
    _userModel = userModel;
    
    [self updateUI];
}

- (void)setVolume:(NSInteger)volume {
    _volume = volume;
    
    if (volume > 60 && (self.userModel.mic == LiveShareUserMicOn)) {
        self.contentView.layer.borderColor = [UIColor greenColor].CGColor;
    }
    else {
        self.contentView.layer.borderColor = [UIColor clearColor].CGColor;
    }
}


#pragma mark - getter
- (UIView *)videoView {
    if (!_videoView) {
        _videoView = [[UIView alloc] init];
    }
    return _videoView;
}

- (UIImageView *)micImageView {
    if (!_micImageView) {
        _micImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"live_share_user_mic_off" bundleName:HomeBundleName]];
    }
    return _micImageView;
}

@end
