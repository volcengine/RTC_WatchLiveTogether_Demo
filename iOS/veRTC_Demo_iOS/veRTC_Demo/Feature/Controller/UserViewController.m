//
//  UserNameViewController.m
//  veRTC_Demo
//
//  Created by on 2021/5/18.
//  
//

#import "UserViewController.h"
#import "UserCell.h"
#import "UserHeadView.h"
#import "UserNameViewController.h"
#import "BaseRTCManager.h"
#import "Masonry.h"
#import "Core.h"
#import "NetworkingManager.h"
#import "MenuLoginHome.h"

@interface UserViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *roomTableView;
@property (nonatomic, copy) NSArray *dataLists;
@property (nonatomic, strong) UserHeadView *headView;
@property (nonatomic, strong) BaseButton *logoutButton;
@property (nonatomic, strong) BaseButton *deletAccountButton;

@end

@implementation UserViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorFromHexString:@"#272E3B"];
    
    [self.view addSubview:self.logoutButton];
    [self.logoutButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(44);
        make.bottom.equalTo(self.view).offset(-64 - [DeviceInforTool getVirtualHomeHeight] - 16);
        make.left.equalTo(self.view).offset(16);
        make.right.equalTo(self.view).offset(-16);
    }];
    
    [self.view addSubview:self.deletAccountButton];
    [self.deletAccountButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(44);
        make.bottom.equalTo(self.logoutButton.mas_top).offset(-15);
        make.left.equalTo(self.view).offset(16);
        make.right.equalTo(self.view).offset(-16);
    }];
    
    [self.view addSubview:self.roomTableView];
    [self.roomTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset([DeviceInforTool getStatusBarHight]);
        make.bottom.equalTo(self.deletAccountButton.mas_top).offset(-5);
        make.left.right.equalTo(self.view);
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.headView.nameString = [LocalUserComponent userModel].name;
    [self.roomTableView reloadData];
}

#pragma mark - Publish Action

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UserCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UserCellID" forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.model = self.dataLists[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    MenuCellModel *model = self.dataLists[indexPath.row];
    if (model.isMore) {
        if ([model.title isEqualToString:@"?????????"]) {
            UserNameViewController *next = [[UserNameViewController alloc] init];
            [self.navigationController pushViewController:next animated:YES];
        } else if ([model.title isEqualToString:@"????????????"]) {
            [self jumpToWeb:@"https://www.volcengine.com/docs/6348/68918"];
        } else if ([model.title isEqualToString:@"????????????"]) {
            [self jumpToWeb:@"https://www.volcengine.com/docs/6348/128955"];
        } else if ([model.title isEqualToString:@"????????????"]) {
            [self jumpToWeb:@"https://www.volcengine.com/docs/6348/68917"];
        } else if ([model.title isEqualToString:@"????????????"]) {
            [self jumpToWeb:@"https://www.volcengine.com/docs/6348/68916"];
        } else if ([model.title isEqualToString:@"?????????SDK??????"]) {
            [self jumpToWeb:@"https://www.volcengine.com/docs/6348/133654"];
        } else if ([model.title isEqualToString:@"??????????????????"]) {
            [self jumpToWeb:@"https://www.volcengine.com/docs/6348/155009"];
        } else {
            
        }
    }
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataLists.count;
}

#pragma mark - Private Action

- (void)jumpToWeb:(NSString *)url {
    if (url && [url isKindOfClass:[NSString class]] && url.length > 0) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]
                                           options:@{}
                                 completionHandler:^(BOOL success) {
            
        }];
    }
}

- (void)deleteAccountButtonClick {
    AlertActionModel *alertCancelModel = [[AlertActionModel alloc] init];
    alertCancelModel.title = @"??????";
    __weak typeof(self) weakSelf = self;
    alertCancelModel.alertModelClickBlock = ^(UIAlertAction * _Nonnull action) {
        [MenuLoginHome logout:^(BOOL result) {
            [weakSelf onClickLogoutRoom];
        }];
    };
    
    AlertActionModel *alertModel = [[AlertActionModel alloc] init];
    alertModel.title = @"??????";
    alertModel.alertModelClickBlock = ^(UIAlertAction * _Nonnull action) {
        
    };
    [[AlertActionManager shareAlertActionManager] showWithMessage:@"????????????????????????????????????????????????????????????????????????" actions:@[alertCancelModel, alertModel]];
}

#pragma mark - Private Action

- (void)onClickLogoutRoom {
    [[NSNotificationCenter defaultCenter] postNotificationName:NotificationLoginExpired object:nil];
}

#pragma mark - getter

- (NSArray *)dataLists {
    if (!_dataLists) {
        NSMutableArray *lists = [[NSMutableArray alloc] init];
        
        MenuCellModel *model1 = [[MenuCellModel alloc] init];
        model1.title = @"?????????";
        model1.desTitle = @"";
        model1.isMore = YES;
        [lists addObject:model1];
        
        MenuCellModel *model2 = [[MenuCellModel alloc] init];
        model2.title = @"????????????";
        model2.isMore = YES;
        [lists addObject:model2];
        
        MenuCellModel *model8 = [[MenuCellModel alloc] init];
        model8.title = @"????????????";
        model8.isMore = YES;
        [lists addObject:model8];
        
        MenuCellModel *model3 = [[MenuCellModel alloc] init];
        model3.title = @"????????????";
        model3.isMore = YES;
        [lists addObject:model3];
        
        MenuCellModel *model4 = [[MenuCellModel alloc] init];
        model4.title = @"????????????";
        model4.isMore = YES;
        [lists addObject:model4];
        
        MenuCellModel *model9 = [[MenuCellModel alloc] init];
        model9.title = @"?????????SDK??????";
        model9.isMore = YES;
        [lists addObject:model9];
        
        MenuCellModel *model7 = [[MenuCellModel alloc] init];
        model7.title = @"??????????????????";
        model7.isMore = YES;
        [lists addObject:model7];
        
        NSString *sdkVer = [BaseRTCManager getSdkVersion];
        NSString *appVer = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        
        MenuCellModel *model5 = [[MenuCellModel alloc] init];
        model5.title = @"App??????";
        model5.desTitle = [NSString stringWithFormat:@"v%@", appVer];
        [lists addObject:model5];
        
        MenuCellModel *model6 = [[MenuCellModel alloc] init];
        model6.title = @"SDK??????";
        model6.desTitle = [NSString stringWithFormat:@"v%@", sdkVer];
        [lists addObject:model6];
        
        _dataLists = [lists copy];
    }
    return _dataLists;
}

- (UITableView *)roomTableView {
    if (!_roomTableView) {
        _roomTableView = [[UITableView alloc] init];
        _roomTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _roomTableView.delegate = self;
        _roomTableView.dataSource = self;
        [_roomTableView registerClass:UserCell.class forCellReuseIdentifier:@"UserCellID"];
        _roomTableView.backgroundColor = [UIColor clearColor];
        _roomTableView.rowHeight = UITableViewAutomaticDimension;
        _roomTableView.tableHeaderView = self.headView;
    }
    return _roomTableView;
}

- (BaseButton *)logoutButton {
    if (!_logoutButton) {
        _logoutButton = [[BaseButton alloc] init];
        _logoutButton.backgroundColor = [UIColor clearColor];
        _logoutButton.layer.masksToBounds = YES;
        _logoutButton.layer.cornerRadius = 44/2;
        _logoutButton.layer.borderWidth = 1;
        [_logoutButton setTitle:@"????????????" forState:UIControlStateNormal];
        _logoutButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
        [_logoutButton addTarget:self action:@selector(onClickLogoutRoom) forControlEvents:UIControlEventTouchUpInside];
        _logoutButton.layer.borderColor = [UIColor colorFromHexString:@"#86909C"].CGColor;
        [_logoutButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
    return _logoutButton;
}

- (BaseButton *)deletAccountButton {
    if (!_deletAccountButton) {
        _deletAccountButton = [[BaseButton alloc] init];
        _deletAccountButton.backgroundColor = [UIColor clearColor];
        _deletAccountButton.layer.masksToBounds = YES;
        _deletAccountButton.layer.cornerRadius = 44/2;
        _deletAccountButton.layer.borderWidth = 1;
        [_deletAccountButton setTitle:@"????????????" forState:UIControlStateNormal];
        _deletAccountButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
        [_deletAccountButton addTarget:self action:@selector(deleteAccountButtonClick) forControlEvents:UIControlEventTouchUpInside];
        _deletAccountButton.layer.borderColor = [UIColor colorFromHexString:@"#86909C"].CGColor;
        [_deletAccountButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
    return _deletAccountButton;
}

- (UserHeadView *)headView {
    if (!_headView) {
        _headView = [[UserHeadView alloc] init];
        _headView.frame = CGRectMake(0, 0, SCREEN_WIDTH, 160);
    }
    return _headView;
}

@end
