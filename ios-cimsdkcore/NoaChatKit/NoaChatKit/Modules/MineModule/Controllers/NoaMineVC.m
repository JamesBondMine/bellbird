//
//  NoaMineVC.m
//  NoaKit
//
//  Created by Apple on 2022/9/2.
//

#import "NoaMineVC.h"
#import "NoaMineInfoView.h"
#import "NoaMineCenterCell.h"

#import "NoaUserInfoViewController.h"//个人资料
#import "NoaBlackListViewController.h"//黑名单
#import "NoaSafeSettingViewController.h"//安全设置
#import "NoaSystemSettingViewController.h"//系统设置
#import "NoaMyQRCodeViewController.h"//我的二维码
#import "NoaMyCollectionViewController.h"//我的收藏
#import "NoaComplainVC.h"//投诉与支持
#import "NoaLanguageSetViewController.h"//多语言
#import "NoaAboutUsViewController.h"//关于我们
#import "NoaShareInviteViewController.h"//分享邀请
#import "NoaSignInViewController.h" //签到页面
#import "NoaTranslateSetDefaultViewController.h" //翻译管理
#import "NoaPrivacySettingViewController.h"
#import "NoaTeamVC.h"//团队
#import "NoaTeamListVC.h"
#import "NoaQRCodeModel.h"
// 网络检测页面
#import "NoaNetworkDetectionVC.h"
#import "NoaDrawerPresentationController.h"
#import "NoaDrawerTransitioningDelegate.h"
#import <objc/runtime.h>

@interface NoaMineReturnObserver : NSObject <UINavigationControllerDelegate>
@property (nonatomic, weak) UINavigationController *navigationController;
@property (nonatomic, weak) UIViewController *observedViewController;
@property (nonatomic, weak) id<UINavigationControllerDelegate> previousDelegate;
@property (nonatomic, copy) void (^onPopped)(void);
@end

@implementation NoaMineReturnObserver
- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (!self.observedViewController) {
        navigationController.delegate = self.previousDelegate;
        self.onPopped = nil;
        return;
    }
    BOOL hasObserved = [navigationController.viewControllers containsObject:self.observedViewController];
    if (!hasObserved) {
        id<UINavigationControllerDelegate> prev = self.previousDelegate;
        navigationController.delegate = prev;
        if (self.onPopped) { self.onPopped(); }
        // 解除与 nav 的关联，释放观察器
        objc_setAssociatedObject(navigationController, @selector(navigationController:didShowViewController:animated:), nil, OBJC_ASSOCIATION_ASSIGN);
    }
}
@end

@interface NoaMineVC () <UITableViewDelegate, UITableViewDataSource, ZBaseCellDelegate, ZMineInfoViewDelegate>

@property (nonatomic, strong) NoaMineInfoView *viewMineInfo;
@property (nonatomic, strong)NSMutableArray *dataArr;

@end

@implementation NoaMineVC

// 统一方式重新 present 抽屉样式的 ZMineVC
+ (void)presentMineDrawerFromTop {
    UIViewController *rootVC = [UIApplication sharedApplication].delegate.window.rootViewController;
    UINavigationController *presenterNav = nil;
    if ([rootVC isKindOfClass:[UITabBarController class]]) {
        UIViewController *selected = ((UITabBarController *)rootVC).selectedViewController;
        if ([selected isKindOfClass:[UINavigationController class]]) {
            presenterNav = (UINavigationController *)selected;
        }
    } else if ([rootVC isKindOfClass:[UINavigationController class]]) {
        presenterNav = (UINavigationController *)rootVC;
    }
    if (!presenterNav) { return; }

    // 去重：若已展示抽屉，则不重复 present
    UIViewController *presented = presenterNav.presentedViewController;
    if ([presented isKindOfClass:[UINavigationController class]]) {
        UINavigationController *pnav = (UINavigationController *)presented;
        UIViewController *first = pnav.viewControllers.firstObject;
        if ([first isKindOfClass:[NoaMineVC class]] && pnav.transitioningDelegate) {
            return;
        }
    }

    NoaMineVC *mine = [NoaMineVC new];
    UINavigationController *drawerNav = [[UINavigationController alloc] initWithRootViewController:mine];
    drawerNav.navigationBarHidden = YES;
    drawerNav.modalPresentationStyle = UIModalPresentationCustom;
    NoaDrawerTransitioningDelegate *transDelegate = [NoaDrawerTransitioningDelegate new];
    transDelegate.contentWidthRatio = 0.8;
    transDelegate.duration = 0.28;
    drawerNav.transitioningDelegate = (id<UIViewControllerTransitioningDelegate>)transDelegate;
    objc_setAssociatedObject(drawerNav, @selector(transitioningDelegate), transDelegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [presenterNav presentViewController:drawerNav animated:YES completion:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self updateUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 当返回到 ZMineVC（成为顶部 VC）时，恢复抽屉为 0.8 宽度
    if (self.navigationController.topViewController == self) {
        UIPresentationController *pc = self.navigationController.presentationController;
        if ([pc isKindOfClass:[NoaDrawerPresentationController class]]) {
            NoaDrawerPresentationController *drawer = (NoaDrawerPresentationController *)pc;
            [drawer updateContentWidthRatio:0.8 animated:YES];
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupUI];
    [self setupNotification];
    [self setUpData];
}

- (void)setupUI {
    self.navView.hidden = YES;
    
    self.view.tkThemebackgroundColors = @[COLORWHITE, HEXCOLOR(@"27292E")];
    
    _viewMineInfo = [[NoaMineInfoView alloc] init];
    _viewMineInfo.delegate = self;
    _viewMineInfo.mineModel = UserManager.userInfo;
    [self.view addSubview:_viewMineInfo];
    [_viewMineInfo mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.view);
        make.height.mas_equalTo(DWScale(185));
    }];
    
    self.baseTableViewStyle = UITableViewStylePlain;
    self.baseTableView.delegate = self;
    self.baseTableView.dataSource = self;
    self.baseTableView.separatorColor = COLOR_CLEAR;
    self.baseTableView.delaysContentTouches = NO;
    self.baseTableView.tkThemebackgroundColors = @[COLORWHITE, HEXCOLOR(@"27292E")];
    [self.view addSubview:self.baseTableView];
    [self.baseTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(@12);
        make.trailing.equalTo(self.view).offset(-12);
        make.top.equalTo(_viewMineInfo.mas_bottom).offset(12);
        make.bottom.equalTo(self.view).offset(-DTabBarH);
    }];
    [self.baseTableView registerClass:[NoaMineCenterCell class] forCellReuseIdentifier:NSStringFromClass([NoaMineCenterCell class])];
}

#pragma mark - Navigation Helper
- (void)openFullScreen:(UIViewController *)vc {
    if (!vc) { return; }
    vc.hidesBottomBarWhenPushed = YES;

    // 优先使用当前可见的导航
    UINavigationController *currentNav = self.navigationController;

    // 若当前在抽屉容器中，改为先隐藏（dismiss）抽屉效果，再在根部导航上 push 全屏页面
    UIPresentationController *pc = currentNav.presentationController;
    if ([pc isKindOfClass:[NoaDrawerPresentationController class]]) {
        [self.navigationController dismissViewControllerAnimated:YES completion:^{
            UIViewController *rootVC = [UIApplication sharedApplication].delegate.window.rootViewController;
            UINavigationController *targetNav = nil;
            if ([rootVC isKindOfClass:[UITabBarController class]]) {
                UIViewController *selected = ((UITabBarController *)rootVC).selectedViewController;
                if ([selected isKindOfClass:[UINavigationController class]]) {
                    targetNav = (UINavigationController *)selected;
                }
            } else if ([rootVC isKindOfClass:[UINavigationController class]]) {
                targetNav = (UINavigationController *)rootVC;
            }
            if (targetNav) {
                vc.hidesBottomBarWhenPushed = YES;
                // 建立 pop 观察器：当 vc 被 pop 时重新 present 抽屉 ZMineVC
                NoaMineReturnObserver *observer = [NoaMineReturnObserver new];
                observer.navigationController = targetNav;
                observer.observedViewController = vc;
                observer.previousDelegate = targetNav.delegate;
                __weak typeof(targetNav) weakNav = targetNav;
                observer.onPopped = ^{
                    if (!weakNav) { return; }
                    [NoaMineVC presentMineDrawerFromTop];
                };
                targetNav.delegate = (id<UINavigationControllerDelegate>)observer;
                objc_setAssociatedObject(targetNav, @selector(navigationController:didShowViewController:animated:), observer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                [targetNav pushViewController:vc animated:YES];
            }
        }];
        return;
    }

    // 精确获取“我的”Tab对应的导航控制器，确保返回时仍回到 ZMineVC
    UINavigationController *mineNav = nil;
    UITabBarController *tab = self.tabBarController;
    if ([tab isKindOfClass:[UITabBarController class]]) {
        for (UIViewController *vcItem in tab.viewControllers) {
            if ([vcItem isKindOfClass:[UINavigationController class]]) {
                UINavigationController *navItem = (UINavigationController *)vcItem;
                UIViewController *root = navItem.viewControllers.firstObject;
                if ([root isKindOfClass:[NoaMineVC class]]) {
                    mineNav = navItem;
                    break;
                }
            }
        }
    }

    // 获取根部导航（Tab 内的选中导航 or 根导航）
    UINavigationController *rootNav = nil;
    UIViewController *rootVC = [UIApplication sharedApplication].delegate.window.rootViewController;
    if ([rootVC isKindOfClass:[UINavigationController class]]) {
        rootNav = (UINavigationController *)rootVC;
    } else if ([rootVC isKindOfClass:[UITabBarController class]]) {
        UIViewController *selected = ((UITabBarController *)rootVC).selectedViewController;
        if ([selected isKindOfClass:[UINavigationController class]]) {
            rootNav = (UINavigationController *)selected;
        }
    }

    // 如果当前页面（或其导航）是以半屏方式呈现（非抽屉的其他场景），可作为兜底：无动画关闭后在根导航 push
    BOOL presentedAsSheet = NO;
    if (currentNav) {
        presentedAsSheet = (currentNav.presentingViewController != nil && currentNav.modalPresentationStyle != UIModalPresentationFullScreen);
    } else {
        presentedAsSheet = (self.presentingViewController != nil && self.modalPresentationStyle != UIModalPresentationFullScreen);
    }

    if (presentedAsSheet && (mineNav || rootNav)) {
        [self dismissViewControllerAnimated:NO completion:^{
            if (tab && mineNav) {
                tab.selectedViewController = mineNav;
                [mineNav pushViewController:vc animated:YES];
            } else {
                [rootNav pushViewController:vc animated:YES];
            }
        }];
        return;
    }

    // 正常 push
    if (currentNav) {
        [currentNav pushViewController:vc animated:YES];
        return;
    }
    if (mineNav) {
        [mineNav pushViewController:vc animated:YES];
        return;
    }
    if (rootNav) {
        [rootNav pushViewController:vc animated:YES];
    }
}

- (void)closeFullScreen {
    [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)setupNotification {
    //监听用户信息更新
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUI) name:@"MineUserInfoUpdate" object:nil];
    //用户角色权限发生变化(是否显示 团队管理 和 分享邀请)
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setUpData) name:@"UserRoleAuthorityShowTeamChangeNotification" object:nil];
    // 翻译开关变化（翻译管理入口显隐）
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setUpData) name:UserRoleAuthorityTranslateFlagDidChange object:nil];
}

- (void)setUpData {
    [self.dataArr removeAllObjects];
    
    NSDictionary *teamManagerDic = @{@"imageName":@"mine_teamManager", @"titleName" : LanguageToolMatch(@"我的团队")};
    NSDictionary *myQRCodeDic = @{@"imageName":@"mine_qrCode", @"titleName" : LanguageToolMatch(@"二维码")};
    NSDictionary *signDic = @{@"imageName":@"mine_sign", @"titleName" : LanguageToolMatch(@"签到日历")};
    NSDictionary *myCollectionDic = @{@"imageName":@"mine_collection", @"titleName" : LanguageToolMatch(@"我的收藏")};
    NSDictionary *friendBlackDic = @{@"imageName":@"mine_black", @"titleName" : LanguageToolMatch(@"黑名单")};
    NSDictionary *characterDic = @{@"imageName":@"mine_character", @"titleName" : LanguageToolMatch(@"翻译管理")};
    NSDictionary *appLanguageDic = @{@"imageName":@"mine_language", @"titleName" : LanguageToolMatch(@"应用语言")};
    NSDictionary *privacySettingDic = @{@"imageName":@"mine_privacy_setting", @"titleName" : LanguageToolMatch(@"隐私设置")};
    NSDictionary *safeSettingDic = @{@"imageName":@"mine_safe", @"titleName" : LanguageToolMatch(@"安全设置")};
    NSDictionary *complainDic = @{@"imageName":@"mine_complain", @"titleName" : LanguageToolMatch(@"投诉与支持")};
    NSDictionary *networkDetectionDic = @{@"imageName":@"mine_networkDetect", @"titleName" : LanguageToolMatch(@"网络检测")};
    NSDictionary *aboutUsDic = @{@"imageName":@"mine_about", @"titleName" : LanguageToolMatch(@"关于")};
    
    //是否显示“团队管理”和“分享邀请”
    if ([UserManager.userRoleAuthInfo.showTeam.configValue isEqualToString:@"true"]) {
        NSArray *sectionOneArray = @[myQRCodeDic, teamManagerDic, signDic];
        
        [self.dataArr addObject:sectionOneArray];
    } else {
        NSArray *sectionOneArray = @[myQRCodeDic, signDic];
        [self.dataArr addObject:sectionOneArray];
    }
    
    NSMutableArray *sectionTwoArray = [NSMutableArray array];
    [sectionTwoArray addObject:myCollectionDic];
    [sectionTwoArray addObject:friendBlackDic];
    [sectionTwoArray addObject:appLanguageDic];
    BOOL translateEnabled = [UserManager isTranslateEnabled];
    if (translateEnabled) {
        [sectionTwoArray addObject:characterDic];
    }
    [sectionTwoArray addObject:networkDetectionDic];
    [sectionTwoArray addObject:safeSettingDic];
    [sectionTwoArray addObject:privacySettingDic];
    [sectionTwoArray addObject:complainDic];
    [sectionTwoArray addObject:aboutUsDic];
    
    [self.dataArr addObject:sectionTwoArray];
    
    [self.baseTableView reloadData];
}

#pragma mark - 界面更新
- (void)updateUI {
    _viewMineInfo.mineModel = UserManager.userInfo;
    [self.baseTableView reloadData];
}

#pragma mark - UITableViewDelegate  UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.dataArr.count;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *rowArray = [self.dataArr objectAtIndexSafe:section];
    return rowArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return DWScale(42);
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *viewHeader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, DScreenWidth, DWScale(12))];
    viewHeader.tkThemebackgroundColors = @[COLORWHITE, HEXCOLOR(@"27292E")];
    return viewHeader;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return DWScale(0.01);
    }
    return DWScale(12);
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NoaMineCenterCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([NoaMineCenterCell class]) forIndexPath:indexPath];
    NSArray *rowArray = [self.dataArr objectAtIndexSafe:indexPath.section];
    [cell configCellCornerWith:indexPath totalIndex:rowArray.count];
    [cell configCellTipWith:indexPath];
    cell.dataDic = (NSDictionary *)[rowArray objectAtIndexSafe:indexPath.row];
    cell.baseCellIndexPath = indexPath;
    cell.baseDelegate = self;
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    NSArray *rowArr = [self.dataArr objectAtIndexSafe:section];
    if (!rowArr) {
        return;
    }
    
    if (rowArr.count < 1) {
        return;
    }
    
    if (rowArr.count == 1) {
        // 只有一个
        if (!CGRectIsEmpty(cell.contentView.bounds)) {
            UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:cell.contentView.bounds
                                                           byRoundingCorners:UIRectCornerAllCorners
                                                                 cornerRadii:CGSizeMake(8, 8)];
            
            CAShapeLayer *maskLayer = [CAShapeLayer layer];
            maskLayer.frame = cell.contentView.bounds;
            maskLayer.path = maskPath.CGPath;
            cell.layer.mask = maskLayer;
        }
        return;
    }
    
    if (row == 0) {
        // 第一个
        UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:cell.contentView.bounds
                                                       byRoundingCorners:(UIRectCornerTopLeft | UIRectCornerTopRight)
                                                             cornerRadii:CGSizeMake(8, 8)];
        
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        maskLayer.frame = cell.contentView.bounds;
        maskLayer.path = maskPath.CGPath;
        cell.layer.mask = maskLayer;
    }else if (row == rowArr.count - 1) {
        // 最后一个
        UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:cell.contentView.bounds
                                                       byRoundingCorners:(UIRectCornerBottomLeft | UIRectCornerBottomRight)
                                                             cornerRadii:CGSizeMake(8, 8)];
        
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        maskLayer.frame = cell.contentView.bounds;
        maskLayer.path = maskPath.CGPath;
        cell.layer.mask = maskLayer;
    }else {
        // 不切角
        cell.layer.mask = nil;
    }
  
}

#pragma mark - ZBaseCellDelegate
- (void)cellClickAction:(NSIndexPath *)indexPath {
    NSArray *sectionArray = [self.dataArr objectAtIndexSafe:indexPath.section];
    NSDictionary *rowDic = (NSDictionary *)[sectionArray objectAtIndexSafe:indexPath.row];
    NSString *titleName = (NSString *)[rowDic objectForKeySafe:@"titleName"];
    if ([titleName isEqualToString:LanguageToolMatch(@"二维码")]) {
        //我的二维码
        [self getQtcondeContent];
    }
    if ([titleName isEqualToString:LanguageToolMatch(@"我的团队")]) {
        //团队管理
        /**
         * 旧版本代码
         * NoaTeamVC *teamVC = [[NoaTeamVC alloc] init];
         */
        NoaTeamListVC *teamVC = [NoaTeamListVC new];
        [self openFullScreen:teamVC];
    }
    if ([titleName isEqualToString:LanguageToolMatch(@"签到日历")]) {
        NoaSignInViewController * signInVC = [[NoaSignInViewController alloc] init];
        [self openFullScreen:signInVC];
    }

    if ([titleName isEqualToString:LanguageToolMatch(@"我的收藏")]) {
        //我的收藏
        NoaMyCollectionViewController *myCollectionVC = [[NoaMyCollectionViewController alloc] init];
        myCollectionVC.isFromChat = NO;
        [self openFullScreen:myCollectionVC];
    }
    if ([titleName isEqualToString:LanguageToolMatch(@"黑名单")]) {
        //黑名单
        NoaBlackListViewController *blackListVC = [[NoaBlackListViewController alloc] init];
        [self openFullScreen:blackListVC];
    }
    if ([titleName isEqualToString:LanguageToolMatch(@"翻译管理")]) {
        //翻译管理
        NoaTranslateSetDefaultViewController *vc = [[NoaTranslateSetDefaultViewController alloc] init];
        [self openFullScreen:vc];
    }
    if ([titleName isEqualToString:LanguageToolMatch(@"应用语言")]) {
        //多语言
        NoaLanguageSetViewController *languageSetVC = [[NoaLanguageSetViewController alloc] init];
        languageSetVC.changeType = LanguageChangeUITypeTabbar;
        [self openFullScreen:languageSetVC];
    }
    if ([titleName isEqualToString:LanguageToolMatch(@"隐私设置")]) {
        //隐私设置
        NoaPrivacySettingViewController *privacySettingVC = [[NoaPrivacySettingViewController alloc] init];
        [self openFullScreen:privacySettingVC];
    }
    if ([titleName isEqualToString:LanguageToolMatch(@"安全设置")]) {
        //安全设置
        NoaSafeSettingViewController *safeSettingVC = [[NoaSafeSettingViewController alloc] init];
        [self openFullScreen:safeSettingVC];
    }
    if ([titleName isEqualToString:LanguageToolMatch(@"投诉与支持")]) {
        //投诉与支持
        NoaComplainVC *vc = [NoaComplainVC new];
        [self openFullScreen:vc];
    }
    if ([titleName isEqualToString:LanguageToolMatch(@"关于")]) {
        //关于我们
        NoaAboutUsViewController *aboutUsVC = [[NoaAboutUsViewController alloc] init];
        [self openFullScreen:aboutUsVC];
    }
    if ([titleName isEqualToString:LanguageToolMatch(@"系统设置")]) {
        //系统设置
        NoaSystemSettingViewController *sysSettingVC = [[NoaSystemSettingViewController alloc] init];
        [self openFullScreen:sysSettingVC];
    }
    if ([titleName isEqualToString:LanguageToolMatch(@"网络检测")]) {
        //网络检测
        NoaNetworkDetectionVC *vc = [NoaNetworkDetectionVC new];
        NoaSsoInfoModel *ssoModel = [NoaSsoInfoModel getSSOInfo];
        vc.currentSsoNumber = ssoModel.liceseId;
        [self openFullScreen:vc];
    }
}

#pragma mark - ZMineInfoViewDelegate
- (void)mineInfoAction:(NSInteger)actionTag {
    if (actionTag == 200) {
        //个人信息
        NoaUserInfoViewController *userInfoVC = [[NoaUserInfoViewController alloc] init];
        [self openFullScreen:userInfoVC];
    }else if (actionTag == 201){
        //系统设置
        NoaSystemSettingViewController *sysSettingVC = [[NoaSystemSettingViewController alloc] init];
        [self openFullScreen:sysSettingVC];
    }else if (actionTag == 202){
        NoaUserInfoViewController *userInfoVC = [[NoaUserInfoViewController alloc] init];
        [self openFullScreen:userInfoVC];
    }
}

#pragma mark - 先获取生成二维码的content，再本地生成二维码
- (void)getQtcondeContent {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObjectSafe:@"" forKey:@"content"];
    [dict setObjectSafe:@1 forKey:@"type"];
    [dict setObjectSafe:UserManager.userInfo.userUID forKey:@"userUid"];
    
    WeakSelf
    [HUD showActivityMessage:@""];
    [IMSDKManager UserGetCreatQrcodeContentWith:dict onSuccess:^(id _Nullable data, NSString * _Nullable traceId) {
        [HUD hideHUD];
        NoaQRCodeModel *model = [NoaQRCodeModel mj_objectWithKeyValues:data];
        NSString *content = model.content;
        //跳转到我的二维码
        NoaMyQRCodeViewController *myQrcodeVC = [[NoaMyQRCodeViewController alloc] init];
        myQrcodeVC.qrcodeContent = ![NSString isNil:content] ? content : @"" ;
        [weakSelf openFullScreen:myQrcodeVC];
    } onFailure:^(NSInteger code, NSString * _Nullable msg, NSString * _Nullable traceId) {
        [HUD hideHUD];
        [HUD showMessageWithCode:code errorMsg:msg];
    }];
}

#pragma mark - Lazy
- (NSMutableArray *)dataArr {
    if (!_dataArr) {
        _dataArr = [NSMutableArray array];
    }
    return _dataArr;
}

#pragma mark - Other
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
