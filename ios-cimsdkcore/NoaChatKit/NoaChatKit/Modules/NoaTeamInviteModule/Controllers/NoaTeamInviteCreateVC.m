//
//  NoaTeamInviteCreateVC.m
//  NoaKit
//
//  Created by phl on 2025/7/22.
//  团队邀请-团队创建

#import "NoaTeamInviteCreateVC.h"
#import "NoaTeamCreateDataHandle.h"
#import "NoaTeamCreateView.h"

@interface NoaTeamInviteCreateVC ()

@property (nonatomic, strong) NoaTeamCreateView *teamCreateView;

@property (nonatomic, strong) NoaTeamCreateDataHandle *teamCreateDataHandle;

@end

@implementation NoaTeamInviteCreateVC

- (void)dealloc {
    CIMLog(@"%@ dealloc", [self class]);
}

- (NoaTeamCreateView *)teamCreateView {
    if (!_teamCreateView) {
        _teamCreateView = [[NoaTeamCreateView alloc] initWithFrame:CGRectZero
                                            TeamCreateDataHandle:self.teamCreateDataHandle];
    }
    return _teamCreateView;
}

- (NoaTeamCreateDataHandle *)teamCreateDataHandle {
    if (!_teamCreateDataHandle) {
        _teamCreateDataHandle = [NoaTeamCreateDataHandle new];
    }
    return _teamCreateDataHandle;
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
    self.navTitleStr = LanguageToolMatch(@"新建团队");
    
    // 上方导航条透明
    self.navView.tkThemebackgroundColors = @[UIColor.clearColor, UIColor.clearColor];
}

- (void)setupUI {
    [self.view addSubview:self.teamCreateView];
    [self.teamCreateView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.view);
        make.top.equalTo(self.view);
        make.bottom.equalTo(self.view);
    }];
}

- (void)processData {
    @weakify(self)
    [self.teamCreateDataHandle.backSubject subscribeNext:^(id  _Nullable x) {
        @strongify(self)
        if (self.createGroupSuccessHandle) {
            self.createGroupSuccessHandle();
        }
        [self.navigationController popViewControllerAnimated:YES];
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
