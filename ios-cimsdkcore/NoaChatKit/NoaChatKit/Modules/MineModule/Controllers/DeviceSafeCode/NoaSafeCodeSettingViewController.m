//
//  NoaSafeCodeSettingViewController.m
//  NoaKit
//
//  Created by mac on 2025/1/2.
//

#import "NoaSafeCodeSettingViewController.h"
#import "NoaInputTextView.h"
#import "NoaSafeSettingTools.h"
#import "LXChatEncrypt.h"
#import "NoaSafeSettingViewController.h"

@interface NoaSafeCodeSettingViewController ()

@property (nonatomic, strong)NoaInputTextView *safeCodeInput;
@property (nonatomic, strong)UILabel *safeCodeInputTipsLbl;
@property (nonatomic, strong)NoaInputTextView *confimSafeCodeInput;
@property (nonatomic, strong)UILabel *confimSafeCodeInputTipsLbl;

@end

@implementation NoaSafeCodeSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
    self.view.tkThemebackgroundColors = @[COLOR_F5F6F9, COLOR_11];
    
    self.navTitleStr = LanguageToolMatch(@"设备安全码");
    [self setupNavBarUI];
    [self setupUI];
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
    //tips
    UILabel *tipsTitleLab = [[UILabel alloc] init];
    tipsTitleLab.text = LanguageToolMatch(@"为了加强安全防护，请设置您的设备安全码，新设备首次登录时须输入安全码。安全码6位，同时包含字母、数字。");
    tipsTitleLab.tkThemetextColors = @[COLOR_11, COLOR_11_DARK];
    tipsTitleLab.font = FONTN(12);
    tipsTitleLab.textAlignment = NSTextAlignmentLeft;
    tipsTitleLab.numberOfLines = 0;
    [self.view addSubview:tipsTitleLab];
    [tipsTitleLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.navView.mas_bottom).offset(DWScale(20));
        make.leading.equalTo(self.view).offset(DWScale(16));
        make.trailing.equalTo(self.view).offset(DWScale(-16));
    }];
    
    //请输入安全码
    UILabel *newTitleLab = [[UILabel alloc] init];
    newTitleLab.text = LanguageToolMatch(@"请输入安全码");
    newTitleLab.tkThemetextColors = @[COLOR_11, COLOR_11_DARK];
    newTitleLab.font = FONTN(14);
    newTitleLab.textAlignment = NSTextAlignmentLeft;
    [self.view addSubview:newTitleLab];
    [newTitleLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(tipsTitleLab.mas_bottom).offset(DWScale(16));
        make.leading.equalTo(self.view).offset(DWScale(16));
        make.trailing.equalTo(self.view).offset(DWScale(-16));
        make.height.mas_equalTo(DWScale(18));
    }];
    
    [self.view addSubview:self.safeCodeInput];
    [self.safeCodeInput mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(newTitleLab.mas_bottom).offset(DWScale(8));
        make.leading.equalTo(self.view).offset(DWScale(16));
        make.trailing.equalTo(self.view).offset(DWScale(-16));
        make.height.mas_equalTo(DWScale(44));
    }];
    
    [self.view addSubview:self.safeCodeInputTipsLbl];
    [self.safeCodeInputTipsLbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.safeCodeInput.mas_bottom);
        make.leading.equalTo(self.view).offset(DWScale(16));
        make.trailing.equalTo(self.view).offset(DWScale(-16));
        make.height.mas_equalTo(0);
    }];
    
    //再次输入安全码
    UILabel *confirmTitleLab = [[UILabel alloc] init];
    confirmTitleLab.text = LanguageToolMatch(@"再次输入安全码");
    confirmTitleLab.tkThemetextColors = @[COLOR_11, COLOR_11_DARK];
    confirmTitleLab.font = FONTN(14);
    confirmTitleLab.textAlignment = NSTextAlignmentLeft;
    [self.view addSubview:confirmTitleLab];
    [confirmTitleLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.safeCodeInputTipsLbl.mas_bottom).offset(DWScale(16));
        make.leading.equalTo(self.view).offset(DWScale(16));
        make.trailing.equalTo(self.view).offset(DWScale(-16));
        make.height.mas_equalTo(DWScale(18));
    }];
    
    [self.view addSubview:self.confimSafeCodeInput];
    [self.confimSafeCodeInput mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(confirmTitleLab.mas_bottom).offset(DWScale(8));
        make.leading.equalTo(self.view).offset(DWScale(16));
        make.trailing.equalTo(self.view).offset(DWScale(-16));
        make.height.mas_equalTo(DWScale(44));
    }];
    
    [self.view addSubview:self.confimSafeCodeInputTipsLbl];
    [self.confimSafeCodeInputTipsLbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.confimSafeCodeInput.mas_bottom);
        make.leading.equalTo(self.view).offset(DWScale(16));
        make.trailing.equalTo(self.view).offset(DWScale(-16));
        make.height.mas_equalTo(0);
    }];
    
    //输入框输入内容变化回调
    @weakify(self)
    [self.safeCodeInput setInputStatus:^{
        @strongify(self)
        [self listenSafeCodeInput];
    }];
    [self.confimSafeCodeInput setInputStatus:^{
        @strongify(self)
        [self listenConfimSafeCodeInput];
    }];
}

//安全码监听
- (void)listenSafeCodeInput {
    if ([NoaSafeSettingTools checkInputDeviceSafeCodeEndWithText:self.safeCodeInput.inputText.text]) {
        self.safeCodeInputTipsLbl.hidden = YES;
        [self.safeCodeInputTipsLbl mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(0);
        }];
    } else {
        self.safeCodeInputTipsLbl.hidden = NO;
        [self.safeCodeInputTipsLbl mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(DWScale(16));
        }];
    }
    
    [self checkFinishBtnAvailable];
}

//确认安全码监听
- (void)listenConfimSafeCodeInput {
    if (![self.safeCodeInput.inputText.text isEqualToString:self.confimSafeCodeInput.inputText.text]) {
        self.confimSafeCodeInputTipsLbl.hidden = NO;
        [self.confimSafeCodeInputTipsLbl mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(DWScale(16));
        }];
    } else {
        self.confimSafeCodeInputTipsLbl.hidden = YES;
        [self.confimSafeCodeInputTipsLbl mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(0);
        }];
    }
    
    [self checkFinishBtnAvailable];
}

- (void)checkFinishBtnAvailable {
    if (self.safeCodeInput.textLength > 0 && self.confimSafeCodeInput.textLength > 0) {
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

#pragma mark - Action
- (void)navBtnRightClicked {
    if (![NoaSafeSettingTools checkInputDeviceSafeCodeEndWithText:self.safeCodeInput.inputText.text]) {
        [HUD showMessage:LanguageToolMatch(@"请输入6位包含字母、数字的安全码") inView:self.view];
        return;
    }
    if (![self.safeCodeInput.inputText.text isEqualToString:self.confimSafeCodeInput.inputText.text]) {
        [HUD showMessage:LanguageToolMatch(@"两次安全码需保持一致") inView:self.view];
        return;
    }
    
    [self requestGetEncryptKeyAction];
}

#pragma mark - Request
- (void)requestGetEncryptKeyAction {
    @weakify(self)
    [HUD showActivityMessage:@"" inView:self.view];
    [IMSDKManager authGetEncryptKeySuccess:^(id  _Nullable data, NSString * _Nullable traceId) {
        @strongify(self)
        [HUD hideHUD];
        if([data isKindOfClass:[NSString class]]){
            NSString *encryptKey = (NSString *)data;
            [self requestSaveDeviceSafeCodeWithEncryptkey:encryptKey];
        }
    } onFailure:^(NSInteger code, NSString * _Nullable msg, NSString * _Nullable traceId) {
        @strongify(self)
        [HUD showMessageWithCode:code errorMsg:msg inView:self.view];
    }];
}

- (void)requestSaveDeviceSafeCodeWithEncryptkey:(NSString *)encryptKey {
    NSString *safeCodeEncryptStr = @"";
    if (![NSString isNil:encryptKey]) {
        //AES对称加密后的密码
        NSString *safeCodeKey = [NSString stringWithFormat:@"%@%@", encryptKey, [self.safeCodeInput.inputText.text trimString]];
        safeCodeEncryptStr = [LXChatEncrypt method4:safeCodeKey];
        if ([NSString isNil:safeCodeEncryptStr]) {
            [HUD showMessage:LanguageToolMatch(@"操作失败") inView:self.view];
            return;
        }
    }
    
    //调用设置安全码接口
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObjectSafe:encryptKey forKey:@"encryptKey"];
    [params setObjectSafe:safeCodeEncryptStr forKey:@"securityCode"];
    [params setObjectSafe:UserManager.userInfo.userUID forKey:@"userUid"];
    
    @weakify(self)
    [HUD showActivityMessage:@"" inView:self.view];
    [IMSDKManager authSaveSecurityCodeWith:params onSuccess:^(id  _Nullable data, NSString * _Nullable traceId) {
        @strongify(self)
        BOOL result = [data boolValue];
        if (result) {
            [HUD showMessage:LanguageToolMatch(@"设置成功") inView:self.view];
            NSArray *viewControllers = self.navigationController.viewControllers;
            for (UIViewController *vc in viewControllers) {
                if ([vc isKindOfClass:[NoaSafeSettingViewController class]]) {
                    NoaSafeSettingViewController *safeCodeSettingVC = (NoaSafeSettingViewController *)vc;
                    [safeCodeSettingVC checkDeviceSafeCodeStatus];
                }
            }
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            [HUD showMessage:LanguageToolMatch(@"操作失败") inView:self.view];
        }
    } onFailure:^(NSInteger code, NSString * _Nullable msg, NSString * _Nullable traceId) {
        @strongify(self)
        if (code == Auth_Login_SecurityCode_Has_Set_Error_Code || code == Auth_Login_SecurityCode_No_Set_Error_Code || code == Auth_Login_SecurityCode_Format_Error_Code || code == Auth_Login_SecurityCode_otherFormat_Error_Code) {
            return;
        } else {
            [HUD showMessageWithCode:code errorMsg:msg inView:self.view];
        }
    }];
}

#pragma mark - Lazy
- (NoaInputTextView *)safeCodeInput {
    if (!_safeCodeInput) {
        _safeCodeInput = [[NoaInputTextView alloc] init];
        _safeCodeInput.clipsToBounds = YES;
        _safeCodeInput.isPassword = YES;
        _safeCodeInput.isShowBoard = NO;
        _safeCodeInput.placeholderText = LanguageToolMatch(@"请输入安全码");
        _safeCodeInput.bgViewBackColor = @[COLORWHITE, COLOR_F5F6F9_DARK];
        _safeCodeInput.inputText.keyboardType = UIKeyboardTypeASCIICapable;
      
        if (@available(iOS 12.0, *)) {
            _safeCodeInput.inputText.textContentType = UITextContentTypeOneTimeCode;
        } else {
            // Fallback on earlier versions
        }
        _safeCodeInput.inputType = ZMessageInputViewTypePassword;
        _safeCodeInput.tipsImgName = @"";
    }
    return _safeCodeInput;
}

- (UILabel *)safeCodeInputTipsLbl {
    if (!_safeCodeInputTipsLbl) {
        _safeCodeInputTipsLbl = [[UILabel alloc] init];
        _safeCodeInputTipsLbl.text = LanguageToolMatch(@"请输入6位包含字母、数字的安全码");
        _safeCodeInputTipsLbl.tkThemetextColors = @[COLOR_FF3333, COLOR_FF3333_DARK];
        _safeCodeInputTipsLbl.font = FONTN(12);
        _safeCodeInputTipsLbl.textAlignment = NSTextAlignmentLeft;
        _safeCodeInputTipsLbl.hidden = YES;
    }
    return _safeCodeInputTipsLbl;
}

- (NoaInputTextView *)confimSafeCodeInput {
    if (!_confimSafeCodeInput) {
        _confimSafeCodeInput = [[NoaInputTextView alloc] init];
        _confimSafeCodeInput.isPassword = YES;
        _confimSafeCodeInput.isShowBoard = NO;
        _confimSafeCodeInput.placeholderText = LanguageToolMatch(@"请再次输入安全码");
        _confimSafeCodeInput.bgViewBackColor = @[COLORWHITE, COLOR_F5F6F9_DARK];
        _confimSafeCodeInput.inputText.keyboardType = UIKeyboardTypeASCIICapable;
        if (@available(iOS 12.0, *)) {
            _confimSafeCodeInput.inputText.textContentType = UITextContentTypeOneTimeCode;
        } else {
            // Fallback on earlier versions
        }
        _confimSafeCodeInput.inputType = ZMessageInputViewTypePassword;
        _confimSafeCodeInput.tipsImgName = @"";
    }
    return _confimSafeCodeInput;
}

- (UILabel *)confimSafeCodeInputTipsLbl {
    if (!_confimSafeCodeInputTipsLbl) {
        _confimSafeCodeInputTipsLbl = [[UILabel alloc] init];
        _confimSafeCodeInputTipsLbl.text = LanguageToolMatch(@"两次安全码需保持一致");
        _confimSafeCodeInputTipsLbl.tkThemetextColors = @[COLOR_FF3333, COLOR_FF3333_DARK];
        _confimSafeCodeInputTipsLbl.font = FONTN(12);
        _confimSafeCodeInputTipsLbl.textAlignment = NSTextAlignmentLeft;
        _confimSafeCodeInputTipsLbl.hidden = YES;
    }
    return _confimSafeCodeInputTipsLbl;
}


@end
