//
//  NoaTeamInviteDetailVC.m
//  NoaKit
//
//  Created by phl on 2025/7/24.
//

#import "NoaTeamInviteDetailVC.h"
#import "NoaTeamInviteDetailDataHandle.h"
#import "NoaTeamInviteDetailView.h"
#import "NoaTeamInviteEditTeamNameVC.h"
#import "NoaTeamTotalNumberListVC.h"

@interface NoaTeamInviteDetailVC ()

@property (nonatomic, strong) NoaTeamInviteDetailView *teamDetailView;

@property (nonatomic, strong) NoaTeamInviteDetailDataHandle *teamDetailDataHandle;

@end

@implementation NoaTeamInviteDetailVC

- (void)dealloc {
    CIMLog(@"%@ dealloc", [self class]);
}

- (NoaTeamInviteDetailView *)teamDetailView {
    if (!_teamDetailView) {
        _teamDetailView = [[NoaTeamInviteDetailView alloc] initWithFrame:CGRectZero
                                            TeamInviteDetailDataHandle:self.teamDetailDataHandle];
    }
    return _teamDetailView;
}

- (NoaTeamInviteDetailDataHandle *)teamDetailDataHandle {
    if (!_teamDetailDataHandle) {
        _teamDetailDataHandle = [[NoaTeamInviteDetailDataHandle alloc] initWithTeamModel:self.currentTeamModel];
    }
    return _teamDetailDataHandle;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configNavUI];
    [self setupUI];
    [self processData];
    // Do any additional setup after loading the view.
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.teamDetailDataHandle.isOperation) {
        if (self.reloadDataBlock) {
            self.reloadDataBlock();
        }
    }
}

// MARK: UI
/// 界面布局
- (void)configNavUI {
    self.navTitleStr = LanguageToolMatch(@"团队详情");
    
    // 上方导航条透明
    self.navView.tkThemebackgroundColors = @[UIColor.clearColor, UIColor.clearColor];
}

- (void)setupUI {
    [self.view addSubview:self.teamDetailView];
    [self.teamDetailView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.view);
        make.top.equalTo(self.view);
        make.bottom.equalTo(self.view);
    }];
}

- (void)processData {
    @weakify(self)
    [self.teamDetailView.editTeamNameSubject subscribeNext:^(id  _Nullable x) {
        @strongify(self)
        NoaTeamInviteEditTeamNameVC *editTeamNameVC = [NoaTeamInviteEditTeamNameVC new];
        editTeamNameVC.modalPresentationStyle = UIModalPresentationOverFullScreen;
        editTeamNameVC.currentTeamModel = self.currentTeamModel;
        editTeamNameVC.changeTeamNameHandle = ^(NSString * _Nonnull newTeamName) {
            @strongify(self)
            [self.teamDetailDataHandle.changeNewTeamSubject sendNext:newTeamName];
        };
        [self presentViewController:editTeamNameVC animated:YES completion:nil];
    }];
    
    [self.teamDetailDataHandle.jumpAllGroupPeoplePageSubject subscribeNext:^(id  _Nullable x) {
        @strongify(self)
        NoaTeamTotalNumberListVC *totalVC = [NoaTeamTotalNumberListVC new];
        totalVC.teamId = self.currentTeamModel.teamId;
        totalVC.hadTickOutPeopleBlock = ^{
            self.teamDetailDataHandle.isOperation = YES;
            [self.teamDetailView reloadData];
        };
        [self.navigationController pushViewController:totalVC animated:YES];
    }];
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
