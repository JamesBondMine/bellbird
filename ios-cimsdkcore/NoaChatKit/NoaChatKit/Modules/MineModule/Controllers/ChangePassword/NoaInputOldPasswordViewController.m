//
//  NoaInputOldPasswordViewController.m
//  NoaKit
//
//  Created by Mac on 2022/11/13.
//

#import "NoaInputOldPasswordViewController.h"
#import "NoaInputNewPasswordViewController.h"
#import "LXChatEncrypt.h"

@interface NoaInputOldPasswordViewController ()

@property (nonatomic, strong)UITextField *inputTextField;
@property (nonatomic, strong)UIButton *eyeBtn;

@end

@implementation NoaInputOldPasswordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navTitleStr = LanguageToolMatch(@"请输入密码");
    [self setupNavBarUI];
    [self setupUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.isForcedReset) {
        self.navBtnBack.hidden = YES;
        // 禁用侧滑返回
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
    // 避免影响其他页面，离开时恢复手势（若未进入新密码页也不影响）
    if (self.navigationController.interactivePopGestureRecognizer) {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    }
}

- (void)setupNavBarUI {
    self.navBtnRight.hidden = NO;
    [self.navBtnRight setTitle:LanguageToolMatch(@"下一步") forState:UIControlStateNormal];
    [self.navBtnRight setTkThemeTitleColor:@[COLORWHITE, COLOR_CCCCCC_DARK] forState:UIControlStateNormal];
    self.navBtnRight.enabled = NO;
    self.navBtnRight.tkThemebackgroundColors = @[COLOR_CCCCCC, COLOR_EEEEEE_DARK];
    [self.navBtnRight setTkThemeBackgroundImage:@[[UIImage ImageForColor:COLOR_4069B9],[UIImage ImageForColor:COLOR_4069B9_DARK]] forState:UIControlStateSelected];
    [self.navBtnRight setTkThemeBackgroundImage:@[[UIImage ImageForColor:COLOR_4069B9],[UIImage ImageForColor:COLOR_4069B9_DARK]] forState:UIControlStateHighlighted];
    [self.navBtnRight rounded:DWScale(12)];
    [self.navBtnRight mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.navTitleLabel);
        make.trailing.equalTo(self.navView).offset(-DWScale(20));
        make.width.mas_equalTo(DWScale(90));
        CGSize textSize = [self.navBtnRight.titleLabel.text sizeWithFont:FONTR(14) constrainedToSize:CGSizeMake(10000, DWScale(32))];
        CGFloat btnHeight = DWScale(32);
        if (textSize.height > DWScale(30)) {
            btnHeight = textSize.height;
        }
        make.height.mas_equalTo(btnHeight > DWScale(60) ? DWScale(60) : btnHeight);
    }];
}

- (void)setupUI {
    UILabel *titleLab = [[UILabel alloc] init];
    titleLab.text = LanguageToolMatch(@"请输入密码");
    titleLab.tkThemetextColors = @[COLOR_66, COLOR_66_DARK];
    titleLab.font = FONTN(12);
    titleLab.textAlignment = NSTextAlignmentLeft;
    [self.view addSubview:titleLab];
    [titleLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(16 + DNavStatusBarH);
        make.leading.equalTo(self.view).offset(20);
        make.trailing.equalTo(self.view).offset(-20);
        make.height.mas_equalTo(DWScale(17));
    }];
    
    UIView *inputBackView = [[UIView alloc] init];
    inputBackView.tkThemebackgroundColors = @[COLOR_F5F6F9, COLOR_F5F6F9_DARK];
    [inputBackView rounded:14];
    [self.view addSubview:inputBackView];
    [inputBackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(titleLab.mas_bottom).offset(4);
        make.leading.equalTo(self.view).offset(16);
        make.trailing.equalTo(self.view).offset(-16);
        make.height.mas_equalTo(DWScale(48));
    }];
    
    [inputBackView addSubview:self.eyeBtn];
    [self.eyeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(inputBackView);
        make.trailing.equalTo(inputBackView).offset(-22);
        make.width.mas_equalTo(DWScale(21));
        make.height.mas_equalTo(DWScale(16));
    }];
    
    [inputBackView addSubview:self.inputTextField];
    [self.inputTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(inputBackView);
        make.leading.equalTo(inputBackView).offset(16);
        make.trailing.equalTo(self.eyeBtn.mas_leading).offset(-10);
    }];
}

#pragma mark - Action
- (void)navBtnRightClicked {
    [self requestGetEncryptKeyAction];
}

//TextField Action
- (void)textChangedAction {
    if (![NSString isNil:self.inputTextField.text]) {
        self.eyeBtn.hidden = NO;
        self.navBtnRight.enabled = YES;
        [self.navBtnRight setTkThemeTitleColor:@[COLORWHITE, COLORWHITE] forState:UIControlStateNormal];
        self.navBtnRight.tkThemebackgroundColors = @[COLOR_5966F2, COLOR_5966F2_DARK];
        [self.navBtnRight setTkThemeBackgroundImage:@[[UIImage ImageForColor:COLOR_4069B9],[UIImage ImageForColor:COLOR_4069B9_DARK]] forState:UIControlStateSelected];
        [self.navBtnRight setTkThemeBackgroundImage:@[[UIImage ImageForColor:COLOR_4069B9],[UIImage ImageForColor:COLOR_4069B9_DARK]] forState:UIControlStateHighlighted];
    } else {
        self.eyeBtn.hidden = YES;
        self.navBtnRight.enabled = NO;
        [self.navBtnRight setTkThemeTitleColor:@[COLORWHITE, COLOR_CCCCCC_DARK] forState:UIControlStateNormal];
        self.navBtnRight.tkThemebackgroundColors = @[COLOR_CCCCCC, COLOR_EEEEEE_DARK];
    }
}

//密码是否明文显示
- (void)eyeBtnAction {
    self.eyeBtn.selected = !self.eyeBtn.selected;
    self.inputTextField.secureTextEntry = !self.eyeBtn.selected;
}

#pragma mark - Request
- (void)requestGetEncryptKeyAction {
    if ([NSString isNil:_inputTextField.text]) {
        [HUD showMessage:LanguageToolMatch(@"密码不能为空") inView:self.view];
        return;
    }
    
    @weakify(self)
    [IMSDKManager authGetEncryptKeySuccess:^(id  _Nullable data, NSString * _Nullable traceId) {
        @strongify(self)
        //调用注册接口，传入加密密钥
        if([data isKindOfClass:[NSString class]]){
            NSString *encryptKey = (NSString *)data;
            [self requestCheckUserPassword:encryptKey];
        }
    } onFailure:^(NSInteger code, NSString * _Nullable msg, NSString * _Nullable traceId) {
        @strongify(self)
        [HUD showMessageWithCode:code errorMsg:msg inView:self.view];
    }];
}

- (void)requestCheckUserPassword:(NSString *)encryptKey {
    //AES对称加密后的密码
    NSString *passwordKey = [NSString stringWithFormat:@"%@%@", encryptKey, _inputTextField.text];
    NSString *userPwStr = [LXChatEncrypt method4:passwordKey];
    //调用校验密码接口
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObjectSafe:userPwStr forKey:@"password"];
    [params setObjectSafe:encryptKey forKey:@"encryptKey"];
    [params setObjectSafe:UserManager.userInfo.userUID forKey:@"userUid"];
    
    @weakify(self)
    [IMSDKManager userCheckUserPasswordWith:params onSuccess:^(id _Nullable data, NSString * _Nullable traceId) {
        @strongify(self)
        BOOL checkResult = [data boolValue];
        if (checkResult) {
            NoaInputNewPasswordViewController *newPwInputVC = [[NoaInputNewPasswordViewController alloc] init];
            newPwInputVC.isForcedReset = self.isForcedReset;
            [self.navigationController pushViewController:newPwInputVC animated:YES];
        } else {
            [HUD showMessage:LanguageToolMatch(@"密码校验失败") inView:self.view];
        }
    } onFailure:^(NSInteger code, NSString * _Nullable msg, NSString * _Nullable traceId) {
        @strongify(self)
        [HUD showMessageWithCode:code errorMsg:msg inView:self.view];
    }];
}

#pragma mark - Lazy
- (UITextField *)inputTextField {
    if (!_inputTextField) {
        _inputTextField = [[UITextField alloc] init];
        _inputTextField.tkThemetextColors = @[COLOR_11, COLOR_11_DARK];
        _inputTextField.tkThemebackgroundColors = @[COLOR_F5F6F9, COLOR_F5F6F9_DARK];
        _inputTextField.font = FONTN(16);
//        _inputTextField.placeholder = LanguageToolMatch(@"输入原密码");
        _inputTextField.secureTextEntry = YES;
        _inputTextField.textAlignment = NSTextAlignmentLeft;
        _inputTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:LanguageToolMatch(@"输入原密码")];
        [_inputTextField addTarget:self action:@selector(textChangedAction) forControlEvents:UIControlEventEditingChanged];
    }
    return _inputTextField;
}

- (UIButton *)eyeBtn {
    if (!_eyeBtn) {
        _eyeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_eyeBtn setImage:ImgNamed(@"icon_eye_off") forState:UIControlStateNormal];
        [_eyeBtn setImage:ImgNamed(@"icon_eye_on") forState:UIControlStateSelected];
        _eyeBtn.selected = NO;
        _eyeBtn.hidden = YES;
        [_eyeBtn addTarget:self action:@selector(eyeBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _eyeBtn;
}

@end
