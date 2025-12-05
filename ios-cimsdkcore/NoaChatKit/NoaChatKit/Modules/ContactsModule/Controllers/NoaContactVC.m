//
//  NoaContactVC.m
//  NoaKit
//
//  Created by Apple on 2022/9/2.
//

#import "NoaContactVC.h"
#import "NoaContactHeaderView.h"
#import "NoaContactSectionHeaderView.h"

#import <JXCategoryView/JXCategoryView.h>
#import "NoaScrollView.h"
#import "NoaFriendListVC.h"//好友列表
#import "NoaFriendGroupListVC.h"//好友分组列表
#import "NoaGroupListVC.h"//群聊列表

//跳转
#import "NoaAddFriendVC.h"//添加好友
#import "NoaGlobalSearchVC.h"//搜索
#import "NoaNewFriendListVC.h"//新朋友
#import "NoaFileHelperVC.h"//文件助手
#import "NoaSystemMessageVC.h"//群助手
//#import "NoaShareInviteViewController.h"//分享邀请

#import "NoaTabBarController.h"//tabbar
#import "NoaMineVC.h"

@interface NoaContactVC () <ZContactHeaderViewDelegate, UITableViewDelegate, UITableViewDataSource, JXCategoryViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIButton *searchView;
@property (nonatomic, strong) NoaContactHeaderView *viewHeader;
//指示器控件
@property (nonatomic, strong) JXCategoryTitleView *viewCategory;
@property (nonatomic, strong) NoaScrollView *scrollView;
@property (nonatomic, strong) NoaFriendListVC *friendVC;//好友
@property (nonatomic, strong) NoaFriendGroupListVC *friendGroupVC;//好友分组
@property (nonatomic, strong) NoaGroupListVC *groupVC;//群组VC
@property (nonatomic, assign) NSInteger currentSelectedIndex;//当前选中下标
@property (nonatomic, strong) UIScreenEdgePanGestureRecognizer *edgePan;
@end

@implementation NoaContactVC
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.tkThemebackgroundColors = @[COLOR_F8F9FB,COLOR_F8F9FB_DARK];
    //导航栏
    [self initNavBar];
    //全局搜索
    [self initSearchBar];
    //布局
    [self initTableView];
    
    //好友申请红点变化
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateFriendApplyCount) name:@"FriendApplyCountChange" object:nil];
    //主界面是否可以滑动通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainTableViewScrollEnable) name:@"ContactScrollEnable" object:nil];
    //用户角色权限发生变化(是否线上文件助手)
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userRoleAuthorityFileHelperChange) name:@"UserRoleAuthorityFileHelperChangeNotification" object:nil];

    // 左侧边缘右滑，根控制器时唤起抽屉
    UIScreenEdgePanGestureRecognizer *edgePan = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(handleLeftEdgePan:)];
    edgePan.edges = UIRectEdgeLeft;
    edgePan.delegate = self;
    self.edgePan = edgePan;
    [self.view addGestureRecognizer:edgePan];
    // 让表格的滚动手势在边缘返回手势失败后再识别，避免冲突
    [self.baseTableView.panGestureRecognizer requireGestureRecognizerToFail:self.edgePan];
}

//初始化导航
-(void)initNavBar{
    self.navLineView.hidden = YES;
    self.navBtnBack.hidden = YES;
    self.navTitleLabel.text = LanguageToolMatch(@"通讯录");
    [self.navTitleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.navBtnBack);
        make.leading.mas_equalTo(self.navView).offset(DWScale(18));
    }];
    if ([UserManager.userRoleAuthInfo.allowAddFriend.configValue isEqualToString:@"true"]) {
        self.navBtnRight.hidden = NO;
        [self.navBtnRight setTkThemeImage:@[ImgNamed(@"cim_contacts_add"), ImgNamed(@"cim_contacts_add_dark")] forState:UIControlStateNormal];
    } else {
        self.navBtnRight.hidden = YES;
    }
}

//搜索框
-(void)initSearchBar{
    self.searchView = [[UIButton alloc] init];
    self.searchView.tkThemebackgroundColors = @[COLOR_EFEFF2, [COLOR_EFEFF2_DARK colorWithAlphaComponent:0.14]];
    [self.searchView rounded:10.0];
    [self.searchView addTarget:self action:@selector(searchViewClickAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.searchView];
    [self.searchView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.view.mas_leading).offset(DWScale(12));
        make.trailing.mas_equalTo(self.view.mas_trailing).offset(-DWScale(12));
        make.top.mas_equalTo(self.navView.mas_bottom).offset(DWScale(0));
        make.height.mas_equalTo(DWScale(40));
    }];
    
    UIView *view = [UIView new];
    
    UIImageView *searchIcon = [[UIImageView alloc] init];
    searchIcon.image = ImgNamed(@"cim_contacts_search_icon_grey");
    [view addSubview:searchIcon];
    [searchIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.centerY.mas_equalTo(view);
        make.width.mas_equalTo(DWScale(20));
        make.height.mas_equalTo(DWScale(20));
    }];
    
    UILabel *searchTitleLbl = [[UILabel alloc] init];
    searchTitleLbl.text = LanguageToolMatch(@"搜索");
    searchTitleLbl.tkThemetextColors = @[COLOR_B8BDCC, COLOR_B8BDCC_DARK];
    if([ZLanguageTOOL.currentLanguage.languageName_zn isEqualToString:@"法语"]){
        searchTitleLbl.font = FONTR(12);
    }else{
        searchTitleLbl.font = FONTR(16);
    }
    [view addSubview:searchTitleLbl];
    [searchTitleLbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(searchIcon.mas_trailing).offset(DWScale(8));
        make.centerY.trailing.mas_equalTo(view);
        make.height.mas_equalTo(DWScale(38));
    }];
    [self.searchView addSubview:view];
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.centerX.centerY.mas_equalTo(self.searchView);
    }];

}

//初始化TableView
-(void)initTableView{
    
    [self.view addSubview:self.baseTableView];
    self.baseTableView.delaysContentTouches = NO;
    self.baseTableView.delegate = self;
    self.baseTableView.dataSource = self;
    self.baseTableView.backgroundColor = UIColor.clearColor;
    [self.baseTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.mas_equalTo(self.view);
        make.top.mas_equalTo(self.searchView.mas_bottom).offset(DWScale(6));
        make.bottom.equalTo(self.view).offset(-DTabBarH);
    }];
    [self.baseTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:NSStringFromClass([UITableViewCell class])];
    
    _viewHeader = [[NoaContactHeaderView alloc] init];
    if ([UserManager.userRoleAuthInfo.isShowFileAssistant.configValue isEqualToString:@"true"]) {
        _viewHeader.frame = CGRectMake(0, 0, DScreenWidth, DWScale(150));
    } else {
        _viewHeader.frame = CGRectMake(0, 0, DScreenWidth, DWScale(100));
    }
    _viewHeader.delegate = self;
    _viewHeader.newFriendApplyNum = [IMSDKManager toolFriendApplyCount];
    self.baseTableView.tableHeaderView = _viewHeader;
    
    _viewCategory = [[JXCategoryTitleView alloc] initWithFrame:CGRectMake(0, 0, DScreenWidth/2, DWScale(54))];
    _viewCategory.tkThemebackgroundColors = @[COLOR_F8F9FB,COLOR_F8F9FB_DARK];
    _viewCategory.delegate = self;
    _viewCategory.titles = @[LanguageToolMatch(@"好友"), LanguageToolMatch(@"分组"), LanguageToolMatch(@"群聊")];
    _viewCategory.titleColorGradientEnabled = YES;
    _viewCategory.titleLabelZoomScale = NO;
    _viewCategory.titleFont = FONTB(16);
    
    JXCategoryIndicatorLineView *lineView = [[JXCategoryIndicatorLineView alloc] init];
    // 设置指示器固定宽度
    lineView.indicatorWidth = 36;
    lineView.indicatorCornerRadius = 2;
    lineView.indicatorHeight = 3;
    lineView.indicatorColor = COLOR_5966F2;
    // 设置指示器位置（底部）
    lineView.componentPosition = JXCategoryComponentPosition_Bottom;
    _viewCategory.indicators = @[lineView];

    WeakSelf
    self.view.tkThemeChangeBlock = ^(id  _Nullable itself, NSUInteger themeIndex) {
        switch (themeIndex) {
            case 1:
            {
                //暗黑
                weakSelf.viewCategory.titleColor = COLOR_99_DARK;
                weakSelf.viewCategory.titleSelectedColor = COLOR_5966F2;
            }
                break;
                
            default:
            {
                weakSelf.viewCategory.titleColor = COLOR_99;
                weakSelf.viewCategory.titleSelectedColor = COLOR_5966F2;
            }
                break;
        }
    };
    
    _scrollView = [[NoaScrollView alloc] initWithFrame:CGRectMake(0, DWScale(54), DScreenWidth, DScreenHeight - DNavStatusBarH - DWScale(38) - DWScale(54) - DTabBarH)];
    _scrollView.delegate = self;
    _scrollView.pagingEnabled = YES;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.delaysContentTouches = NO;
    _scrollView.contentSize = CGSizeMake(DScreenWidth * 3, 0);
    _scrollView.bounces = NO;
    self.viewCategory.contentScrollView = self.scrollView;
    
    _currentSelectedIndex = 0;
    
    
    _friendVC = [[NoaFriendListVC alloc] init];
    _friendVC.view.frame = CGRectMake(0, 0, DScreenWidth, _scrollView.height);
    [self addChildViewController:_friendVC];
    [self.scrollView addSubview:_friendVC.view];
    
    _friendGroupVC = [[NoaFriendGroupListVC alloc] init];
    _friendGroupVC.view.frame = CGRectMake(DScreenWidth, 0, DScreenWidth, _scrollView.height);
    [self addChildViewController:_friendGroupVC];
    [self.scrollView addSubview:_friendGroupVC.view];
    
    _groupVC = [[NoaGroupListVC alloc] init];
    _groupVC.view.frame = CGRectMake(DScreenWidth * 2, 0, DScreenWidth, _scrollView.height);
    [self addChildViewController:_groupVC];
    [self.scrollView addSubview:_groupVC.view];
}

//添加好友
- (void)navBtnRightClicked {
    NoaAddFriendVC *vc = [NoaAddFriendVC new];
    [self.navigationController pushViewController:vc animated:YES];
}
#pragma mark - ZContactHeaderViewDelegate
- (void)contactHeaderAction:(NSInteger)actionTag {
    if (actionTag == 0) {
        //新朋友
        [self newFriendAction];
    } else if (actionTag == 1){
        //文件助手
        [self fileHelperAction];
    }
    else if (actionTag == 2){
        //群助手
        [self groupHelperAction];
    }
}
//新朋友
- (void)newFriendAction {
    NoaNewFriendListVC *newFriendVC = [[NoaNewFriendListVC alloc] init];
    [self.navigationController pushViewController:newFriendVC animated:YES];
}

//文件助手
- (void)fileHelperAction {
    //好友 系统用户级别
    //文件助手 100002
    NoaFileHelperVC *vc = [NoaFileHelperVC new];
    vc.sessionID = @"100002";
    [self.navigationController pushViewController:vc animated:YES];
}

//群助手
- (void)groupHelperAction {
    LingIMSessionModel *sssionModel = [IMSDKManager toolCheckMySessionWithType:CIMSessionTypeSystemMessage];
    //群助手
    NoaSystemMessageVC *vc = [NoaSystemMessageVC new];
    vc.groupHelperType = ZGroupHelperFormTypeSessionList;
    vc.groupId = @"";
    vc.sessionModel = sssionModel;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Notification
- (void)userRoleAuthorityFileHelperChange {
    if ([UserManager.userRoleAuthInfo.isShowFileAssistant.configValue isEqualToString:@"true"]) {
        _viewHeader.frame = CGRectMake(0, 0, DScreenWidth, DWScale(162));
    } else {
        _viewHeader.frame = CGRectMake(0, 0, DScreenWidth, DWScale(108));
    }
    [_viewHeader updateUI];
}

#pragma mark - SearchClickAction
- (void)searchViewClickAction {
    NoaGlobalSearchVC *vc = [NoaGlobalSearchVC new];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - 好友申请红点变化
- (void)updateFriendApplyCount {
    NSInteger count = [IMSDKManager toolFriendApplyCount];
    
    _viewHeader.newFriendApplyNum = count;
    
    NoaTabBarController *tab = (NoaTabBarController *)self.tabBarController;
    [tab setBadgeValue:1 number:count];
    
}
#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([UITableViewCell class]) forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.contentView.tkThemebackgroundColors = @[COLOR_F8F9FB,COLOR_F8F9FB_DARK];
    [cell.contentView addSubview:_viewCategory];
    [cell.contentView addSubview:_scrollView];
    return cell;
}
#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return DScreenHeight - DNavStatusBarH - DWScale(38) - DTabBarH;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    
    return nil;
    
//    static NSString *headerID = @"ZContactSectionHeaderView";
//    ZContactSectionHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:headerID];
//    if (headerView == nil) {
//        headerView = [[ZContactSectionHeaderView alloc] initWithReuseIdentifier:headerID];
//        [headerView addSubview:_viewCategory];
//        [headerView addSubview:_scrollView];
//    }
//
//    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    //return DScreenHeight - DNavStatusBarH - DWScale(216) - DTabBarH - DHomeBarH;
    return CGFLOAT_MIN;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat offsetY = scrollView.contentOffset.y;
    
    if (offsetY >= DWScale(162)) {
        
        self.baseTableView.scrollEnabled = NO;
        [self.baseTableView setContentOffset:CGPointMake(0, DWScale(162))];
        //[_friendVC friendListScrollEnable:YES];
        [_friendGroupVC friendGroupListScrollEnable:YES];
        [_groupVC groupListScrollEnable:YES];
        
    }else {
        
        self.baseTableView.scrollEnabled = YES;
        //[_friendVC friendListScrollEnable:NO];
        [_friendGroupVC friendGroupListScrollEnable:NO];
        [_groupVC groupListScrollEnable:NO];
    }
    
}

- (void)mainTableViewScrollEnable {
    self.baseTableView.scrollEnabled = YES;
}
#pragma mark - #pragma mark - JXCategoryViewDelegate

- (void)handleLeftEdgePan:(UIScreenEdgePanGestureRecognizer *)recognizer {
    if (self.navigationController.viewControllers.firstObject != self) { return; }
    CGPoint translation = [recognizer translationInView:self.view];
    if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) {
        if (translation.x > 60) {
            [NoaMineVC presentMineDrawerFromTop];
        }
    }
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    // 允许与列表滚动手势同时识别，提升触发概率
    return YES;
}
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer == self.edgePan) {
        // 仅在根控制器时生效，避免与系统右滑返回冲突
        if (self.navigationController.viewControllers.firstObject != self) { return NO; }
    }
    return YES;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

