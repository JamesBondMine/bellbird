//
//  NoaTeamListVC.m
//  NoaKit
//
//  Created by phl on 2025/7/21.
//  团队邀请-团队列表UI

#import "NoaTeamListVC.h"
#import "NoaTeamListDataHandle.h"
#import "NoaTeamListView.h"
#import "NoaTeamInviteCreateVC.h"
#import "NoaTeamInviteDetailVC.h"

@interface NoaTeamListVC ()

@property (nonatomic, strong) NoaTeamListView *teamListView;

@property (nonatomic, strong) NoaTeamListDataHandle *teamListDataHandle;

@end

@implementation NoaTeamListVC

- (void)dealloc {
    CIMLog(@"%@ dealloc", [self class]);
}

- (NoaTeamListView *)teamListView {
    if (!_teamListView) {
        _teamListView = [[NoaTeamListView alloc] initWithFrame:CGRectZero
                                          TeamListDataHandle:self.teamListDataHandle];
    }
    return _teamListView;
}

- (NoaTeamListDataHandle *)teamListDataHandle {
    if (!_teamListDataHandle) {
        _teamListDataHandle = [NoaTeamListDataHandle new];
    }
    return _teamListDataHandle;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configNavUI];
    [self setupUI];
    [self processData];
}

// MARK: UI
/// 界面布局
- (void)configNavUI {
//    self.view.tkThemebackgroundColors = @[COLORWHITE, COLOR_11];
    
    self.navTitleStr = LanguageToolMatch(@"团队列表");
    
    self.navBtnRight.hidden = NO;
    [self.navBtnRight setTitle:LanguageToolMatch(@"新建团队") forState:UIControlStateNormal];
    [self.navBtnRight setTkThemeTitleColor:@[COLOR_5966F2, COLOR_5966F2_DARK] forState:UIControlStateNormal];
    
    // 上方导航条透明
    self.navView.tkThemebackgroundColors = @[UIColor.clearColor, UIColor.clearColor];
}

- (void)setupUI {
    [self.view addSubview:self.teamListView];
    [self.teamListView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.view);
        make.top.equalTo(self.view);
        make.bottom.equalTo(self.view);
    }];
}

- (void)processData {
    @weakify(self)
    [self.teamListView.jumpDetailVCSubject subscribeNext:^(id  _Nullable x) {
        @strongify(self)
        NoaTeamInviteDetailVC *detailVC = [NoaTeamInviteDetailVC new];
        if ([x isKindOfClass:[NoaTeamModel class]]) {
            NoaTeamModel *teamModel = x;
            detailVC.currentTeamModel = teamModel;
        }
        detailVC.reloadDataBlock = ^{
            @strongify(self)
            [self.teamListView reloadData];
        };
        [self.navigationController pushViewController:detailVC animated:YES];
    }];
}

- (void)navBtnRightClicked {
    NoaTeamInviteCreateVC *createVC = [NoaTeamInviteCreateVC new];
    @weakify(self)
    createVC.createGroupSuccessHandle = ^{
        @strongify(self)
        [self.teamListView reloadData];
    };
    [self.navigationController pushViewController:createVC animated:YES];
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
