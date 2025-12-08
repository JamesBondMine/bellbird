//
//  NoaRegisterView.m
//  NoaChatKit
//
//  Created by phl on 2025/11/12.
//

#import "NoaRegisterView.h"
// 数据处理
#import "NoaRegisterDataHandle.h"
// 页签切换
#import "JXCategoryTitleView.h"
#import "JXCategoryIndicatorLineView.h"
// 服务协议与隐私政策
#import "ProtocolPolicyView.h"
// 提示弹窗
#import "NoaAlertTipView.h"
// 手机号码输入
#import "NoaRegisterPhoneNumberInputView.h"
// 邮箱号码输入
#import "NoaRegisterEMailInputView.h"
// 账号注册
#import "NoaRegisterAccountInputView.h"
// 保证加密key唯一性
#import "NoaEncryptKeyGuard.h"

@interface NoaRegisterView ()<JXCategoryViewDelegate>

@property (nonatomic, strong) NoaRegisterDataHandle *dataHandle;

/// 顶部切换
@property (nonatomic, strong) JXCategoryTitleView *registerTypeCategoryView;

/// 滚动视图
@property (nonatomic, strong) UIScrollView *scrollView;

/// 账号输入
@property (nonatomic, strong) NoaRegisterAccountInputView *accountInputView;

/// 邮箱输入
@property (nonatomic, strong) NoaRegisterEMailInputView *eMailInputView;

/// 手机号码输入
@property (nonatomic, strong) NoaRegisterPhoneNumberInputView *phoneNumberInputView;

/// 当前激活的输入视图（用于统一管理约束）
@property (nonatomic, weak) NoaRegisterBaseInputView *currentRegisterView;

/// 密码格式提醒
@property (nonatomic, strong) UILabel *passwordFormatTipLabel;

/// 注册并登录
@property (nonatomic, strong) UIButton *signUpBtn;

// 服务协议与隐私政策
@property (nonatomic, strong) ProtocolPolicyView *policyView;

/// 已有账号，去登录
@property (nonatomic, strong) UIButton *hadAccountAndLoginBtn;

/// 版本管理
@property (nonatomic, strong) UILabel *versionLabel;

@end

@implementation NoaRegisterView

#pragma mark - Lazy Loading
- (JXCategoryTitleView *)registerTypeCategoryView {
    if (!_registerTypeCategoryView) {
        _registerTypeCategoryView = [JXCategoryTitleView new];
        _registerTypeCategoryView.delegate = self;
        _registerTypeCategoryView.titles = self.dataHandle.titleArr;
        _registerTypeCategoryView.titleColor = COLOR_00;
        _registerTypeCategoryView.titleSelectedColor = COLOR_5966F2;
        // 设置 title 字体大小（影响 title 高度）
        _registerTypeCategoryView.titleFont = FONTSB(16);
        _registerTypeCategoryView.titleSelectedFont = FONTM(16);
        // 设置 title 垂直偏移量（正值向下，负值向上）
        // _ssoTypeCategoryView.titleLabelVerticalOffset = 0;
        _registerTypeCategoryView.titleColorGradientEnabled = YES;
        _registerTypeCategoryView.averageCellSpacingEnabled = NO;
        _registerTypeCategoryView.contentEdgeInsetLeft = 12;
        _registerTypeCategoryView.contentEdgeInsetRight = 12;
        _registerTypeCategoryView.cellSpacing = 24;
        // 默认第一个
        _registerTypeCategoryView.defaultSelectedIndex = 0;
        JXCategoryIndicatorLineView *lineView = [[JXCategoryIndicatorLineView alloc] init];
        // 设置指示器固定宽度
        lineView.indicatorWidth = 36;
        lineView.indicatorCornerRadius = 2;
        lineView.indicatorHeight = 3;
        lineView.indicatorColor = COLOR_5966F2;
        // 设置指示器位置（底部）
        lineView.componentPosition = JXCategoryComponentPosition_Bottom;
        _registerTypeCategoryView.indicators = @[lineView];
    }
    return _registerTypeCategoryView;
}

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
    }
    return _scrollView;
}

- (NoaRegisterAccountInputView *)accountInputView {
    if (!_accountInputView) {
        _accountInputView = [[NoaRegisterAccountInputView alloc] initWithFrame:CGRectZero
                                                          CurrentRegisterWay:ZLoginTypeMenuAccountPassword];
        _accountInputView.isSupportInviteCode = [self.dataHandle getInviteCodeSupportState];
    }
    return _accountInputView;
}

- (NoaRegisterPhoneNumberInputView *)phoneNumberInputView {
    if (!_phoneNumberInputView) {
        _phoneNumberInputView = [[NoaRegisterPhoneNumberInputView alloc] initWithFrame:CGRectZero
                                                                  CurrentRegisterWay:ZLoginTypeMenuPhoneNumber];
        _phoneNumberInputView.isSupportInviteCode = [self.dataHandle getInviteCodeSupportState];
        // 先展示默认areaCode
        [_phoneNumberInputView refreshAreaCode:[self.dataHandle getAreaCode]];
        
        @weakify(self)
        _phoneNumberInputView.clickChangeAreaCodeBtnAction = ^{
            @strongify(self)
            [self.dataHandle.jumpChangeAreaCodeSubject sendNext:@0];
        };
        
        // 获取验证码
        _phoneNumberInputView.getVerCodeActionBlock = ^{
            @strongify(self)
            [HUD showActivityMessage:@"" inView:self];
            [self.dataHandle.checkUserIsExistCommand execute:nil];
        };
    }
    return _phoneNumberInputView;
}

- (NoaRegisterEMailInputView *)eMailInputView {
    if (!_eMailInputView) {
        _eMailInputView = [[NoaRegisterEMailInputView alloc] initWithFrame:CGRectZero
                                                      CurrentRegisterWay:ZLoginTypeMenuEmail];
        _eMailInputView.isSupportInviteCode = [self.dataHandle getInviteCodeSupportState];
        // 获取验证码
        @weakify(self)
        _eMailInputView.getVerCodeActionBlock = ^{
            @strongify(self)
            [HUD showActivityMessage:@"" inView:self];
            [self.dataHandle.checkUserIsExistCommand execute:nil];
        };
    }
    return _eMailInputView;
}

- (UILabel *)passwordFormatTipLabel {
    if (!_passwordFormatTipLabel) {
        _passwordFormatTipLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        if (ZHostTool.appSysSetModel.checkEnglishSymbol) {
            _passwordFormatTipLabel.text = LanguageToolMatch(@"密码至少6个字符，同时包含字母、数字、符号");
        } else {
            _passwordFormatTipLabel.text = LanguageToolMatch(@"密码至少6个字符，不能全是字母或数字");
        }
        _passwordFormatTipLabel.tkThemetextColors = @[COLOR_11, COLOR_99];
        _passwordFormatTipLabel.font = FONTR(14);
        _passwordFormatTipLabel.numberOfLines = 0;
        _passwordFormatTipLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _passwordFormatTipLabel;
}

- (UIButton *)signUpBtn {
    if (!_signUpBtn) {
        _signUpBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_signUpBtn setTitle:LanguageToolMatch(@"注册并登录") forState:UIControlStateNormal];
        [_signUpBtn setTkThemeTitleColor:@[COLORWHITE, COLORWHITE] forState:UIControlStateNormal];
        _signUpBtn.titleLabel.font = FONTM(14);
        _signUpBtn.tkThemebackgroundColors = @[COLOR_5966F2, COLOR_5966F2_DARK];
        _signUpBtn.layer.cornerRadius = 16;
        _signUpBtn.layer.masksToBounds = YES;
    }
    return _signUpBtn;
}

- (ProtocolPolicyView *)policyView {
    if (!_policyView) {
        _policyView = [[ProtocolPolicyView alloc] initWithFrame:CGRectZero];
    }
    return _policyView;
}

- (UIButton *)hadAccountAndLoginBtn {
    if (!_hadAccountAndLoginBtn) {
        _hadAccountAndLoginBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    }
    return _hadAccountAndLoginBtn;
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
                   DataHandle:(NoaRegisterDataHandle *)dataHandle {
    self = [super initWithFrame:frame IsPopWindows:NO];
    if (self) {
        self.dataHandle = dataHandle;
        [self setUpUI];
        [self processData];
    }
    return self;
}


- (void)setUpUI {
    [self addSubview:self.registerTypeCategoryView];
    [self.registerTypeCategoryView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(@20);
        make.top.equalTo(@30);
        make.height.equalTo(@36);
        make.trailing.equalTo(self).offset(-20);
    }];
    
    [self addSubview:self.scrollView];
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.registerTypeCategoryView.mas_bottom).offset(16);
        make.leading.equalTo(self);
        make.trailing.equalTo(self);
        make.bottom.equalTo(self);
    }];
    
    // 根据登录类型设置当前激活的输入视图和显示/隐藏状态
    [self updateCurrentInputView];
    
    [self.scrollView addSubview:self.passwordFormatTipLabel];
    [self.passwordFormatTipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.currentRegisterView.mas_bottom).offset(12);
        make.leading.equalTo(self.scrollView).offset(32);
        make.trailing.equalTo(self.scrollView).offset(-32);
        make.height.greaterThanOrEqualTo(@12);
    }];
    
    [self.scrollView addSubview:self.signUpBtn];
    [self.signUpBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.passwordFormatTipLabel.mas_bottom).offset(48);
        make.leading.equalTo(self.scrollView).offset(20);
        make.trailing.equalTo(self.scrollView).offset(-20);
        make.height.equalTo(@54);
    }];
    
    //服务协议 隐私政策
    [self.scrollView addSubview:self.policyView];
    [self.policyView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.signUpBtn.mas_bottom).offset(12);
        make.leading.equalTo(self.scrollView).offset(40);
        make.trailing.equalTo(self.scrollView).offset(-35);
    }];
    
    // 去注册→
    [self.scrollView addSubview:self.hadAccountAndLoginBtn];
    [self.hadAccountAndLoginBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.policyView.mas_bottom).offset(12);
        make.centerX.equalTo(self.scrollView);
        make.width.equalTo(@335);
        make.height.equalTo(@48);
    }];
    
    // 版本
    [self.scrollView addSubview:self.versionLabel];
    [self.versionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.hadAccountAndLoginBtn.mas_bottom).offset(90);
        make.centerX.equalTo(self.scrollView);
        make.width.greaterThanOrEqualTo(@121);
        make.height.equalTo(@14);
        make.bottom.equalTo(self.scrollView).offset(-DHomeBarH);
    }];
    
    if (![NSString isNil:self.dataHandle.unRegisterAccount]) {
        // 上个页面传入的未使用账号，需要回显
        switch (self.dataHandle.currentLoginTypeMenu) {
            case ZLoginTypeMenuAccountPassword:
                if (self.accountInputView) {
                    [self.accountInputView showPrepareAccount:self.dataHandle.unRegisterAccount];
                }
                break;
            case ZLoginTypeMenuPhoneNumber:
                if (self.phoneNumberInputView) {
                    [self.phoneNumberInputView showPreparePhoneNumber:self.dataHandle.unRegisterAccount];
                }
                break;
            case ZLoginTypeMenuEmail:
                if (self.eMailInputView) {
                    [self.eMailInputView showPrepareEmail:self.dataHandle.unRegisterAccount];
                }
                break;
            default:
                break;
        }
        [self.currentRegisterView triggerValidation];
    }
}

- (void)processData {
    @weakify(self)
    // 暗黑模式切换
    self.registerTypeCategoryView.tkThemeChangeBlock = ^(id  _Nullable itself, NSUInteger themeIndex) {
        @strongify(self)
        if (themeIndex == 0) {
            self.registerTypeCategoryView.titleColor = COLOR_00;
            self.registerTypeCategoryView.titleSelectedColor = COLOR_5966F2;
        }else {
            self.registerTypeCategoryView.titleColor = COLOR_00_DARK;
            self.registerTypeCategoryView.titleSelectedColor = COLOR_5966F2_DARK;
        }
        // 不刷新颜色不生效
        [self.registerTypeCategoryView reloadDataWithoutListContainer];
    };
    
    self.hadAccountAndLoginBtn.tkThemeChangeBlock = ^(id  _Nullable itself, NSUInteger themeIndex) {
        @strongify(self)
        // 设置富文本
        NSString *actionText = LanguageToolMatch(@"去登录");
        NSString *template = LanguageToolMatch(@"已有账号？%@");
        NSString *fullText = [NSString stringWithFormat:template, actionText];
        
        BOOL isDarkMode = (themeIndex != 0);
        UIColor *fullColor = isDarkMode ? COLOR_99_DARK : COLOR_99;
        UIColor *actionColor = isDarkMode ? COLOR_5966F2_DARK : COLOR_5966F2;
        
        NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:fullText];
        [attrStr addAttribute:NSForegroundColorAttributeName
                        value:fullColor
                        range:NSMakeRange(0, fullText.length)];
        [attrStr addAttribute:NSForegroundColorAttributeName
                        value:actionColor
                        range:[fullText rangeOfString:actionText]];
        [attrStr addAttribute:NSFontAttributeName
                        value:FONTM(14)
                        range:NSMakeRange(0, attrStr.length)];
        [self.hadAccountAndLoginBtn setAttributedTitle:attrStr forState:UIControlStateNormal];
    };
    
    // 注册按钮点击事件
    [[self.hadAccountAndLoginBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        @strongify(self)
        // 已有账号？跳转到登录页面
        [self.dataHandle.popLoginVCSubject sendNext:@1];
    }];
    
    // 注册并登录按钮点击事件
    [[self.signUpBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        @strongify(self)
        // 停止编辑
        [self endEditing:YES];
        
        // 检查相关参数合规性
        BOOL paramIsAvaliable = [self.dataHandle checkParamIsAvaliable];
        if (!paramIsAvaliable) {
            // 参数异常
            return;
        }
        
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
                [self clickRegisterAndLoginBtnAction];
            };
            return;
        }
        
        [self clickRegisterAndLoginBtnAction];
    }];
    
    // 设置获取输入框文字的回调 block
    self.dataHandle.getInputTextBlock = ^NSDictionary<NSString *,NSString *> *(ZLoginAndRegisterTypeMenu loginType) {
        @strongify(self)
        NSMutableDictionary *textDict = [NSMutableDictionary dictionary];
        
        switch (loginType) {
            case ZLoginTypeMenuAccountPassword: {
                textDict[kLoginModuleParamAccountKey] = [self.accountInputView getAccountText];
                textDict[kLoginModuleParamPasswordKey] = [self.accountInputView getPasswordText];
                textDict[kLoginModuleParamConfirmPasswordKey] = [self.accountInputView getConfirmPasswordText];
                textDict[kLoginModuleParamVerCodeKey] = [self.accountInputView getCodeText];
                textDict[kLoginModuleParamInviteCodeKey] = [self.accountInputView getInviteText];
                break;
            }
            case ZLoginTypeMenuPhoneNumber: {
                textDict[kLoginModuleParamPhoneNumberKey] = [self.phoneNumberInputView getPhoneNumberText];
                textDict[kLoginModuleParamPasswordKey] = [self.phoneNumberInputView getPasswordText];
                textDict[kLoginModuleParamConfirmPasswordKey] = [self.phoneNumberInputView getConfirmPasswordText];
                textDict[kLoginModuleParamVerCodeKey] = [self.phoneNumberInputView getCodeText];
                textDict[kLoginModuleParamInviteCodeKey] = [self.phoneNumberInputView getInviteText];
                break;
            }
            case ZLoginTypeMenuEmail: {
                textDict[kLoginModuleParamEmailKey] = [self.eMailInputView getEmailText];
                textDict[kLoginModuleParamPasswordKey] = [self.eMailInputView getPasswordText];
                textDict[kLoginModuleParamConfirmPasswordKey] = [self.eMailInputView getConfirmPasswordText];
                textDict[kLoginModuleParamVerCodeKey] = [self.eMailInputView getCodeText];
                textDict[kLoginModuleParamInviteCodeKey] = [self.eMailInputView getInviteText];
                break;
            }
            default:
                break;
        }
        
        return textDict;
    };
    
    // 获取注册获取密钥事件回调
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
            
            NSInteger code = [[errorDic objectForKey:@"code"] integerValue];
            NSString *msg = [errorDic objectForKey:@"msg"];
            [self.dataHandle.showToastSubject sendNext:LanguageToolCodeMatch(code, msg)];
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
        
        [self.dataHandle.registerAndLoginCommand execute:encryptKey];
    }];
    
    // 注册协议事件回调
    [self.dataHandle.registerAndLoginCommand.executionSignals.switchToLatest subscribeNext:^(id  _Nullable x) {
        //        @strongify(self)
        // 这里可以处理其他逻辑，如果需要的话
        BOOL res = [x boolValue];
        if (res) {
            CIMLog(@"注册成功");
        }else {
            CIMLog(@"注册失败");
        }
    }];
    
    // 注册检测用户是否存在
    [self.dataHandle.checkUserIsExistCommand.executionSignals.switchToLatest subscribeNext:^(id  _Nullable x) {
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
            [self.dataHandle.showToastSubject sendNext:LanguageToolCodeMatch(code, msg)];
            [ZTOOL sentryUploadWithString:LanguageToolCodeMatch(code, msg) sentryUploadType:ZSentryUploadTypeHttp errorCode:[NSString stringWithFormat:@"%ld",(long)code]];
            return;
        }
        
        // 检查当前账号是否已经注册
        BOOL isExist = [[resDic objectForKey:@"data"] boolValue];
        if (isExist) {
            [HUD hideHUD];
            //账号已注册过，不可使用该账号
            switch (self.dataHandle.currentLoginTypeMenu) {
                case ZLoginTypeMenuPhoneNumber:
                    [self.dataHandle.showToastSubject sendNext:LanguageToolMatch(@"手机号已注册，请登录")];
                    break;
                case ZLoginTypeMenuEmail:
                    [self.dataHandle.showToastSubject sendNext:LanguageToolMatch(@"邮箱已注册，请登录")];
                    break;
                case ZLoginTypeMenuAccountPassword:
                    [self.dataHandle.showToastSubject sendNext:LanguageToolMatch(@"账号已存在，请登录")];
                    break;
                    
                default:
                    break;
            }
            return;
        }
        
        // 判断依据:手机、邮箱通过验证码判断用户是否存在；账号注册因为不支持验证码，故直接认为是调用注册
        if (self.dataHandle.currentLoginTypeMenu != ZLoginTypeMenuAccountPassword) {
            // 未注册过，且是获取验证码时，现请求图文验证码
            if (self.dataHandle.currentLoginTypeMenu == ZLoginTypeMenuPhoneNumber) {
                // 设置验证方式
                [self.dataHandle resetSDKCaptchaChannel];
                // 手机号码注册
                switch (ZHostTool.appSysSetModel.captchaChannel) {
                    case 1: {
                        // 关闭验证码验证，直接发送验证码请求
                        NSDictionary *paramDic = [self.dataHandle getVerCodeParamWithImgCode:@""
                                                                                      Ticket:@""
                                                                                     Randstr:@""
                                                                          CaptchaVerifyParam:@""];
                        [self.dataHandle.getVerCommand execute:paramDic];
                    }
                        break;
                    case 2:
                        // 开启图文验证码
                        [self.dataHandle.getImgVerCommand execute:nil];
                        break;
                    case 3:
                        // 开启腾讯无痕验证码
                        [self.dataHandle.getTencentCaptchaCommand execute:nil];
                        break;
                    case 4:
                        // 开启阿里无痕验证码
                        [self.dataHandle.getAliCaptchaCommand execute:@YES];
                        break;
                    default:
                        break;
                }
            }else if (self.dataHandle.currentLoginTypeMenu == ZLoginTypeMenuEmail) {
                // 邮箱号码注册，直接发送验证码请求
                NSDictionary *paramDic = [self.dataHandle getVerCodeParamWithImgCode:@""
                                                                              Ticket:@""
                                                                             Randstr:@""
                                                                  CaptchaVerifyParam:@""];
                [self.dataHandle.getVerCommand execute:paramDic];
            }else {
                // 未知逻辑
                [HUD hideHUD];
            }
            
            return;
        }
        
        // 未注册，是账号密码注册类型时，调用获取密钥方法，进行注册
        [self.dataHandle.getEncryptKeyCommand execute:nil];
    }];
    
    // 点击获取验证码的时候，获取图文验证码给弹窗用
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
            
            NSInteger code = [[errorDic objectForKey:@"code"] integerValue];
            NSString *msg = [errorDic objectForKey:@"msg"];
            [self.dataHandle.showToastSubject sendNext:LanguageToolCodeMatch(code, msg)];
            return;
        }
        
        // 成功
        NSString *codeStr = [resDic objectForKey:@"code"];
        if (codeStr.length == 0) {
            // 如果为空，会在弹窗继续获取
            codeStr = @"";
        }
        
        [self.dataHandle showImgVerCodePopWindowWithCode:codeStr];
    }];
    
    // 获取验证码倒计时
    [self.dataHandle.startVerCodeCountDownSubject subscribeNext:^(id  _Nullable x) {
        @strongify(self)
        
        if (!self.currentRegisterView) {
            return;
        }
        
        // 通知UI页面开始倒计时
        [self.currentRegisterView startVerCodeCountDown];
    }];
    
    // 发送获取验证码结果回调
    [self.dataHandle.getVerCommand.executionSignals.switchToLatest subscribeNext:^(id  _Nullable x) {
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
            
            NSInteger code = [[errorDic objectForKey:@"code"] integerValue];
            if (code == Auth_User_Capcha_Error_Code) {
                [self.dataHandle.getAliCaptchaCommand execute:nil];
                return;
            }else if (code == Auth_User_Capcha_TimeOut_Code ||
                      code == Auth_User_Capcha_ChangeImgVer_Code) {
                [self.dataHandle showImgVerCodePopWindowWithCode:@""];
            }
            
            NSString *msg = [errorDic objectForKey:@"msg"];
            [self.dataHandle.showToastSubject sendNext:LanguageToolCodeMatch(code, msg)];
            [ZTOOL sentryUploadWithString:LanguageToolCodeMatch(code, msg) sentryUploadType:ZSentryUploadTypeHttp errorCode:[NSString stringWithFormat:@"%ld",(long)code]];
            return;
        }
        
        [self.dataHandle.showToastSubject sendNext:LanguageToolMatch(@"验证码已发送")];
        [self.dataHandle resetSDKCaptchaChannel];
        
        // 开启页面倒计时
        [self.dataHandle.startVerCodeCountDownSubject sendNext:nil];
    }];
    
    // 腾讯无痕验证码
    [self.dataHandle.getTencentCaptchaCommand.executionSignals.switchToLatest subscribeNext:^(id  _Nullable x) {
        @strongify(self)
       
        if (![x isKindOfClass:[NSDictionary class]]) {
            return;
        }
        
        NSDictionary *resDic = x;
        BOOL isSuccess = [[resDic objectForKey:@"res"] boolValue];
        if (!isSuccess) {
            // 展示图文验证码
            [self.dataHandle showImgVerCodePopWindowWithCode:@""];
            return;
        }
        
        // 成功
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
        
        [ZTOOL doInMain:^{
            [HUD showActivityMessage:@"" inView:self];
        }];
        
        NSDictionary *paramDic = [self.dataHandle getVerCodeParamWithImgCode:@""
                                                                      Ticket:ticket
                                                                     Randstr:randstr
                                                          CaptchaVerifyParam:@""];
        [self.dataHandle.getVerCommand execute:paramDic];
    }];
    
    // 阿里无痕验证码
    [self.dataHandle.getAliCaptchaCommand.executionSignals.switchToLatest subscribeNext:^(id  _Nullable x) {
        @strongify(self)
        
        if (![x isKindOfClass:[NSDictionary class]]) {
            return;
        }
        
        NSDictionary *resDic = x;
        BOOL isSuccess = [[resDic objectForKey:@"res"] boolValue];
        if (!isSuccess) {
            // 展示图文验证码
            [self.dataHandle showImgVerCodePopWindowWithCode:@""];
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
        
        [ZTOOL doInMain:^{
            [HUD showActivityMessage:@"" inView:self];
        }];
        
        NSDictionary *paramDic = [self.dataHandle getVerCodeParamWithImgCode:@""
                                                                      Ticket:@""
                                                                     Randstr:@""
                                                          CaptchaVerifyParam:captchaVerifyParam];
        [self.dataHandle.getVerCommand execute:paramDic];
    }];
    
    // 订阅账号密码输入验证结果，绑定到登录按钮的 enabled 属性
    [self setupLoginButtonEnableBinding];
}

- (void)clickRegisterAndLoginBtnAction {
    [HUD showActivityMessage:@"" inView:self];
    
    if (self.dataHandle.currentLoginTypeMenu == ZLoginTypeMenuAccountPassword) {
        [self.dataHandle.checkUserIsExistCommand execute:nil];
        return;
    }
    [self.dataHandle.getEncryptKeyCommand execute:nil];
}

/// 设置登录按钮的启用状态绑定
- (void)setupLoginButtonEnableBinding {
    @weakify(self)
    
    // 根据当前登录类型获取对应的验证信号
    ZLoginAndRegisterTypeMenu loginType = self.dataHandle.currentLoginTypeMenu;
    RACSubject<NSNumber *> *targetSignal = nil;
    
    if (loginType == ZLoginTypeMenuAccountPassword) {
        targetSignal = self.accountInputView.accountValidationResultSignal;
    } else if (loginType == ZLoginTypeMenuPhoneNumber) {
        targetSignal = self.phoneNumberInputView.phoneNumberValidationResultSignal;
    } else if (loginType == ZLoginTypeMenuEmail) {
        targetSignal = self.eMailInputView.emailValidationResultSignal;
    } else {
        // 未知类型
    }
    
    // 如果找到对应的信号，使用 replay 确保总是有最后一个值，然后用 startWith 确保有初始值
    RACSignal<NSNumber *> *validationSignal = nil;
    if (targetSignal) {
        // 使用 replay 确保信号总是有最后一个值（如果之前发送过）
        // 使用 startWith 确保立即有一个初始值（如果之前没有发送过）
        // 使用 distinctUntilChanged 避免重复发送相同的值
        validationSignal = [[[targetSignal replay] startWith:@NO] distinctUntilChanged];
    } else {
        validationSignal = [RACSignal return:@NO];
    }
    
    // 订阅并更新按钮状态
    [validationSignal subscribeNext:^(NSNumber *shouldEnable) {
        @strongify(self)
        BOOL isEnable = shouldEnable.boolValue;
        self.signUpBtn.enabled = isEnable;
        self.signUpBtn.alpha = isEnable ? 1.0 : 0.7;
    }];
}

/// 更新当前激活的输入视图（根据 loginTypeMenu）
- (void)updateCurrentInputView {
    NoaRegisterBaseInputView *newInputView = nil;
    // 设置所有输入视图的约束（上、左右相同，高度不一定相同-高度由组件内部自适应撑开）
    if (self.dataHandle.currentLoginTypeMenu == ZLoginTypeMenuAccountPassword) {
        newInputView = self.accountInputView;
        
        if (!self.accountInputView.superview) {
            [self.scrollView addSubview:self.accountInputView];
            [self.accountInputView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.scrollView);
                make.leading.equalTo(self.scrollView);
                make.trailing.equalTo(self.scrollView);
                make.width.equalTo(self.scrollView);
            }];
        }
    } else if (self.dataHandle.currentLoginTypeMenu == ZLoginTypeMenuPhoneNumber) {
        newInputView = self.phoneNumberInputView;
        
        if (!self.phoneNumberInputView.superview) {
            [self.scrollView addSubview:self.phoneNumberInputView];
            [self.phoneNumberInputView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.scrollView);
                make.leading.equalTo(self.scrollView);
                make.trailing.equalTo(self.scrollView);
                make.width.equalTo(self.scrollView);
            }];
        }
    } else if (self.dataHandle.currentLoginTypeMenu == ZLoginTypeMenuEmail) {
        newInputView = self.eMailInputView;
        
        if (!self.eMailInputView.superview) {
            [self.scrollView addSubview:self.eMailInputView];
            [self.eMailInputView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.scrollView);
                make.leading.equalTo(self.scrollView);
                make.trailing.equalTo(self.scrollView);
                make.width.equalTo(self.scrollView);
            }];
        }
    }
    
    if (!newInputView || newInputView == self.currentRegisterView) {
        return;
    }
    // 更新当前激活的输入视图
    self.currentRegisterView = newInputView;
}

- (void)refreshShowAreaCode {
    if (!self.phoneNumberInputView) {
        return;
    }
    
    [self.phoneNumberInputView refreshAreaCode:[self.dataHandle getAreaCode]];
}

/// MARK: JXCategoryViewDelegate Methods
- (void)categoryView:(JXCategoryBaseView *)categoryView didSelectedItemAtIndex:(NSInteger)index {
    // 只有一个，不用处理
}

/// 触发验证状态更新（用于切换登录类型时立即更新按钮状态）
- (void)triggerValidationUpdate {
    // 根据当前登录类型，调用对应输入视图的 triggerValidation 方法
    // 这样可以确保切换登录类型时，即使没有编辑过输入框，按钮状态也会立即更新
    switch (self.dataHandle.currentLoginTypeMenu) {
        case ZLoginTypeMenuAccountPassword: {
            // 手动触发账号密码验证
            [self.accountInputView triggerValidation];
            break;
        }
        case ZLoginTypeMenuPhoneNumber: {
            // 手动触发手机号验证
            [self.phoneNumberInputView triggerValidation];
            break;
        }
        case ZLoginTypeMenuEmail: {
            // 手动触发邮箱验证
            [self.eMailInputView triggerValidation];
            break;
        }
        default:
            break;
    }
}

// 点击页面，取消编辑，收起键盘
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self endEditing:YES];
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect {
 // Drawing code
 }
 */

@end
