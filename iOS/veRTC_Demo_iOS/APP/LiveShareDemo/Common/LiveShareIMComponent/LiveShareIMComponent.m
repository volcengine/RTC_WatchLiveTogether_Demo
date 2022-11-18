//
//  LiveShareIMCompoments.m
//  veRTC_Demo
//
//

#import "LiveShareIMComponent.h"
#import "LiveShareIMView.h"

@interface LiveShareIMComponent ()

@property (nonatomic, strong) LiveShareIMView *liveShareIMView;

@end

@implementation LiveShareIMComponent

- (instancetype)initWithSuperView:(UIView *)superView {
    self = [super init];
    if (self) {
        [superView addSubview:self.liveShareIMView];
        [self.liveShareIMView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(16);
            make.right.mas_equalTo(-16);
            make.bottom.mas_equalTo(-56 - ([DeviceInforTool getVirtualHomeHeight]));
            
            CGFloat top = SCREEN_HEIGHT * 0.5 + (SCREEN_WIDTH * 9 / 16) * 0.5 + 10;
            make.top.mas_equalTo(top);
        }];
    }
    return self;
}

#pragma mark - Publish Action

- (void)addIM:(LiveShareIMModel *)model {
    NSMutableArray *datas = [[NSMutableArray alloc] initWithArray:self.liveShareIMView.dataLists];
    [datas addObject:model];
    self.liveShareIMView.dataLists = [datas copy];
}

- (void)setHidden:(BOOL)hidden {
    _hidden = hidden;
    self.liveShareIMView.hidden = hidden;
}

#pragma mark - getter

- (LiveShareIMView *)liveShareIMView {
    if (!_liveShareIMView) {
        _liveShareIMView = [[LiveShareIMView alloc] init];
    }
    return _liveShareIMView;
}

@end
