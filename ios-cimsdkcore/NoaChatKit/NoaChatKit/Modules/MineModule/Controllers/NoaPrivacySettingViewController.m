//
//  NoaPrivacySettingViewController.m
//  NoaKit
//
//  Created by mac on 2024/2/16.
//

#import "NoaPrivacySettingViewController.h"
#import "NoaPrivacySettingTableViewCell.h"
@interface NoaPrivacySettingViewController ()<UITableViewDelegate, UITableViewDataSource, ZBaseCellDelegate>
@property (nonatomic, strong)NSArray *dataArr;
@property (nonatomic, strong) NoaUserModel *userModel;
@end

@implementation NoaPrivacySettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.tkThemebackgroundColors = @[COLOR_F5F6F9, COLOR_11];
    self.navTitleStr = LanguageToolMatch(@"隐私设置");
    [self setupUI];
    [self requestUserInfo];
}

- (void)setupUI {
    self.baseTableView.delegate = self;
    self.baseTableView.dataSource = self;
    self.baseTableView.bounces = NO;
    self.baseTableView.delaysContentTouches = NO;
    self.baseTableView.tkThemebackgroundColors = @[COLOR_F5F6F9, COLOR_11];
    [self.view addSubview:self.baseTableView];
    [self.baseTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(DNavStatusBarH + 16);
        make.leading.trailing.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(-DHomeBarH);
    }];
    
    [self.baseTableView registerClass:[NoaPrivacySettingTableViewCell class] forCellReuseIdentifier:NSStringFromClass([NoaPrivacySettingTableViewCell class])];
}

- (void)requestUserInfo {
    WeakSelf
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:UserManager.userInfo.userUID forKey:@"userUid"];
    [IMSDKManager getUserInfoWith:dict onSuccess:^(id _Nullable data, NSString * _Nullable traceId) {
        
        if ([data isKindOfClass:[NSDictionary class]]) {
            NSDictionary *userDict = (NSDictionary *)data;
            weakSelf.userModel = [NoaUserModel mj_objectWithKeyValues:userDict];
            [weakSelf.baseTableView reloadData];
        }
    } onFailure:^(NSInteger code, NSString * _Nullable msg, NSString * _Nullable traceId) {
        DLog(@"获取用户信息失败");
    }];
}

#pragma mark - UITableViewDelegate  UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return DWScale(74);
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NoaPrivacySettingTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([NoaPrivacySettingTableViewCell class]) forIndexPath:indexPath];
    [cell updateCellUIWith:indexPath.row totalRow:indexPath.row];
    cell.baseCellIndexPath = indexPath;
    cell.baseDelegate = self;
    cell.btnSwitch.selected = self.userModel.showOfflineStatus == 1;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)cellClickAction:(NSIndexPath *)indexPath {
    [self setShowOffLineStatusStatus];
}

//设置离线时长
- (void)setShowOffLineStatusStatus {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if (![NSString isNil:UserManager.userInfo.userUID]) {
        [dict setObjectSafe:UserManager.userInfo.userUID forKey:@"userUid"];
    }
    WeakSelf
    [[NoaIMSDKManager sharedTool] userSetShowOffLineStatusWith:dict onSuccess:^(id _Nullable data, NSString * _Nullable traceId) {
        int isResult = [data intValue];
        weakSelf.userModel.showOfflineStatus = isResult;
        [weakSelf.baseTableView reloadData];
    } onFailure:^(NSInteger code, NSString * _Nullable msg, NSString * _Nullable traceId) {
        [HUD showMessageWithCode:code errorMsg:msg];
    }];
}

- (NoaUserModel *)userModel {
    if (_userModel == nil) {
        _userModel = [[NoaUserModel alloc] init];
    }
    return _userModel;
}

@end
