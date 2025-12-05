//
//  NoaChangeUserInfoViewController.m
//  NoaKit
//
//  Created by Mac on 2022/11/14.
//

#import "NoaChangeUserInfoViewController.h"
#import "UITextView+Addition.h"
@interface NoaChangeUserInfoViewController ()

@property (nonatomic, assign)NSInteger maxNum;
@property (nonatomic, strong)UIButton *clearBtn;
@property (nonatomic, strong)UILabel *textNumLbl;
@property (nonatomic, strong)UITextView *inputText;

@end

@implementation NoaChangeUserInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.tkThemebackgroundColors = @[COLOR_F5F6F9, COLOR_11];
    
    if (self.changeType == changeUserInfoTypeAccount) {
        self.navTitleStr = LanguageToolMatch(@"修改账号");
        self.maxNum = 16;
        self.inputText.text = UserManager.userInfo.userName;
    } else {
        self.navTitleStr = LanguageToolMatch(@"修改昵称");
        self.maxNum = 30;
        self.inputText.text = UserManager.userInfo.nickname;
    }
    [self setNavBarUI];
    [self setupUI];
    //此处需要调用一下该方法
    [self textChangedAction];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChangedAction) name:UITextViewTextDidChangeNotification object:nil];
}

- (void)setNavBarUI {
    self.navBtnRight.hidden = NO;
    [self.navBtnRight setTitle:LanguageToolMatch(@"保存") forState:UIControlStateNormal];
    [self.navBtnRight setTkThemeTitleColor:@[COLORWHITE, COLOR_CCCCCC_DARK] forState:UIControlStateNormal];
    self.navBtnRight.enabled = NO;
    [self.navBtnRight setTkThemeBackgroundImage:@[[UIImage ImageForColor:COLOR_4069B9],[UIImage ImageForColor:COLOR_4069B9_DARK]] forState:UIControlStateSelected];
    [self.navBtnRight setTkThemeBackgroundImage:@[[UIImage ImageForColor:COLOR_4069B9],[UIImage ImageForColor:COLOR_4069B9_DARK]] forState:UIControlStateHighlighted];
    self.navBtnRight.tkThemebackgroundColors = @[COLOR_CCCCCC, COLOR_EEEEEE_DARK];
    [self.navBtnRight rounded:DWScale(12)];
    [self.navBtnRight mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.navTitleLabel);
        make.trailing.equalTo(self.navView).offset(-DWScale(20));
        make.height.mas_equalTo(DWScale(32));
        CGSize textSize = [self.navBtnRight.titleLabel.text sizeWithFont:FONTR(14) constrainedToSize:CGSizeMake(10000, DWScale(32))];
        make.width.mas_equalTo(MIN(textSize.width+DWScale(28), 60));

    }];
}

- (void)setupUI {
    UIView *inputBackView = [[UIView alloc] init];
    inputBackView.tkThemebackgroundColors = @[COLORWHITE, COLOR_F5F6F9_DARK];
    [inputBackView rounded:14];
    [self.view addSubview:inputBackView];
    
    if (self.changeType == changeUserInfoTypeAccount) {
        UILabel *titleLab = [[UILabel alloc] init];
        titleLab.text = LanguageToolMatch(@"账号只能修改一次");
        titleLab.tkThemetextColors = @[COLOR_66, COLOR_66_DARK];
        titleLab.font = FONTN(12);
        titleLab.textAlignment = NSTextAlignmentLeft;
        [self.view addSubview:titleLab];
        [titleLab mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view).offset(16 + DNavStatusBarH);
            make.leading.equalTo(self.view).offset(16);
            make.trailing.equalTo(self.view).offset(-16);
            make.height.mas_equalTo(DWScale(17));
        }];
        
        [inputBackView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(titleLab.mas_bottom).offset(4);
            make.leading.equalTo(self.view).offset(16);
            make.trailing.equalTo(self.view).offset(-16);
            make.height.mas_equalTo(DWScale(70));
        }];
        
        UILabel *subTitleLab = [[UILabel alloc] init];
        subTitleLab.text = LanguageToolMatch(@"*账号格式：2个字母+字母/数字,长度：6-16");
        subTitleLab.tkThemetextColors = @[COLOR_F93A2F, COLOR_F93A2F_DARK];
        subTitleLab.font = FONTN(14);
        subTitleLab.textAlignment = NSTextAlignmentLeft;
        subTitleLab.numberOfLines = 0;
        [self.view addSubview:subTitleLab];
        [subTitleLab mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(inputBackView.mas_bottom).offset(DWScale(8));
            make.leading.equalTo(self.view).offset(18);
            make.trailing.equalTo(self.view).offset(-18);
        }];
    } else {
        [inputBackView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view).offset(16 + DNavStatusBarH);
            make.leading.equalTo(self.view).offset(16);
            make.trailing.equalTo(self.view).offset(-16);
            make.height.mas_equalTo(DWScale(70));
        }];
    }
    
    _clearBtn = [[UIButton alloc] init];
    [_clearBtn setImage:ImgNamed(@"icon_userinfo_text_clear") forState:UIControlStateNormal];
    [_clearBtn addTarget:self action:@selector(clearBtnAction) forControlEvents:UIControlEventTouchUpInside];
    [inputBackView addSubview:_clearBtn];
    [_clearBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(inputBackView).offset(DWScale(8));
        make.trailing.equalTo(inputBackView).offset(-10);
        make.width.height.mas_equalTo(DWScale(20));
    }];

    _textNumLbl = [[UILabel alloc] init];
    if (self.changeType == changeUserInfoTypeAccount) {
        _textNumLbl.text = @"0/30";
    } else {
        _textNumLbl.text = @"0/16";
    }
    _textNumLbl.tkThemetextColors = @[COLOR_99, COLOR_99_DARK];
    _textNumLbl.font = FONTN(12);
    _textNumLbl.textAlignment = NSTextAlignmentRight;
    [inputBackView addSubview:_textNumLbl];
    [_textNumLbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_clearBtn.mas_bottom).offset(DWScale(10));
        make.trailing.equalTo(inputBackView).offset(-10);
        make.width.mas_equalTo(DWScale(40));
        make.height.mas_equalTo(DWScale(17));
    }];
    
    _inputText = [[UITextView alloc] init];
    _inputText.text = self.originalContent;
    _inputText.tkThemetextColors = @[COLOR_11, COLOR_11_DARK];
    _inputText.tkThemebackgroundColors = @[COLORWHITE, COLOR_F5F6F9_DARK];
    _inputText.font = FONTN(16);
    _inputText.textAlignment = NSTextAlignmentLeft;
    [inputBackView addSubview:_inputText];
    [_inputText mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(inputBackView).offset(16);
        make.top.equalTo(inputBackView).offset(3);
        make.bottom.equalTo(inputBackView);
        make.trailing.equalTo(_textNumLbl.mas_leading);
    }];
}

#pragma mark - Action
- (void)clearBtnAction {
    _inputText.text = @"";
}

//TextField Action
- (void)textChangedAction {
    if (self.changeType == changeUserInfoTypeNick) {
        _inputText.text = [_inputText.text stringByReplacingOccurrencesOfString:@"'" withString:@""];
        _inputText.text = [_inputText.text stringByReplacingOccurrencesOfString:@"’" withString:@""];
    }
    if (![NSString isNil:_inputText.text]) {
        if (self.changeType == changeUserInfoTypeAccount) {
            if ([self.inputText.text isEqualToString:UserManager.userInfo.userName]) {
                self.clearBtn.hidden = NO;
                self.navBtnRight.enabled = NO;
                [self.navBtnRight setTkThemeTitleColor:@[COLORWHITE, COLOR_CCCCCC_DARK] forState:UIControlStateNormal];
                self.navBtnRight.tkThemebackgroundColors = @[COLOR_CCCCCC, COLOR_EEEEEE_DARK];
            } else {
                self.clearBtn.hidden = NO;
                self.navBtnRight.enabled = YES;
                [self.navBtnRight setTkThemeTitleColor:@[COLORWHITE, COLORWHITE] forState:UIControlStateNormal];
                self.navBtnRight.tkThemebackgroundColors = @[COLOR_5966F2, COLOR_5966F2_DARK];
                [self.navBtnRight setTkThemeBackgroundImage:@[[UIImage ImageForColor:COLOR_4069B9],[UIImage ImageForColor:COLOR_4069B9_DARK]] forState:UIControlStateSelected];
                [self.navBtnRight setTkThemeBackgroundImage:@[[UIImage ImageForColor:COLOR_4069B9],[UIImage ImageForColor:COLOR_4069B9_DARK]] forState:UIControlStateHighlighted];
            }
        } else {
            if ([self.inputText.text isEqualToString:UserManager.userInfo.nickname]) {
                self.clearBtn.hidden = NO;
                self.navBtnRight.enabled = NO;
                [self.navBtnRight setTkThemeTitleColor:@[COLORWHITE, COLOR_CCCCCC_DARK] forState:UIControlStateNormal];
                self.navBtnRight.tkThemebackgroundColors = @[COLOR_CCCCCC, COLOR_EEEEEE_DARK];
            } else {
                self.clearBtn.hidden = NO;
                self.navBtnRight.enabled = YES;
                [self.navBtnRight setTkThemeTitleColor:@[COLORWHITE, COLORWHITE] forState:UIControlStateNormal];
                self.navBtnRight.tkThemebackgroundColors = @[COLOR_5966F2, COLOR_5966F2_DARK];
                [self.navBtnRight setTkThemeBackgroundImage:@[[UIImage ImageForColor:COLOR_4069B9],[UIImage ImageForColor:COLOR_4069B9_DARK]] forState:UIControlStateSelected];
                [self.navBtnRight setTkThemeBackgroundImage:@[[UIImage ImageForColor:COLOR_4069B9],[UIImage ImageForColor:COLOR_4069B9_DARK]] forState:UIControlStateHighlighted];
            }
        }
    } else {
        self.clearBtn.hidden = YES;
        self.navBtnRight.enabled = NO;
        [self.navBtnRight setTkThemeTitleColor:@[COLORWHITE, COLOR_CCCCCC_DARK] forState:UIControlStateNormal];
        self.navBtnRight.tkThemebackgroundColors = @[COLOR_CCCCCC, COLOR_EEEEEE_DARK];
    }
    
    if (_inputText.text.length > self.maxNum) {
        _inputText.text = [_inputText.text substringToIndex:self.maxNum];
    }
    _textNumLbl.text = [NSString stringWithFormat:@"%lu/%ld", (unsigned long)_inputText.text.length, (long)self.maxNum];
}

//保存
- (void)navBtnRightClicked {
    if (self.changeType == changeUserInfoTypeAccount) {
        //修改账号
        if ([NSString isNil:[_inputText.text trimString]]) {
            [HUD showMessage:LanguageToolMatch(@"账号不能为空")];
            return;
        }
        if ([[_inputText.text trimString] isEqualToString:UserManager.userInfo.userUID]) {
            [HUD showMessage:LanguageToolMatch(@"与当前账号相同")];
            return;
        }
        if ([[_inputText.text trimString] checkUserAccountFormat] == NO) {
            [HUD showMessage:LanguageToolMatch(@"账号格式错误")];
            return;
        }
        //调用修改账号接口
        [self requestChangeUserName];
    } else {
        //修改昵称
        if ([NSString isNil:[_inputText.text trimString]]) {
            [HUD showMessage:LanguageToolMatch(@"昵称不能为空")];
            return;
        }
        if ([[_inputText.text trimString] isEqualToString:UserManager.userInfo.userName]) {
            [HUD showMessage:LanguageToolMatch(@"与当前昵称相同")];
            return;
        }
        //调用修改昵称接口
        [self requestChangeNickName];
    }
}

//检查账号是否被注册过
- (void)requestCheckUserNameExit {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObjectSafe:_inputText.text forKey:@"loginInfo"];
    [params setObjectSafe:@"" forKey:@"areaCode"];
    [params setObjectSafe:[NSNumber numberWithInt:UserAuthTypeAccount] forKey:@"loginType"];

    WeakSelf
    [IMSDKManager authUserExistWith:params onSuccess:^(id _Nullable data, NSString * _Nullable traceId) {
        BOOL exist = [data boolValue];
        if (!exist) {
            //账号未使用过
            [weakSelf requestChangeUserName];
        } else {
            //账号已使用
            [HUD showMessage:LanguageToolMatch(@"账号已被使用")];
        }
    } onFailure:^(NSInteger code, NSString * _Nullable msg, NSString * _Nullable traceId) {
        [HUD showMessageWithCode:code errorMsg:msg];
    }];
}

//调用修改账号接口
- (void)requestChangeUserName {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObjectSafe:_inputText.text forKey:@"userName"];
    [dict setObjectSafe:UserManager.userInfo.userUID forKey:@"userUid"];
    
    WeakSelf
    [IMSDKManager userAccountChangeWith:dict onSuccess:^(id _Nullable data, NSString * _Nullable traceId) {
        //修改账号成功
        [NoaUserModel savePreAccount:weakSelf.inputText.text Type:UserAuthTypeAccount];
        NoaUserModel *resultUserModel = UserManager.userInfo;
        resultUserModel.userName = weakSelf.inputText.text;
        [resultUserModel saveUserInfo];
        [UserManager setUserInfo:resultUserModel];
        [weakSelf.navigationController popViewControllerAnimated:YES];
    } onFailure:^(NSInteger code, NSString * _Nullable msg, NSString * _Nullable traceId) {
        [HUD showMessageWithCode:code errorMsg:msg];
    }];
}

//调用修改昵称接口
- (void)requestChangeNickName {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObjectSafe:_inputText.text forKey:@"nickname"];
    [dict setObjectSafe:UserManager.userInfo.userUID forKey:@"userUid"];
    
    WeakSelf
    [IMSDKManager userNicknameChangeWith:dict onSuccess:^(id _Nullable data, NSString * _Nullable traceId) {
        //修改昵称成功
        NoaUserModel *resultUserModel = UserManager.userInfo;
        resultUserModel.nickname = weakSelf.inputText.text;
        [resultUserModel saveUserInfo];
        [UserManager setUserInfo:resultUserModel];
        [weakSelf.navigationController popViewControllerAnimated:YES];
    } onFailure:^(NSInteger code, NSString * _Nullable msg, NSString * _Nullable traceId) {
        [HUD showMessageWithCode:code errorMsg:msg];
    }];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
