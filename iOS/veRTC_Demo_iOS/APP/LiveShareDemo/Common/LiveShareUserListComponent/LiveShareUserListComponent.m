//
//  LiveShareUserListComponent.m
//  Pods
//
//

#import "LiveShareUserListComponent.h"
#import "LiveShareUserCollectionViewCell.h"
#import "LiveShareRTCManager.h"
#import "LiveShareDataManager.h"

/// cell 宽高
static CGFloat const kItemWidth = 70;
/// 水平方向cell间距
static CGFloat const kHorizontalSpaceWidth = 16;
/// 竖直方向cell间距
static CGFloat const kVerticalSpaceWidth = 6;

@interface LiveShareUserListComponent ()<UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
/// UI
@property (nonatomic, weak) UIView *superView;

@property (nonatomic, strong) LiveShareUserCollectionViewCell *localUserCell;

/// 全屏用户视图
@property (nonatomic, strong) UIView *fullVideoView;
/// 在线用户列表
@property (nonatomic, strong) UICollectionView *collectionView;
/// 展开/收起View
@property (nonatomic, strong) UIView *userHiddenView;
/// 展开/收起 箭头图标
@property (nonatomic, strong) UIImageView *arrowImageView;

/// 数据源
@property (nonatomic, copy) NSArray<LiveShareUserModel *> *dataArray;

@property (nonatomic, assign) BOOL needShowHeaderUser;

@end

@implementation LiveShareUserListComponent

- (instancetype)initWithSuperview:(UIView *)superView {
    if (self = [super init]) {
        self.superView = superView;
        
        [self setupViews];
        
        self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    }
    return self;
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataArray.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    LiveShareUserCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([LiveShareUserCollectionViewCell class]) forIndexPath:indexPath];
    cell.userModel = [self.dataArray objectAtIndex:indexPath.item];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (!self.shouldSwitchFullUser) {
        return;
    }
    
    [[LiveShareDataManager shared] changeFullUserModelWithModel:self.dataArray[indexPath.item]];
    
    // 展示数据
    [self updateData];
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *view = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:NSStringFromClass([UICollectionReusableView class]) forIndexPath:indexPath];
    
    [view addSubview:self.localUserCell];
    [self.localUserCell mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.top.equalTo(view);
        make.size.mas_offset(CGSizeMake(kItemWidth, kItemWidth));
    }];
    
    return view;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    CGFloat width = kItemWidth;
    CGFloat height = kItemWidth;

    if (self.scrollDirection == UICollectionViewScrollDirectionHorizontal) {
        if (self.needShowHeaderUser) {
            width = kItemWidth + kHorizontalSpaceWidth;
        } else {
            width = 0;
        }
    } else {
        if (self.needShowHeaderUser) {
            height = kItemWidth + kVerticalSpaceWidth;
        } else {
            height = 0;
        }
    }

    return CGSizeMake(width, height);
}


#pragma mark - actions

/// 视频收起窗口点击
- (void)userHiddenViewTap {
    if (self.collectionView.isHidden) {
        [self expandUserCollectionView];
    } else {
        [self foldUserCollectionView];
    }
}

- (void)localUserCellDidTouch {
    if (!self.shouldSwitchFullUser) {
        return;
    }
    
    [[LiveShareDataManager shared] changeFullUserModelWithModel:self.localUserCell.userModel];
    
    // 展示数据
    [self updateData];
}

#pragma mark - privateMethods

/// 初始化UI
- (void)setupViews {
    [self.superView addSubview:self.fullVideoView];
    [self.superView addSubview:self.collectionView];
    [self.superView addSubview:self.userHiddenView];
    
    
    [self.localUserCell mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(kItemWidth, kItemWidth));
    }];
    
    [self.fullVideoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.superView);
    }];
    [self.userHiddenView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.superView).offset(91);
        make.left.equalTo(self.superView).offset(16 + [DeviceInforTool getStatusBarHight]);
        make.height.mas_equalTo(27);
    }];
}

/// 设置水平方向布局
- (void)layoutScrollDirectionHorizontal {
    
    int userCount = 0;
    if (self.needShowHeaderUser) {
        userCount = 1;
    }
    userCount += self.dataArray.count;
    
    CGFloat width = 0;
    if (userCount > 0) {
        width = userCount * kItemWidth + (userCount - 1) * kHorizontalSpaceWidth;
    }
    
    CGFloat maxWidth = MIN(width, (SCREEN_WIDTH - 2 * kHorizontalSpaceWidth));
    
    [self.collectionView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.superView);
        make.top.equalTo(self.superView).offset(40 + [DeviceInforTool getStatusBarHight]);
        make.width.mas_equalTo(maxWidth);
        make.height.mas_equalTo(kItemWidth);
    }];
}

/// 展开用户列表
- (void)expandUserCollectionView {
    [UIView animateWithDuration:0.25 animations:^{
        self.arrowImageView.transform = CGAffineTransformIdentity;
        self.collectionView.hidden = NO;
    }];
}

/// 收起用户列表
- (void)foldUserCollectionView {
    [UIView animateWithDuration:0.25 animations:^{
        self.arrowImageView.transform = CGAffineTransformMakeRotation(M_PI) ;
        self.collectionView.hidden = YES;
    }];
}

#pragma mark - publicMethods

/// 设置全屏数据
/// @param fullUserModel Full user model
- (void)setFullUserModel:(LiveShareUserModel *)fullUserModel {
    _fullUserModel = fullUserModel;
    self.fullVideoView.hidden = !fullUserModel;
    [self updateFullVideoView];
}

- (void)updateFullVideoView {
    UIView *videoView = [[LiveShareRTCManager shareRtc] getStreamViewWithUid:self.fullUserModel.uid];
    if (videoView) {
        [self.fullVideoView addSubview:videoView];
        [videoView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.fullVideoView);
        }];
    }
    videoView.hidden = (self.fullUserModel.camera == LiveShareUserCameraOff);
}

/// 设置数据源
/// @param dataArray Data list
- (void)setDataArray:(NSArray<LiveShareUserModel *> *)dataArray {
    _dataArray = dataArray;
    if (self.scrollDirection == UICollectionViewScrollDirectionHorizontal) {
        [self layoutScrollDirectionHorizontal];
    }
    
    [self.collectionView reloadData];
}

/// 设置滑动方向
/// @param scrollDirection 滑动方向
- (void)setScrollDirection:(UICollectionViewScrollDirection)scrollDirection {
    _scrollDirection = scrollDirection;

    self.collectionView.hidden = NO;

    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    layout.scrollDirection = scrollDirection;

    if (scrollDirection == UICollectionViewScrollDirectionHorizontal) {
        layout.minimumLineSpacing = kHorizontalSpaceWidth;

        self.userHiddenView.hidden = YES;
        [self layoutScrollDirectionHorizontal];
    } else {
        [self.collectionView mas_remakeConstraints:^(MASConstraintMaker *make) {
          make.top.equalTo(self.userHiddenView.mas_bottom).offset(kHorizontalSpaceWidth);
          make.bottom.equalTo(self.superView).offset(-kVerticalSpaceWidth);
          make.width.mas_equalTo(kItemWidth);
          make.centerX.equalTo(self.userHiddenView);
        }];

        layout.minimumLineSpacing = kVerticalSpaceWidth;

        self.userHiddenView.hidden = NO;
        self.arrowImageView.transform = CGAffineTransformIdentity;
    }
}

- (void)updateData {
    if ([[[LiveShareDataManager shared] getFullUserModel].uid isEqualToString:[LocalUserComponent userModel].uid] && self.shouldSwitchFullUser) {
        self.needShowHeaderUser = NO;
    } else {
        self.needShowHeaderUser = YES;
        self.localUserCell.userModel = [[LiveShareDataManager shared] getLocalUserModel];
    }

    if (self.shouldSwitchFullUser) {
        self.fullUserModel = [[LiveShareDataManager shared] getFullUserModel];
        self.dataArray = [[LiveShareDataManager shared] getUserListWithoutFullUserList];
    } else {
        self.dataArray = [[LiveShareDataManager shared] getAllUserList];
    }
}

- (void)updateLocalUserVolume:(NSInteger)volume {
    
    self.localUserCell.volume = volume;
}

- (void)updateRemoteUserVolume:(NSDictionary *)volumeDict {
    for (LiveShareUserCollectionViewCell *cell in self.collectionView.visibleCells) {
        if ([cell.userModel.uid isEqualToString:[LocalUserComponent userModel].uid]) {
            continue;
        }
        NSInteger volume = [[volumeDict objectForKey:cell.userModel.uid] integerValue];
        cell.volume = volume;
    }
}

#pragma mark - getter

- (UIView *)fullVideoView {
    if (!_fullVideoView) {
        _fullVideoView = [[UIView alloc] init];
        _fullVideoView.backgroundColor = UIColor.grayColor;
        _fullVideoView.hidden = YES;
    }
    return _fullVideoView;
}

- (LiveShareUserCollectionViewCell *)localUserCell {
    if (!_localUserCell) {
        _localUserCell = [[LiveShareUserCollectionViewCell alloc] init];
        [_localUserCell addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(localUserCellDidTouch)]];
    }
    return _localUserCell;
}

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.itemSize = CGSizeMake(kItemWidth, kItemWidth);
        layout.sectionHeadersPinToVisibleBounds = YES;
        
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _collectionView.backgroundColor = UIColor.clearColor;
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        
        
        [_collectionView registerClass:[LiveShareUserCollectionViewCell class] forCellWithReuseIdentifier:NSStringFromClass([LiveShareUserCollectionViewCell class])];
        [_collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:NSStringFromClass([UICollectionReusableView class])];
    }
    return _collectionView;
}

- (UIView *)userHiddenView {
    if (!_userHiddenView) {
        _userHiddenView = [[UIView alloc] init];
        _userHiddenView.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.7];
        _userHiddenView.layer.cornerRadius = 4;
        [_userHiddenView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userHiddenViewTap)]];
        
        UILabel *label = [[UILabel alloc] init];
        label.font = [UIFont systemFontOfSize:12];
        label.textColor = UIColor.whiteColor;
        label.text = veString(@"video_window");
        
        [_userHiddenView addSubview:label];
        [_userHiddenView addSubview:self.arrowImageView];
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_userHiddenView).offset(6);
            make.centerY.equalTo(_userHiddenView);
        }];
        [self.arrowImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(label.mas_right).offset(4);
            make.right.equalTo(_userHiddenView).offset(-6);
            make.centerY.equalTo(_userHiddenView);
        }];
    }
    return _userHiddenView;
}

- (UIImageView *)arrowImageView {
    if (!_arrowImageView) {
        _arrowImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"live_share_arrow" bundleName:HomeBundleName]];
    }
    return _arrowImageView;
}

@end
