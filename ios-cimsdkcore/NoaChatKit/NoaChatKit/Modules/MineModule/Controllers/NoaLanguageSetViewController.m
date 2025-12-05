//
//  NoaLanguageSetViewController.m
//  NoaKit
//
//  Created by Mac on 2022/12/28.
//

#import "NoaLanguageSetViewController.h"
#import "NoaLanguageSettingCell.h"
#import "NoaToolManager.h"

@interface NoaLanguageSetViewController () <UITableViewDelegate, UITableViewDataSource, ZBaseCellDelegate>

@property (nonatomic, strong) NoaLanguageInfo * selectInfo;
@property (nonatomic, copy) NSArray * dataArray;

@end

@implementation NoaLanguageSetViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.tkThemebackgroundColors = @[COLOR_F5F6F9, COLOR_11];
    self.navTitleStr = LanguageToolMatch(@"语言");
    [self setUpNavUI];
    [self setupUI];
    self.selectInfo = [NoaLanguageManager shareManager].currentLanguage;
    self.dataArray = [NoaLanguageManager shareManager].languageList;
    [self.baseTableView reloadData];

}
- (void)setUpNavUI {
    self.navBtnRight.hidden = NO;
    [self.navBtnRight setTitle:LanguageToolMatch(@"确定") forState:UIControlStateNormal];
    [self.navBtnRight setTkThemeTitleColor:@[COLORWHITE, COLORWHITE] forState:UIControlStateNormal];
    self.navBtnRight.tkThemebackgroundColors = @[COLOR_5966F2, COLOR_5966F2];
    [self.navBtnRight rounded:DWScale(12)];
    [self.navBtnRight mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.navTitleLabel);
        make.trailing.equalTo(self.navView).offset(-DWScale(20));
        make.height.mas_equalTo(DWScale(32));
        make.width.mas_equalTo(DWScale(60));
    }];
}

- (void)setupUI {
    self.baseTableView.delegate = self;
    self.baseTableView.dataSource = self;
    self.baseTableView.tkThemebackgroundColors = @[COLOR_F5F6F9, COLOR_11];
    [self.view addSubview:self.baseTableView];
    [self.baseTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(DNavStatusBarH);
        make.leading.trailing.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(-DHomeBarH);
    }];
    
    [self.baseTableView registerClass:[NoaLanguageSettingCell class] forCellReuseIdentifier:NSStringFromClass([NoaLanguageSettingCell class])];
}

#pragma mark - UITableViewDelegate, UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NoaLanguageSettingCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([NoaLanguageSettingCell class]) forIndexPath:indexPath];
    
    NoaLanguageInfo * info = [NoaLanguageManager shareManager].languageList[indexPath.row];
    
    cell.lblTitle.text = info.languageName;
    if ([self.selectInfo.languageName isEqualToString:info.languageName]) {
        cell.ivSelected.hidden = NO;
    }else {
        cell.ivSelected.hidden = YES;
    }
    cell.lbBelowlTitle.text = LanguageToolMatch(info.languageName_zn);
    cell.baseCellIndexPath = indexPath;
    cell.baseDelegate = self;
    [cell configCellRoundWithCellIndex:indexPath.row totalIndex:self.dataArray.count];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return DWScale(54);
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return DWScale(16);
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, DScreenWidth, DWScale(16))];
    headerView.tkThemebackgroundColors = @[COLOR_F5F6F9, COLOR_11];
    return headerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - ZBaseCellDelegate
- (void)cellClickAction:(NSIndexPath *)indexPath {
    self.selectInfo = [self.dataArray objectAtIndex:indexPath.row];
    //reloadData
    [self.baseTableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark - Action
- (void)navBtnRightClicked {
    //在业务层保存设置的语言时处理，不影响语言模块的封装
    //存储的标识 按照简体中文来实现的
    [[MMKV defaultMMKV] setString:self.selectInfo.languageName_zn forKey:Z_LANGUAGE_SELECTES_TYPE];
    [self updateFileHelperLanguage];
    if (_changeType == LanguageChangeUITypeLogin) {
//        ZSsoInfoModel *ssoModel = [ZSsoInfoModel getSSOInfo];
//        if (ssoModel == nil || (ssoModel.liceseId.length <= 0 && ssoModel.ipDomainPortStr.length <= 0)) {
//            //更新SSO
//            [ZTOOL setupSsoSetVcUI];
//        } else {
//            //更新 登录
//            [ZTOOL setupLoginUI];
//        }
        [ZTOOL setupSsoSetVcUI];
    }else {
        //默认 更新tabbar
        [ZTOOL setupTabBarUI];
    }
}

#pragma mark - 修改本地语言后更新 文件助手
- (void)updateFileHelperLanguage {
    //更新会话列表文件助手
    [ZTOOL sessionFileHelperLanguageUpdate];
    //更新通讯录文件助手
    [ZTOOL connectFileHelperLanguageUpdate];
}
@end
