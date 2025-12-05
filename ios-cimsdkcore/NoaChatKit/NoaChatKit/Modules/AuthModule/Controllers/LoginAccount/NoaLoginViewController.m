//
//  NoaLoginViewController.m
//  NoaKit
//
//  Created by Mac on 2022/8/30.
//

#import "NoaLoginViewController.h"
#import "NoaRegisterTypeViewController.h"
#import "NoaRegisterViewController.h"
#import "NoaPasswordViewController.h"
#import "NoaAlertTipView.h"
#import "ProtocolPolicyView.h"
#import "LoginTypeMenuView.h"

#import "NoaAuthInputTools.h"
#import "NoaToolManager.h"
#import "NoaNavigationController.h"
#import "AppDelegate.h"
#import "AppDelegate+DB.h"

// 登录页面
#import "NoaLoginAccountManagerView.h"
// 数据处理
#import "NoaLoginAccountDataHandle.h"
// 设备验证码验证页面
#import "NoaSafeCodeAuthViewController.h"
// 修改企业号页面
#import "NoaSsoSetViewController.h"
// 手机号选择区号页面
#import "NoaCountryCodeViewController.h"
// 验证码登录
#import "NoaVerCodeLoginViewController.h"
// 忘记密码
#import "NoaForgetPasswordViewController.h"

@interface NoaLoginViewController ()

/// 重新声明 blurView 为子类类型，覆盖父类的声明
@property (nonatomic, strong, readwrite) NoaLoginAccountManagerView *blurView;

/// 数据处理
@property (nonatomic, strong, readwrite) NoaLoginAccountDataHandle *dataHandle;

@end

@implementation NoaLoginViewController

// MARK: dealloc
- (void)dealloc {
    
}

// 显式合成 blurView 属性，确保可以访问 _blurView 实例变量
@synthesize blurView = _blurView;

// MARK: getter/setter
- (NoaLoginAccountManagerView *)blurView {
    if (!_blurView) {
        _blurView = [[NoaLoginAccountManagerView alloc] initWithFrame:CGRectZero
                                                         DataHandle:self.dataHandle];
    }
    return _blurView;
}

- (NoaLoginAccountDataHandle *)dataHandle {
    if (!_dataHandle) {
        _dataHandle = [NoaLoginAccountDataHandle new];
    }
    return _dataHandle;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // 结束编辑状态
    [self.view endEditing:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setLoginUI];
    [self processData];
}

- (void)setLoginUI {
    // 隐藏网络设置、隐藏系统语言按钮
    // 展示左上角的网络检测、系统语言，隐藏设置企业号
    [self showNetworkDetectionAndSystemLanguageButton:NO];
    [self showSsoAccountSetButton:YES];
    
    [self.view addSubview:self.topTitleLabel];
    self.topTitleLabel.numberOfLines = 2;
    self.topTitleLabel.text = LanguageToolMatch(@"您好，\n欢迎加入我们");
    [self.topTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.navView.mas_bottom).offset(24.5);
        make.leading.equalTo(@23);
        make.trailing.equalTo(self.view).offset(-23);
        make.bottom.equalTo(self.blurView.mas_top).offset(-37.5);
    }];
}

- (void)processData {
    @weakify(self)
    [self.dataHandle.jumpChangeAreaCodeSubject subscribeNext:^(id  _Nullable x) {
        @strongify(self)
        NoaCountryCodeViewController *countryCodeVC = [[NoaCountryCodeViewController alloc] init];
        [self.navigationController pushViewController:countryCodeVC animated:YES];
        [countryCodeVC setSelecgCountryCodeBlock:^(NSDictionary * _Nonnull dic) {
            @strongify(self)
            NSNumber *areaCode = [dic objectForKey:@"prefix"];
            NSString *newAreaCode = [NSString stringWithFormat:@"+%@", areaCode];
            [self.dataHandle changeAreaCode:newAreaCode];
            [self.blurView refreshShowAreaCode];
        }];
    }];
    
    [self.dataHandle.jumpRegisterSubject subscribeNext:^(id  _Nullable x) {
        @strongify(self)
        NSString *unusedAccountStr = @"";
        if (x && [x isKindOfClass:[NSString class]]) {
            unusedAccountStr = x;
        }
        NoaRegisterTypeViewController *registerTypeVC = [[NoaRegisterTypeViewController alloc] init];
        registerTypeVC.areaCode = [self.dataHandle getAreaCode];
        registerTypeVC.registerWayArr = self.dataHandle.loginTypeArr;
        registerTypeVC.unusedAccountStr = unusedAccountStr;
        registerTypeVC.unusedAccountTypeMenu = self.dataHandle.currentLoginTypeMenu;
        [self.navigationController pushViewController:registerTypeVC animated:YES];
    }];
    
    [self.dataHandle.jumpSafeCodeAuthSubject subscribeNext:^(id  _Nullable x) {
        @strongify(self)
        //登录需要安全码，跳转到安全码输入界面
        if (![x isKindOfClass:[NSString class]]) {
            return;
        }
        
        NSString *scKey = x;
        NSString *account = [self.dataHandle getAccountText];
        ZLoginAndRegisterTypeMenu loginTypeMenu = self.dataHandle.currentLoginTypeMenu;
        int loginType = [self.dataHandle covertInterfaceParamWithLoginTypeMenu:loginTypeMenu];
        
        NoaSafeCodeAuthViewController *vc = [[NoaSafeCodeAuthViewController alloc] init];
        vc.scKey = scKey;
        vc.loginInfo = account;
        vc.loginType = loginType;
        [self.navigationController pushViewController:vc animated:YES];
    }];
    
    [self.dataHandle.showToastSubject subscribeNext:^(id  _Nullable x) {
        @strongify(self)
        if (![x isKindOfClass:[NSString class]]) {
            return;
        }
        
        NSString *msg = x;
        if (![x isKindOfClass:[NSString class]]) {
            return;
        }
        
        [ZTOOL doInMain:^{
            [HUD showMessage:msg inView:self.view];
        }];
    }];
    
    
    [self.dataHandle.jumpVerCodeLoginSubject subscribeNext:^(id  _Nullable x) {
        @strongify(self)
        
        ZLoginAndRegisterTypeMenu loginTypeMenu = self.dataHandle.currentLoginTypeMenu;
        NSString *inputAccount = [self.dataHandle getAccountText];
        
        NoaVerCodeLoginViewController *verCodeLoginVC = [[NoaVerCodeLoginViewController alloc] init];
        verCodeLoginVC.currentVerCodeLoginType = loginTypeMenu;
        verCodeLoginVC.areaCode = [self.dataHandle getAreaCode];
        verCodeLoginVC.loginAccount = inputAccount;
        [self.navigationController pushViewController:verCodeLoginVC animated:YES];
    }];
    
    [self.dataHandle.jumpForgetPasswordSubject subscribeNext:^(id  _Nullable x) {
        @strongify(self)
        
        ZLoginAndRegisterTypeMenu loginTypeMenu = self.dataHandle.currentLoginTypeMenu;
        NSString *inputAccount = [self.dataHandle getAccountText];
        
        NoaForgetPasswordViewController *forgetPasswordVC = [[NoaForgetPasswordViewController alloc] init];
        forgetPasswordVC.currentResetPasswordType = loginTypeMenu;
        forgetPasswordVC.areaCode = [self.dataHandle getAreaCode];
        forgetPasswordVC.resetAccount = inputAccount;
        [self.navigationController pushViewController:forgetPasswordVC animated:YES];
    }];

}

- (void)clickSetSsoAccount {
    [[NoaToolManager shareManager] setupSsoSetVcUI];
}

@end
