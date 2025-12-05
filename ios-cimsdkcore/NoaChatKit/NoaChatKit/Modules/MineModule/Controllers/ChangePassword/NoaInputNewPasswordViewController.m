//
//  NoaInputNewPasswordViewController.m
//  NoaKit
//
//  Created by Mac on 2022/11/13.
//

#import "NoaInputNewPasswordViewController.h"
#import "NoaAuthInputTools.h"
#import "LXChatEncrypt.h"
#import "NoaInputTextView.h"

@interface NoaInputNewPasswordViewController ()

@property (nonatomic, strong)NoaInputTextView *passwordInput;
@property (nonatomic, strong)NoaInputTextView *confimPasswordInput;
@property (nonatomic, strong)UILabel *tipLbl;
@property (nonatomic, strong)UILabel *dynamicTipLbl;
@end

@implementation NoaInputNewPasswordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navTitleStr = LanguageToolMatch(@"输入新密码");
    [self setupNavBarUI];
    [self setupUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.isForcedReset) {
        self.navBtnBack.hidden = YES;
        if (self.navigationController.interactivePopGestureRecognizer) {
            self.navigationController.interactivePopGestureRecognizer.enabled = NO;
        }
    } else {
        self.navBtnBack.hidden = NO;
        if (self.navigationController.interactivePopGestureRecognizer) {
            self.navigationController.interactivePopGestureRecognizer.enabled = YES;
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.navigationController.interactivePopGestureRecognizer) {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    }
}

- (void)setupNavBarUI {
    self.navBtnRight.hidden = NO;
    [self.navBtnRight setTitle:LanguageToolMatch(@"完成") forState:UIControlStateNormal];
    [self.navBtnRight setTkThemeTitleColor:@[COLORWHITE, COLOR_CCCCCC_DARK] forState:UIControlStateNormal];
    self.navBtnRight.enabled = NO;
    self.navBtnRight.tkThemebackgroundColors = @[COLOR_CCCCCC, COLOR_EEEEEE_DARK];
    [self.navBtnRight setTkThemeBackgroundImage:@[[UIImage ImageForColor:COLOR_4069B9],[UIImage ImageForColor:COLOR_4069B9_DARK]] forState:UIControlStateSelected];
    [self.navBtnRight setTkThemeBackgroundImage:@[[UIImage ImageForColor:COLOR_4069B9],[UIImage ImageForColor:COLOR_4069B9_DARK]] forState:UIControlStateHighlighted];
    [self.navBtnRight rounded:DWScale(12)];
    [self.navBtnRight mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.navTitleLabel);
        make.trailing.equalTo(self.navView).offset(-DWScale(20));
        make.height.mas_equalTo(DWScale(32));
        CGSize textSize = [self.navBtnRight.titleLabel.text sizeWithFont:FONTR(14) constrainedToSize:CGSizeMake(10000, DWScale(32))];
        make.width.mas_equalTo(textSize.width+DWScale(28));
    }];
}

- (void)setupUI {
    //输入新密码
    UILabel *newTitleLab = [[UILabel alloc] init];
    newTitleLab.text = LanguageToolMatch(@"输入新密码");
    newTitleLab.tkThemetextColors = @[COLOR_66, COLOR_66_DARK];
    newTitleLab.font = FONTN(12);
    newTitleLab.textAlignment = NSTextAlignmentLeft;
    [self.view addSubview:newTitleLab];
    [newTitleLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(16 + DNavStatusBarH);
        make.leading.equalTo(self.view).offset(20);
        make.trailing.equalTo(self.view).offset(-20);
        make.height.mas_equalTo(DWScale(17));
    }];
    
    [self.view addSubview:self.passwordInput];
    [self.passwordInput mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(newTitleLab.mas_bottom).offset(4);
        make.leading.equalTo(self.view).offset(16);
        make.trailing.equalTo(self.view).offset(-16);
        make.height.mas_equalTo(DWScale(48));
    }];
    
    [self.view addSubview:self.dynamicTipLbl];
    [self.dynamicTipLbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.passwordInput.mas_bottom);
        make.leading.trailing.equalTo(self.passwordInput);
        make.height.mas_equalTo(0);
    }];
    
    //再次输入密码
    UILabel *confirmTitleLab = [[UILabel alloc] init];
    confirmTitleLab.text = LanguageToolMatch(@"再次输入密码");
    confirmTitleLab.tkThemetextColors = @[COLOR_66, COLOR_66_DARK];
    confirmTitleLab.font = FONTN(12);
    confirmTitleLab.textAlignment = NSTextAlignmentLeft;
    [self.view addSubview:confirmTitleLab];
    [confirmTitleLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.dynamicTipLbl.mas_bottom).offset(16);
        make.leading.equalTo(self.view).offset(20);
        make.trailing.equalTo(self.view).offset(-20);
        make.height.mas_equalTo(DWScale(17));
    }];
    
    [self.view addSubview:self.confimPasswordInput];
    [self.confimPasswordInput mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(confirmTitleLab.mas_bottom).offset(4);
        make.leading.equalTo(self.view).offset(16);
        make.trailing.equalTo(self.view).offset(-16);
        make.height.mas_equalTo(DWScale(48));
    }];
    
    [self.view addSubview:self.tipLbl];
    [self.tipLbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.confimPasswordInput.mas_bottom).offset(DWScale(20));
        make.leading.trailing.equalTo(self.confimPasswordInput);
        make.height.mas_equalTo(DWScale(20));
    }];
    
    //输入框输入内容变化回调
    @weakify(self)
    [self.passwordInput setInputStatus:^{
        @strongify(self)
        [self checkNextBtnAvailable];
    }];
    [self.confimPasswordInput setInputStatus:^{
        @strongify(self)
        [self checkNextBtnAvailable];
    }];
    
    //输入框结束输入
    self.passwordInput.textFieldEndInput = ^{
        @strongify(self)
        [self listenPasswordInput];
    };
    self.confimPasswordInput.textFieldEndInput = ^{
        @strongify(self)
        [self listenConfimPasswordInput];
    };
}

- (void)checkNextBtnAvailable {
    if ([NoaAuthInputTools checkCreatPasswordEndWithTextLength:self.passwordInput.inputText.text] &&
        [NoaAuthInputTools checkCreatPasswordEndWithTextFormat:self.passwordInput.inputText.text] &&
        [NoaAuthInputTools checkCreatPasswordEndWithTextLength:self.confimPasswordInput.inputText.text] &&
        [NoaAuthInputTools checkCreatPasswordEndWithTextFormat:self.confimPasswordInput.inputText.text]) {
        self.navBtnRight.enabled = YES;
        [self.navBtnRight setTkThemeTitleColor:@[COLORWHITE, COLORWHITE] forState:UIControlStateNormal];
        self.navBtnRight.tkThemebackgroundColors = @[COLOR_5966F2, COLOR_5966F2_DARK];
        [self.navBtnRight setTkThemeBackgroundImage:@[[UIImage ImageForColor:COLOR_4069B9],[UIImage ImageForColor:COLOR_4069B9_DARK]] forState:UIControlStateSelected];
        [self.navBtnRight setTkThemeBackgroundImage:@[[UIImage ImageForColor:COLOR_4069B9],[UIImage ImageForColor:COLOR_4069B9_DARK]] forState:UIControlStateHighlighted];
    } else {
        self.navBtnRight.enabled = NO;
        [self.navBtnRight setTkThemeTitleColor:@[COLORWHITE, COLOR_CCCCCC_DARK] forState:UIControlStateNormal];
        self.navBtnRight.tkThemebackgroundColors = @[COLOR_CCCCCC, COLOR_EEEEEE_DARK];
    }
}

//密码监听
- (void)listenPasswordInput {
    if ([NoaAuthInputTools checkCreatPasswordEndWithTextLength:self.passwordInput.inputText.text] == NO) {
        self.dynamicTipLbl.hidden = NO;
        self.dynamicTipLbl.text = LanguageToolMatch(@"密码长度6-16");
        [self.dynamicTipLbl mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.passwordInput.mas_bottom).offset(DWScale(4));
            make.height.mas_equalTo(DWScale(16));
        }];
    } else if ([NoaAuthInputTools checkCreatPasswordEndWithTextFormat:self.passwordInput.inputText.text] == NO) {
        self.dynamicTipLbl.hidden = NO;
        self.dynamicTipLbl.text = LanguageToolMatch(@"密码须包含字母、数字");
        [self.dynamicTipLbl mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.passwordInput.mas_bottom).offset(DWScale(4));
            make.height.mas_equalTo(DWScale(16));
        }];
    } else {
        self.dynamicTipLbl.hidden = YES;
        self.dynamicTipLbl.text = @"";
        [self.dynamicTipLbl mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.passwordInput.mas_bottom);
            make.height.mas_equalTo(0);
        }];
    }
}

//确认密码监听
- (void)listenConfimPasswordInput {
    if (![self.passwordInput.inputText.text isEqualToString:self.confimPasswordInput.inputText.text]) {
        [HUD showMessage:LanguageToolMatch(@"密码不一致") inView:self.view];
    }
}


#pragma mark - Action
- (void)navBtnRightClicked {
    if ( [NoaAuthInputTools checkCreatPasswordEndWithTextLength:self.passwordInput.inputText.text] == NO ||
        [NoaAuthInputTools checkCreatPasswordEndWithTextFormat:self.passwordInput.inputText.text] == NO ||
        [NoaAuthInputTools checkCreatPasswordEndWithTextLength:self.confimPasswordInput.inputText.text] == NO ||
        [NoaAuthInputTools checkCreatPasswordEndWithTextFormat:self.confimPasswordInput.inputText.text] == NO) {

        [HUD showMessage:LanguageToolMatch(@"密码长度6-16位，须包含字母、数字") inView:self.view];
        return;
    }
    if (![self.passwordInput.inputText.text isEqualToString:self.confimPasswordInput.inputText.text]) {
        [HUD showMessage:LanguageToolMatch(@"密码不一致") inView:self.view];
        return;
    }
    
    [self requestGetEncryptKeyAction];
}

#pragma mark - Request
- (void)requestGetEncryptKeyAction {    
    @weakify(self)
    [IMSDKManager authGetEncryptKeySuccess:^(id  _Nullable data, NSString * _Nullable traceId) {
        @strongify(self)
        
        //调用注册接口，传入加密密钥
        if([data isKindOfClass:[NSString class]]){
            NSString *encryptKey = (NSString *)data;
            [self requestResetPassword:encryptKey];
        }
    } onFailure:^(NSInteger code, NSString * _Nullable msg, NSString * _Nullable traceId) {
        @strongify(self)
        [HUD showMessageWithCode:code errorMsg:msg inView:self.view];
    }];
}

- (void)requestResetPassword:(NSString *)encryptKey {
    //AES对称加密后的密码
    NSString *passwordKey = [NSString stringWithFormat:@"%@%@", encryptKey, self.passwordInput.inputText.text];
    NSString *userPwStr = [LXChatEncrypt method4:passwordKey];
    //调用校验密码接口
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObjectSafe:userPwStr forKey:@"password"];
    [params setObjectSafe:encryptKey forKey:@"encryptKey"];
    [params setObjectSafe:UserManager.userInfo.userUID forKey:@"userUid"];
    
    [IMSDKManager userResetPasswordWith:params onSuccess:^(id _Nullable data, NSString * _Nullable traceId) {
        BOOL resetResult = [data boolValue];
        if (resetResult) {
            [HUD showMessage:LanguageToolMatch(@"修改密码成功") inView:self.view];
            [ZTOOL setupLoginUI];
        } else {
            [HUD showMessage:LanguageToolMatch(@"修改密码失败") inView:self.view];
        }
    } onFailure:^(NSInteger code, NSString * _Nullable msg, NSString * _Nullable traceId) {
        [HUD showMessageWithCode:code errorMsg:msg inView:self.view];
    }];
}

#pragma mark - Lazy
- (NoaInputTextView *)passwordInput {
    if (!_passwordInput) {
        _passwordInput = [[NoaInputTextView alloc] init];
        _passwordInput.clipsToBounds = YES;
        _passwordInput.isPassword = YES;
        _passwordInput.isShowBoard = NO;
        _passwordInput.placeholderText = LanguageToolMatch(@"输入6-16位密码");
        _passwordInput.bgViewBackColor = @[COLOR_F5F6F9, COLOR_F5F6F9_DARK];
        _passwordInput.inputText.keyboardType = UIKeyboardTypeASCIICapable;
      
        if (@available(iOS 12.0, *)) {
            _passwordInput.inputText.textContentType = UITextContentTypeOneTimeCode;
        } else {
            // Fallback on earlier versions
        }
        _passwordInput.inputType = ZMessageInputViewTypePassword;
        _passwordInput.tipsImgName = @"";
    }
    return _passwordInput;
}

- (NoaInputTextView *)confimPasswordInput {
    if (!_confimPasswordInput) {
        _confimPasswordInput = [[NoaInputTextView alloc] init];
        _confimPasswordInput.isPassword = YES;
        _confimPasswordInput.isShowBoard = NO;
        _confimPasswordInput.placeholderText = LanguageToolMatch(@"再次输入密码");
        _confimPasswordInput.bgViewBackColor = @[COLOR_F5F6F9, COLOR_F5F6F9_DARK];
        _confimPasswordInput.inputText.keyboardType = UIKeyboardTypeASCIICapable;
        if (@available(iOS 12.0, *)) {
            _confimPasswordInput.inputText.textContentType = UITextContentTypeOneTimeCode;
        } else {
            // Fallback on earlier versions
        }
        _confimPasswordInput.inputType = ZMessageInputViewTypePassword;
        _confimPasswordInput.tipsImgName = @"";
    }
    return _confimPasswordInput;
}

- (UILabel *)tipLbl {
    if (!_tipLbl) {
        _tipLbl = [[UILabel alloc] init];
        if (ZHostTool.appSysSetModel.checkEnglishSymbol) {
            _tipLbl.text = LanguageToolMatch(@"密码至少6个字符，同时包含字母、数字、符号");
        } else {
            _tipLbl.text = LanguageToolMatch(@"密码至少6个字符，不能全是字母或数字");
        }
        _tipLbl.tkThemetextColors = @[COLOR_11, COLOR_11_DARK];
        _tipLbl.font = FONTN(14);
        _tipLbl.textAlignment = NSTextAlignmentLeft;
    }
    return _tipLbl;
}

- (UILabel *)dynamicTipLbl {
    if (!_dynamicTipLbl) {
        _dynamicTipLbl = [[UILabel alloc] init];
        _dynamicTipLbl.text = @"";
        _dynamicTipLbl.tkThemetextColors = @[COLOR_FF3333, COLOR_FF3333_DARK];
        _dynamicTipLbl.font = FONTN(12);
        _dynamicTipLbl.textAlignment = NSTextAlignmentLeft;
        _dynamicTipLbl.hidden = YES;
    }
    return _dynamicTipLbl;
}
@end
