//
//  NoaLoginAccountManagerView.m
//  NoaChatKit
//
//  Created by phl on 2025/11/6.
//

#import "NoaLoginAccountManagerView.h"
// 上方切换页签
#import "JXCategoryTitleView.h"
#import "JXCategoryIndicatorLineView.h"
// 账号输入
#import "NoaLoginAccountInputView.h"
// 手机号码输入
#import "NoaLoginPhoneNumberInputView.h"
// 邮箱号码输入
#import "NoaLoginEMailInputView.h"
// 服务协议与隐私政策
#import "ProtocolPolicyView.h"
// 数据处理
#import "NoaLoginAccountDataHandle.h"
// 保证加密key唯一性
#import "NoaEncryptKeyGuard.h"
// 加密
#import "LXChatEncrypt.h"
// 提示弹窗
#import "NoaAlertTipView.h"

@interface NoaLoginAccountManagerView ()<JXCategoryViewDelegate, UITextFieldDelegate>

/// 切换页签
@property (nonatomic, strong) JXCategoryTitleView *loginTypeCategoryView;

/// 解决小屏显示不下
@property (nonatomic, strong) UIScrollView *scrollView;

/// 账号输入
@property (nonatomic, strong) NoaLoginAccountInputView *loginAccountInputView;

/// 手机号码输入
@property (nonatomic, strong) NoaLoginPhoneNumberInputView *loginPhoneNumberInputView;

/// 邮箱号码输入
@property (nonatomic, strong) NoaLoginEMailInputView *loginEmailInputView;

/// 当前激活的输入视图（用于统一管理约束）
@property (nonatomic, weak) UIView *currentInputView;

/// 验证码登录
@property (nonatomic, strong) UIButton *verificationCodeBtn;

/// 忘记密码
@property (nonatomic, strong) UIButton *forgetPasswordBtn;

/// 登录
@property (nonatomic, strong) UIButton *loginBtn;

// 服务协议与隐私政策
@property (nonatomic, strong) ProtocolPolicyView *policyView;

/// 注册
@property (nonatomic, strong) UIButton *registerBtn;

/// 版本管理
@property (nonatomic, strong) UILabel *versionLabel;

/// 数据处理
@property (nonatomic, strong) NoaLoginAccountDataHandle *dataHandle;

@end

@implementation NoaLoginAccountManagerView

#pragma mark - Lazy Loading

- (JXCategoryTitleView *)loginTypeCategoryView {
    if (!_loginTypeCategoryView) {
        _loginTypeCategoryView = [JXCategoryTitleView new];
        _loginTypeCategoryView.delegate = self;
        _loginTypeCategoryView.titles = self.dataHandle.titleArr;
        _loginTypeCategoryView.titleColor = COLOR_00;
        _loginTypeCategoryView.titleSelectedColor = COLOR_5966F2;
        // 设置 title 字体大小（影响 title 高度）
        _loginTypeCategoryView.titleFont = FONTSB(16);
        _loginTypeCategoryView.titleSelectedFont = FONTM(16);
        _loginTypeCategoryView.titleColorGradientEnabled = YES;
        _loginTypeCategoryView.averageCellSpacingEnabled = NO;
        _loginTypeCategoryView.contentEdgeInsetLeft = 12;
        _loginTypeCategoryView.contentEdgeInsetRight = 12;
        _loginTypeCategoryView.cellSpacing = 24;
        // 默认第一个
        _loginTypeCategoryView.defaultSelectedIndex = 0;
        JXCategoryIndicatorLineView *lineView = [[JXCategoryIndicatorLineView alloc] init];
        // 设置指示器固定宽度
        lineView.indicatorWidth = 36;
        lineView.indicatorCornerRadius = 2;
        lineView.indicatorHeight = 3;
        lineView.indicatorColor = COLOR_5966F2;
        // 设置指示器位置（底部）
        lineView.componentPosition = JXCategoryComponentPosition_Bottom;
        _loginTypeCategoryView.indicators = @[lineView];
    }
    return _loginTypeCategoryView;
}

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
    }
    return _scrollView;
}

- (NoaLoginAccountInputView *)loginAccountInputView {
    if (!_loginAccountInputView) {
        _loginAccountInputView = [[NoaLoginAccountInputView alloc] initWithFrame:CGRectZero];
        _loginAccountInputView.isNeedShowImageCode = [self.dataHandle getImageCodeStateWithLoginState:ZLoginTypeMenuAccountPassword];
        @weakify(self)
        _loginAccountInputView.clickRefreshVerificationCodeBtnAction = ^{
            @strongify(self)
            CIMLog(@"点击刷新账号登录图文验证码");
            [self.dataHandle setImageCodeViewShow:YES
                                        loginType:ZLoginTypeMenuAccountPassword];
        };
    }
    return _loginAccountInputView;
}

- (NoaLoginPhoneNumberInputView *)loginPhoneNumberInputView {
    if (!_loginPhoneNumberInputView) {
        _loginPhoneNumberInputView = [[NoaLoginPhoneNumberInputView alloc] initWithFrame:CGRectZero];
        // 先展示默认areaCode
        [_loginPhoneNumberInputView refreshAreaCode:[self.dataHandle getAreaCode]];
        _loginPhoneNumberInputView.isNeedShowImageCode = [self.dataHandle getImageCodeStateWithLoginState:ZLoginTypeMenuPhoneNumber];
        
        @weakify(self)
        _loginPhoneNumberInputView.clickRefreshVerificationCodeBtnAction = ^{
            @strongify(self)
            CIMLog(@"点击刷新手机号登录图文验证码");
            [self.dataHandle setImageCodeViewShow:YES
                                        loginType:ZLoginTypeMenuPhoneNumber];
        };
        
        _loginPhoneNumberInputView.clickChangeAreaCodeBtnAction = ^{
            @strongify(self)
            [self.dataHandle.jumpChangeAreaCodeSubject sendNext:@0];
        };
    }
    return _loginPhoneNumberInputView;
}

- (NoaLoginEMailInputView *)loginEmailInputView {
    if (!_loginEmailInputView) {
        _loginEmailInputView = [[NoaLoginEMailInputView alloc] initWithFrame:CGRectZero];
        _loginEmailInputView.isNeedShowImageCode = [self.dataHandle getImageCodeStateWithLoginState:ZLoginTypeMenuEmail];
        @weakify(self)
        _loginEmailInputView.clickRefreshVerificationCodeBtnAction = ^{
            @strongify(self)
            CIMLog(@"点击刷新邮箱登录图文验证码");
            [self.dataHandle setImageCodeViewShow:YES
                                        loginType:ZLoginTypeMenuEmail];
        };
    }
    return _loginEmailInputView;
}

- (UIButton *)verificationCodeBtn {
    if (!_verificationCodeBtn) {
        _verificationCodeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_verificationCodeBtn setTitle:LanguageToolMatch(@"验证码登录") forState:UIControlStateNormal];
        [_verificationCodeBtn setTkThemeTitleColor:@[COLOR_99, COLOR_99_DARK] forState:UIControlStateNormal];
        _verificationCodeBtn.titleLabel.font = FONTR(14);
        _verificationCodeBtn.tkThemebackgroundColors = @[UIColor.clearColor, UIColor.clearColor];
        _verificationCodeBtn.titleEdgeInsets = UIEdgeInsetsMake(16, 0, 16, 0);
    }
    return _verificationCodeBtn;
}

- (UIButton *)forgetPasswordBtn {
    if (!_forgetPasswordBtn) {
        _forgetPasswordBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_forgetPasswordBtn setTitle:LanguageToolMatch(@"忘记密码") forState:UIControlStateNormal];
        [_forgetPasswordBtn setTkThemeTitleColor:@[COLOR_99, COLOR_99_DARK] forState:UIControlStateNormal];
        _forgetPasswordBtn.titleLabel.font = FONTR(14);
        _forgetPasswordBtn.tkThemebackgroundColors = @[UIColor.clearColor, UIColor.clearColor];
        _forgetPasswordBtn.titleEdgeInsets = UIEdgeInsetsMake(16, 0, 16, 0);
    }
    return _forgetPasswordBtn;
}

- (UIButton *)loginBtn {
    if (!_loginBtn) {
        _loginBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_loginBtn setTitle:LanguageToolMatch(@"登录") forState:UIControlStateNormal];
        [_loginBtn setTkThemeTitleColor:@[COLORWHITE, COLORWHITE] forState:UIControlStateNormal];
        _loginBtn.titleLabel.font = FONTM(14);
        _loginBtn.tkThemebackgroundColors = @[COLOR_5966F2, COLOR_5966F2_DARK];
        _loginBtn.layer.cornerRadius = 16;
        _loginBtn.layer.masksToBounds = YES;
    }
    return _loginBtn;
}

- (ProtocolPolicyView *)policyView {
    if (!_policyView) {
        _policyView = [[ProtocolPolicyView alloc] initWithFrame:CGRectZero];
    }
    return _policyView;
}

- (UIButton *)registerBtn {
    if (!_registerBtn) {
        _registerBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_registerBtn setTitle:LanguageToolMatch(@"去注册") forState:UIControlStateNormal];
        [_registerBtn setTkThemeTitleColor:@[COLOR_5966F2, COLOR_5966F2_DARK] forState:UIControlStateNormal];
        _registerBtn.titleLabel.font = FONTM(16);
        [_registerBtn setImage:ImgNamed(@"icon_right_arrow") forState:UIControlStateNormal];
        [_registerBtn setBtnImageAlignmentType:ButtonImageAlignmentTypeRight imageSpace:2];
    }
    return _registerBtn;
}

- (UILabel *)versionLabel {
    if (!_versionLabel) {
        _versionLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _versionLabel.text = [NSString stringWithFormat:@"V%@ %@", [ZTOOL getCurretnVersion], [ZTOOL getBuildVersion]];
        _versionLabel.tkThemetextColors = @[COLOR_99, COLOR_99_DARK];
        _versionLabel.font = FONTM(14);
    }
    return _versionLabel;
}

- (instancetype)initWithFrame:(CGRect)frame
                   DataHandle:(NoaLoginAccountDataHandle *)manager {
    self = [super initWithFrame:frame IsPopWindows:NO];
    if (self) {
        self.dataHandle = manager;
        
        [self setupView];
        [self processData];
    }
    return self;
}

- (void)setupView {
    [self addSubview:self.loginTypeCategoryView];
    [self.loginTypeCategoryView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(@20);
        make.top.equalTo(@30);
        make.height.equalTo(@36);
        make.width.equalTo(@200);
    }];
    
    [self addSubview:self.scrollView];
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.loginTypeCategoryView.mas_bottom).offset(16);
        make.leading.equalTo(self);
        make.trailing.equalTo(self);
        make.bottom.equalTo(self);
    }];
    
    // 将所有输入视图都添加到 scrollView
    [self.scrollView addSubview:self.loginAccountInputView];
    [self.scrollView addSubview:self.loginPhoneNumberInputView];
    [self.scrollView addSubview:self.loginEmailInputView];
    
    // 设置所有输入视图的约束（上、左右相同，高度不一定相同-高度由组件内部自适应撑开）
    [self.loginAccountInputView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.scrollView);
        make.leading.equalTo(self.scrollView);
        make.trailing.equalTo(self.scrollView);
        make.width.equalTo(self.scrollView);
    }];
    
    [self.loginPhoneNumberInputView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.scrollView);
        make.leading.equalTo(self.scrollView);
        make.trailing.equalTo(self.scrollView);
        make.width.equalTo(self.scrollView);
    }];
    
    [self.loginEmailInputView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.scrollView);
        make.leading.equalTo(self.scrollView);
        make.trailing.equalTo(self.scrollView);
        make.width.equalTo(self.scrollView);
    }];
    
    // 根据登录类型设置当前激活的输入视图和显示/隐藏状态
    [self updateCurrentInputView];

    //服务协议 隐私政策
    [self.scrollView addSubview:self.policyView];
    [self.policyView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.loginBtn.mas_bottom).offset(12);
        make.leading.equalTo(self.scrollView).offset(40);
        make.trailing.equalTo(self.scrollView).offset(-35);
    }];
    
    // 去注册→
    [self.scrollView addSubview:self.registerBtn];
    [self.registerBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.policyView.mas_bottom).offset(48);
        make.centerX.equalTo(self.scrollView);
        make.width.equalTo(@127);
        make.height.equalTo(@41);
    }];
    
    // 版本
    [self.scrollView addSubview:self.versionLabel];
    [self.versionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.registerBtn.mas_bottom).offset(48);
        make.centerX.equalTo(self.scrollView);
        make.width.greaterThanOrEqualTo(@121);
        make.height.equalTo(@14);
        make.bottom.equalTo(self.scrollView).offset(-DHomeBarH);
    }];
}

- (void)processData {
    @weakify(self)
    // 暗黑模式切换
    self.loginTypeCategoryView.tkThemeChangeBlock = ^(id  _Nullable itself, NSUInteger themeIndex) {
        @strongify(self)
        if (themeIndex == 0) {
            self.loginTypeCategoryView.titleColor = COLOR_00;
            self.loginTypeCategoryView.titleSelectedColor = COLOR_5966F2;
        }else {
            self.loginTypeCategoryView.titleColor = COLOR_00_DARK;
            self.loginTypeCategoryView.titleSelectedColor = COLOR_5966F2_DARK;
        }
        // 不刷新颜色不生效
        [self.loginTypeCategoryView reloadDataWithoutListContainer];
    };
    
    // 注册按钮点击事件
    [[self.registerBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        @strongify(self)
        [self.dataHandle.jumpRegisterSubject sendNext:nil];
    }];
    
    // 登录按钮点击事件
    [[self.loginBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        @strongify(self)
        // 停止编辑
        [self endEditing:YES];
        // 是否勾选 服务协议 和 隐私政策
        if (!self.policyView.checkBoxBtn.selected) {
            //富文本
            NSString *serveText = LanguageToolMatch(@"《服务协议》");
            NSString *privateText = LanguageToolMatch(@"《隐私政策》");
            NSString *contentText = [NSString stringWithFormat:LanguageToolMatch(@"请阅读并同意%@和%@"), serveText, privateText];
            NSMutableAttributedString *attText = [[NSMutableAttributedString alloc] initWithString:contentText];
            [attText addAttribute:NSForegroundColorAttributeName value:COLOR_5966F2 range:[contentText rangeOfString:serveText]];
            [attText addAttribute:NSForegroundColorAttributeName value:COLOR_5966F2 range:[contentText rangeOfString:privateText]];
            
            // 保存需要使用的字符串，避免在异步回调中访问可能已释放的对象
            NSString *agreeText = LanguageToolMatch(@"请阅读并同意");
            NSString *andText = LanguageToolMatch(@"和");
            
            attText.tkThemeChangeBlock = ^(id  _Nullable itself, NSUInteger themeIndex) {
                UIColor *color = nil;
                if (themeIndex == 0) {
                    color = COLOR_11;
                } else {
                    color = COLOR_11_DARK;
                }
                NSRange range = [contentText rangeOfString:agreeText];
                if (range.location != NSNotFound) {
                    [(NSMutableAttributedString *)itself addAttribute:NSForegroundColorAttributeName value:color range:range];
                }
            };
            attText.tkThemeChangeBlock = ^(id  _Nullable itself, NSUInteger themeIndex) {
                UIColor *color = nil;
                if (themeIndex == 0) {
                    color = COLOR_11;
                } else {
                    color = COLOR_11_DARK;
                }
                NSRange range = [contentText rangeOfString:andText];
                if (range.location != NSNotFound) {
                    [(NSMutableAttributedString *)itself addAttribute:NSForegroundColorAttributeName value:color range:range];
                }
            };
            //弹窗
            NoaAlertTipView *alertView = [NoaAlertTipView new];
            alertView.lblTitle.text = LanguageToolMatch(@"提示");
            alertView.lblContent.text = @"";
            alertView.lblContent.attributedText = attText;
            [alertView.btnSure setTitle:LanguageToolMatch(@"同意并继续") forState:UIControlStateNormal];
            [alertView alertTipViewSHow];
            
            @weakify(self)
            alertView.sureBtnBlock = ^{
                @strongify(self)
                self.policyView.checkBoxBtn.selected = YES;
                [self clickLoginBtnAction];
            };
            return;
        }
        
        [self clickLoginBtnAction];
    }];
    
    // 设置获取输入框文字的回调 block
    self.dataHandle.getInputTextBlock = ^NSDictionary<NSString *,NSString *> *(ZLoginAndRegisterTypeMenu loginType) {
        @strongify(self)
        NSMutableDictionary *textDict = [NSMutableDictionary new];
        
        switch (loginType) {
            case ZLoginTypeMenuAccountPassword: {
                textDict[kLoginModuleParamAccountKey] = [self.loginAccountInputView getAccountText];
                textDict[kLoginModuleParamPasswordKey] = [self.loginAccountInputView getPasswordText];
                textDict[kLoginModuleParamImgCodeKey] = [self.loginAccountInputView getCodeText];
                break;
            }
            case ZLoginTypeMenuPhoneNumber: {
                textDict[kLoginModuleParamPhoneNumberKey] = [self.loginPhoneNumberInputView getPhoneNumberText];
                textDict[kLoginModuleParamPasswordKey] = [self.loginPhoneNumberInputView getPasswordText];
                textDict[kLoginModuleParamImgCodeKey] = [self.loginPhoneNumberInputView getCodeText];
                break;
            }
            case ZLoginTypeMenuEmail: {
                textDict[kLoginModuleParamEmailKey] = [self.loginEmailInputView getEmailText];
                textDict[kLoginModuleParamPasswordKey] = [self.loginEmailInputView getPasswordText];
                textDict[kLoginModuleParamImgCodeKey] = [self.loginEmailInputView getCodeText];
                break;
            }
            default:
                break;
        }
        
        return textDict;
    };
    
    // 获取登录密钥事件回调
    [self.dataHandle.getEncryptKeyCommand.executionSignals.switchToLatest subscribeNext:^(id  _Nullable x) {
        @strongify(self)
        if (![x isKindOfClass:[NSDictionary class]]) {
            [HUD hideHUD];
            return;
        }
        
        NSDictionary *resDic = x;
        BOOL isSuccess = [[resDic objectForKey:@"res"] boolValue];
        if (!isSuccess) {
            [HUD hideHUD];
            NSDictionary *errorDic = [resDic objectForKey:@"error"];
            if (!errorDic) {
                return;
            }
            
            NSInteger errorCode = [[errorDic objectForKey:@"code"] integerValue];
            NSString *errorMsg = [errorDic objectForKey:@"msg"];
            [self.dataHandle.showToastSubject sendNext:LanguageToolCodeMatch(errorCode, errorMsg)];
            return;
        }
        
        // 成功
        NSString *dataStr = [resDic objectForKey:@"data"];
        if (dataStr.length == 0) {
            [HUD hideHUD];
            return;
        }
        
        NoaEncryptKeyGuard *guard = [NoaEncryptKeyGuard guardWithKey:dataStr];
        NSString *encryptKey = [guard consume];
        if ([NSString isNil:encryptKey]) {
            [HUD hideHUD];
            return;
        }
        
        // 获取密码
        NSString *password = [self.dataHandle getPasswordText];
        //AES对称加密后的密码
        NSString *passwordKey = [NSString stringWithFormat:@"%@%@", encryptKey, password];
        NSString *passwordEncryptKey = [LXChatEncrypt method4:passwordKey];
        if ([NSString isNil:passwordEncryptKey]) {
            [HUD hideHUD];
            [HUD showMessage:[NSString stringWithFormat:@"%@～", LanguageToolMatch(@"操作失败")] inView:self];
            return;
        }
        
        NSMutableDictionary *loginParam = nil;
        if (!self.dataHandle.tempParamWhenGetEncrypt) {
            // 提前填充接口需要的参数
            loginParam = [NSMutableDictionary dictionaryWithDictionary:@{
                @"encryptKey": encryptKey,
                @"userPw": passwordEncryptKey,
                @"ticket": @"",
                @"randstr": @"",
                @"captchaVerifyParam": @"",
                @"code": @""
            }];
        }else {
            loginParam = [NSMutableDictionary new];
            [loginParam addEntriesFromDictionary:self.dataHandle.tempParamWhenGetEncrypt];
            [loginParam setValue:encryptKey forKey:@"encryptKey"];
            [loginParam setValue:passwordEncryptKey forKey:@"userPw"];
        }
        
        self.dataHandle.tempParamWhenGetEncrypt = nil;
        [self.dataHandle.loginAccountCommand execute:loginParam];
       
    }];
    
    [self.dataHandle.checkUserIsExistAndHadPasswordCommand.executionSignals.switchToLatest subscribeNext:^(id  _Nullable x) {
        @strongify(self)
        if (![x isKindOfClass:[NSDictionary class]]) {
            [HUD hideHUD];
            return;
        }
        
        NSDictionary *resDic = x;
        BOOL isSuccess = [[resDic objectForKey:@"res"] boolValue];
        if (!isSuccess) {
            [HUD hideHUD];
            NSDictionary *errorDic = [resDic objectForKey:@"error"];
            if (!errorDic) {
                return;
            }
            
            NSInteger code = [[errorDic objectForKey:@"code"] integerValue];
            NSString *msg = [errorDic objectForKey:@"msg"];
            if (code == 2036 ||
                code == 40019 ||
                code == 50000 ||
                code == 50001) {
                // 模糊化提示用户不存在： 2036-账号不存在、40019-密码不正确、50000-邮箱不存在、50001-手机号不存在
                [self.dataHandle.showToastSubject sendNext:[NSString stringWithFormat:LanguageToolMatch(@"账号或密码错误，请重新输入，错误码：%d"), code]];
            }else {
                // 根据错误码提示
                [self.dataHandle.showToastSubject sendNext:LanguageToolCodeMatch(code, msg)];
            }
            [ZTOOL sentryUploadWithString:LanguageToolCodeMatch(code, msg) sentryUploadType:ZSentryUploadTypeHttp errorCode:[NSString stringWithFormat:@"%ld", (long)code]];
            return;
        }
        
        // 检查当前账号是否已经注册
        NSDictionary *dataDic = [resDic objectForKey:@"data"];
        // 用户是否存在
        BOOL userExist = [[dataDic objectForKey:@"userExist"] boolValue];
        /**
         // 是否设置了密码--暂时没用
         BOOL passwordExist = [[dataDic objectForKey:@"passwordExist"] boolValue];
         */
        if (!userExist) {
            // 隐藏loading
            [HUD hideHUD];
            // 用户不存在，Toast提示
            [self.dataHandle.showToastSubject sendNext:[NSString stringWithFormat:LanguageToolMatch(@"账号或密码错误，请重新输入，错误码：%d"), 2036]];
            return;
        }
        
        // 创建中转数据
        NSMutableDictionary *loginParam = [NSMutableDictionary dictionaryWithDictionary:@{
            @"ticket": @"",
            @"randstr": @"",
            @"captchaVerifyParam": @"",
            @"code": @""
        }];
        self.dataHandle.tempParamWhenGetEncrypt = loginParam;
        [self.dataHandle.getEncryptKeyCommand execute:nil];
    }];
    
    // 阿里无痕验证事件回调
    [self.dataHandle.getAliCaptchaCommand.executionSignals.switchToLatest subscribeNext:^(id  _Nullable x) {
        @strongify(self)
        if (![x isKindOfClass:[NSDictionary class]]) {
            return;
        }
        
        NSDictionary *resDic = x;
        BOOL isSuccess = [[resDic objectForKey:@"res"] boolValue];
        if (!isSuccess) {
            // 失败，展示图文验证码
            [self.dataHandle setImageCodeViewShow:YES
                                        loginType:self.dataHandle.currentLoginTypeMenu];
            return;
        }
        
        
        NSDictionary *captchaDataDic = [resDic objectForKey:@"captchaData"];
        if (!captchaDataDic || captchaDataDic.count == 0) {
            // 异常
            return;
        }
        
        NSString *captchaVerifyParam = [captchaDataDic objectForKey:@"captchaVerifyParam"];
       
        if ([NSString isNil:captchaVerifyParam]) {
            // 异常
            captchaVerifyParam = @"";
        }

        // 创建中转数据
        NSMutableDictionary *loginParam = [NSMutableDictionary dictionaryWithDictionary:@{
            @"ticket": @"",
            @"randstr": @"",
            @"captchaVerifyParam": captchaVerifyParam,
            @"code": @""
        }];
        self.dataHandle.tempParamWhenGetEncrypt = loginParam;
        
        [HUD showActivityMessage:@"" inView:self];
        [self.dataHandle.getEncryptKeyCommand execute:nil];
    }];
    
    // 腾讯无痕验证事件回调
    [self.dataHandle.getTencentCaptchaCommand.executionSignals.switchToLatest subscribeNext:^(id  _Nullable x) {
        @strongify(self)
        if (![x isKindOfClass:[NSDictionary class]]) {
            return;
        }
        
        NSDictionary *resDic = x;
        BOOL isSuccess = [[resDic objectForKey:@"res"] boolValue];
        if (!isSuccess) {
            // 失败，展示图文验证码
            [self.dataHandle setImageCodeViewShow:YES
                                        loginType:self.dataHandle.currentLoginTypeMenu];
            return;
        }
        
        
        NSDictionary *captchaDataDic = [resDic objectForKey:@"captchaData"];
        if (!captchaDataDic || captchaDataDic.count == 0) {
            // 异常
            return;
        }
        
        NSString *ticket = [captchaDataDic objectForKey:@"ticket"];
        NSString *randstr = [captchaDataDic objectForKey:@"randstr"];
        
        if ([NSString isNil:ticket]) {
            // 异常
            ticket = @"";
        }

        if ([NSString isNil:randstr]) {
            // 异常
            randstr = @"";
        }
        
        // 创建中转数据
        NSMutableDictionary *loginParam = [NSMutableDictionary dictionaryWithDictionary:@{
            @"ticket": ticket,
            @"randstr": randstr,
            @"captchaVerifyParam": @"",
            @"code": @""
        }];
        self.dataHandle.tempParamWhenGetEncrypt = loginParam;
        
        [HUD showActivityMessage:@"" inView:self];
        [self.dataHandle.getEncryptKeyCommand execute:nil];
       
    }];
    
    // 登录协议事件回调
    [self.dataHandle.loginAccountCommand.executionSignals.switchToLatest subscribeNext:^(id  _Nullable x) {
//        @strongify(self)
        // 这里可以处理其他逻辑，如果需要的话
        BOOL res = [x boolValue];
        if (res) {
            CIMLog(@"登陆成功");
        }else {
            CIMLog(@"登陆失败");
        }
    }];
    
    [self.dataHandle.changeImageCodeShowStatusSubject subscribeNext:^(id  _Nullable x) {
        @strongify(self)
        if (![x isKindOfClass:[NSNumber class]]) {
            return;
        }
        ZLoginAndRegisterTypeMenu loginTypeMenu = [x intValue];
        BOOL currentShowStatus = [self.dataHandle getImageCodeStateWithLoginState:loginTypeMenu];
        if (!currentShowStatus) {
            // 通知对应登录页面隐藏验证码，更新布局
            switch (loginTypeMenu) {
                case ZLoginTypeMenuPhoneNumber:
                    self.loginPhoneNumberInputView.isNeedShowImageCode = currentShowStatus;
                    break;
                case ZLoginTypeMenuEmail:
                    self.loginEmailInputView.isNeedShowImageCode = currentShowStatus;
                    break;
                case ZLoginTypeMenuAccountPassword:
                    self.loginAccountInputView.isNeedShowImageCode = currentShowStatus;
                    break;
                default:
                    break;
            }
        } else {
            // 需要展示，去获取图文验证码
            [HUD showActivityMessage:@"" inView:self];
            [self.dataHandle.getImgVerCommand execute:nil];
        }
    }];
    
    [self.dataHandle.getImgVerCommand.executionSignals.switchToLatest subscribeNext:^(id  _Nullable x) {
        @strongify(self)
        
        [ZTOOL doInMain:^{
            [HUD hideHUD];
        }];
        
        if (![x isKindOfClass:[NSDictionary class]]) {
            return;
        }
        
        NSDictionary *resDic = x;
        BOOL isSuccess = [[resDic objectForKey:@"res"] boolValue];
        if (!isSuccess) {
            NSDictionary *errorDic = [resDic objectForKey:@"error"];
            if (!errorDic) {
                return;
            }
            
            NSInteger errorCode = [[errorDic objectForKey:@"code"] integerValue];
            NSString *errorMsg = [errorDic objectForKey:@"msg"];
            [self.dataHandle.showToastSubject sendNext:LanguageToolCodeMatch(errorCode, errorMsg)];
            return;
        }
        
        // 成功
        NSString *codeStr = [resDic objectForKey:@"code"];
        if (codeStr.length == 0) {
            return;
        }
        
        ZLoginAndRegisterTypeMenu loginTypeMenu = self.dataHandle.currentLoginTypeMenu;
        // 将对应的登录UI刷新，并展示图文验证码
        switch (loginTypeMenu) {
            case ZLoginTypeMenuPhoneNumber:
                self.loginPhoneNumberInputView.isNeedShowImageCode = YES;
                self.loginPhoneNumberInputView.imageCodeText = codeStr;
                break;
            case ZLoginTypeMenuEmail:
                self.loginEmailInputView.isNeedShowImageCode = YES;
                self.loginEmailInputView.imageCodeText = codeStr;
                break;
            case ZLoginTypeMenuAccountPassword:
                self.loginAccountInputView.isNeedShowImageCode = YES;
                self.loginAccountInputView.imageCodeText = codeStr;
                break;
            default:
                break;
        }
    }];
    
    [[self.verificationCodeBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
       @strongify(self)
        [self.dataHandle.jumpVerCodeLoginSubject sendNext:nil];
    }];
    
    [[self.forgetPasswordBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
       @strongify(self)
        [self.dataHandle.jumpForgetPasswordSubject sendNext:nil];
    }];
    
    // 订阅账号密码输入验证结果，绑定到登录按钮的 enabled 属性
    [self setupLoginButtonEnableBinding];
}

- (void)clickLoginBtnAction {
    BOOL isAvaliable = [self.dataHandle checkLoginAccountInfoAvaliableWhenClickLoginBtn];
    if (!isAvaliable) {
        // 参数校验未通过
        return;
    }

    [HUD showActivityMessage:@"" inView:self];
    [self.dataHandle.checkUserIsExistAndHadPasswordCommand execute:nil];
}

/// 设置登录按钮的启用状态绑定
- (void)setupLoginButtonEnableBinding {
    @weakify(self)
    
    // 创建一个信号，当 loginTypeMenu 改变时发送当前值
    // 使用 distinctUntilChanged 避免重复发送相同的值
    RACSignal<NSNumber *> *loginTypeSignal = [[RACObserve(self.dataHandle, currentLoginTypeMenu) distinctUntilChanged] map:^NSNumber *(NSNumber *value) {
        return value;
    }];
    
    // 根据登录类型选择对应的验证信号
    // 使用 map 将登录类型映射为对应的验证信号，然后使用 switchToLatest 切换订阅
    RACSignal<RACSignal<NSNumber *> *> *validationSignalOfSignals = [loginTypeSignal map:^RACSignal<NSNumber *> *(NSNumber *loginTypeValue) {
        @strongify(self)
        ZLoginAndRegisterTypeMenu loginType = [loginTypeValue integerValue];
        
        // 根据登录类型返回对应的验证信号
        RACSubject<NSNumber *> *targetSignal = nil;
        if (loginType == ZLoginTypeMenuAccountPassword) {
            targetSignal = self.loginAccountInputView.accountValidationResultSignal;
        } else if (loginType == ZLoginTypeMenuPhoneNumber) {
            targetSignal = self.loginPhoneNumberInputView.phoneNumberValidationResultSignal;
        } else if (loginType == ZLoginTypeMenuEmail) {
            targetSignal = self.loginEmailInputView.emailValidationResultSignal;
        } else {
            // 未知类型
        }
        
        // 如果找到对应的信号，使用 replay 确保总是有最后一个值，然后用 startWith 确保有初始值
        if (targetSignal) {
            // 使用 replay 确保信号总是有最后一个值（如果之前发送过）
            // 使用 startWith 确保切换时立即有一个初始值（如果之前没有发送过）
            // 使用 distinctUntilChanged 避免重复发送相同的值
            // 注意：replay 会缓存最后一个值，新订阅者会立即收到这个值
            RACSignal<NSNumber *> *replayedSignal = [[targetSignal replay] startWith:@NO];
            return [replayedSignal distinctUntilChanged];
        } else {
            return [RACSignal return:@NO];
        }
    }];
    
    // 使用 switchToLatest 来切换信号，确保只订阅当前登录类型对应的验证信号
    // 当登录类型改变时，会自动取消订阅旧的信号，订阅新的信号
    RACSignal<NSNumber *> *currentValidationSignal = [validationSignalOfSignals switchToLatest];
    
    // 合并验证结果信号和登录类型信号
    // 注意：使用 startWith 确保信号有初始值
    RACSignal<NSNumber *> *enableSignal = [[RACSignal combineLatest:@[
        currentValidationSignal,
        [loginTypeSignal startWith:@(self.dataHandle.currentLoginTypeMenu)]
    ]] map:^NSNumber *(RACTuple *tuple) {
        NSNumber *isValid = tuple.first;
        // 根据验证结果决定是否启用登录按钮
        BOOL shouldEnable = isValid.boolValue;
        return @(shouldEnable);
    }];
    
    // 订阅并更新按钮状态
    [enableSignal subscribeNext:^(NSNumber *shouldEnable) {
        @strongify(self)
        BOOL isEnable = shouldEnable.boolValue;
        self.loginBtn.enabled = isEnable;
        self.loginBtn.alpha = isEnable ? 1.0 : 0.7;
    }];
}

/// 更新当前激活的输入视图（根据 loginTypeMenu）
- (void)updateCurrentInputView {
    UIView *newInputView = nil;
    
    BOOL isSupportVerificationCode = NO;
    BOOL isSupportForgetPassword = NO;
    
    ZLoginAndRegisterTypeMenu currentLoginTypeMenu = self.dataHandle.currentLoginTypeMenu;
    if (currentLoginTypeMenu == ZLoginTypeMenuAccountPassword) {
        self.loginAccountInputView.hidden = NO;
        self.loginPhoneNumberInputView.hidden = YES;
        self.loginEmailInputView.hidden = YES;
        newInputView = self.loginAccountInputView;
        
        isSupportForgetPassword = NO;
        isSupportVerificationCode = NO;
    } else if (currentLoginTypeMenu == ZLoginTypeMenuPhoneNumber) {
        self.loginPhoneNumberInputView.hidden = NO;
        self.loginAccountInputView.hidden = YES;
        self.loginEmailInputView.hidden = YES;
        newInputView = self.loginPhoneNumberInputView;
        
        isSupportForgetPassword = YES;
        isSupportVerificationCode = YES;
    } else if (currentLoginTypeMenu == ZLoginTypeMenuEmail) {
        self.loginEmailInputView.hidden = NO;
        self.loginAccountInputView.hidden = YES;
        self.loginPhoneNumberInputView.hidden = YES;
        newInputView = self.loginEmailInputView;
        
        isSupportForgetPassword = YES;
        isSupportVerificationCode = YES;
    }
    
    if (!newInputView || newInputView == self.currentInputView) {
        return;
    }
    // 更新当前激活的输入视图
    self.currentInputView = newInputView;
    
    self.verificationCodeBtn.hidden = !isSupportVerificationCode;
    self.forgetPasswordBtn.hidden = !isSupportForgetPassword;
    
    if (!self.loginBtn.superview) {
        [self.scrollView addSubview:self.loginBtn];
    }
    
    if (isSupportVerificationCode || isSupportForgetPassword) {
        if (!self.verificationCodeBtn.superview) {
            [self.scrollView addSubview:self.verificationCodeBtn];
        }
        
        if (!self.forgetPasswordBtn.superview) {
            [self.scrollView addSubview:self.forgetPasswordBtn];
        }
        
        CGFloat verificationCodeTextWidth = [self calculateButtonWidthForText:self.verificationCodeBtn.titleLabel.text font:self.verificationCodeBtn.titleLabel.font];
        // 设计图最低106，然后+32是因为文字距离左右边距各16
        CGFloat verificationCodeBtnWidth = MAX(102, verificationCodeTextWidth);
        [self.verificationCodeBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(@4);
            make.top.equalTo(self.currentInputView.mas_bottom);
            make.width.equalTo(@(verificationCodeBtnWidth));
            make.height.equalTo(@46);
        }];
        
        CGFloat forgetPasswordTextWidth = [self calculateButtonWidthForText:self.forgetPasswordBtn.titleLabel.text font:self.forgetPasswordBtn.titleLabel.font];
        // 设计图最低106，然后+32是因为文字距离左右边距各16
        CGFloat forgetPasswordBtnWidth = MAX(102, forgetPasswordTextWidth);
        [self.forgetPasswordBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(self.scrollView).offset(-4);
            make.top.equalTo(self.currentInputView.mas_bottom);
            make.width.equalTo(@(forgetPasswordBtnWidth));
            make.height.equalTo(@46);
        }];
        
        // 更新登录按钮的约束，使其依赖于新的输入视图
        [self.loginBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
            // 32是因为verificationCodeBtn文字距离下边距16
            make.top.equalTo(self.verificationCodeBtn.mas_bottom).offset(32);
            make.leading.equalTo(self.scrollView).offset(20);
            make.trailing.equalTo(self.scrollView).offset(-20);
            make.height.equalTo(@54);
        }];
    }else {
        // 更新登录按钮的约束，使其依赖于新的输入视图
        [self.loginBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.currentInputView.mas_bottom).offset(48);
            make.leading.equalTo(self.scrollView).offset(20);
            make.trailing.equalTo(self.scrollView).offset(-20);
            make.height.equalTo(@54);
        }];
    }
}

- (void)refreshShowAreaCode {
    if (!self.loginPhoneNumberInputView) {
        return;
    }
    
    [self.loginPhoneNumberInputView refreshAreaCode:[self.dataHandle getAreaCode]];
}

- (void)reloadSupportLoginType {
    self.loginTypeCategoryView.titles = self.dataHandle.titleArr;
    [self.loginTypeCategoryView reloadDataWithoutListContainer];
    // 默认选中第一个
    [self.loginTypeCategoryView selectItemAtIndex:0];
}

/// MARK: JXCategoryViewDelegate Methods
- (void)categoryView:(JXCategoryBaseView *)categoryView didSelectedItemAtIndex:(NSInteger)index {
    self.dataHandle.currentLoginTypeMenu = [self.dataHandle getLoginTypeWithIndex:index];
    
    if (self.dataHandle.currentLoginTypeMenu == ZLoginTypeMenuPhoneNumber) {
        [self.loginPhoneNumberInputView refreshAreaCode:[self.dataHandle getAreaCode]];        
    }
    
    // 统一更新输入视图的显示/隐藏和约束
    [self updateCurrentInputView];
    
    // 切换登录类型后，立即触发一次验证状态更新
    // 这样即使没有编辑过输入框，按钮状态也会立即更新
    [self triggerValidationUpdate];
}

/// 触发验证状态更新（用于切换登录类型时立即更新按钮状态）
- (void)triggerValidationUpdate {
    // 根据当前登录类型，调用对应输入视图的 triggerValidation 方法
    // 这样可以确保切换登录类型时，即使没有编辑过输入框，按钮状态也会立即更新
    switch (self.dataHandle.currentLoginTypeMenu) {
        case ZLoginTypeMenuAccountPassword: {
            // 手动触发账号密码验证
            [self.loginAccountInputView triggerValidation];
            break;
        }
        case ZLoginTypeMenuPhoneNumber: {
            // 手动触发手机号验证
            [self.loginPhoneNumberInputView triggerValidation];
            break;
        }
        case ZLoginTypeMenuEmail: {
            // 手动触发邮箱验证
            [self.loginEmailInputView triggerValidation];
            break;
        }
        default:
            break;
    }
}



/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
