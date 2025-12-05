//
//  NoaAboutUsViewController.m
//  NoaKit
//
//  Created by Mac on 2022/11/13.
//

#import "NoaAboutUsViewController.h"
#import "NoaToolManager.h"
#import "NoaAppUpdateTools.h"

#define SERVE_BTN_TAG           101
#define PRIVACY_BTN_TAG         102
#define SCORE_BTN_TAG           103
#define VERSION_BTN_TAG         104
#define LOGAN_BTN_TAG           105

@interface NoaAboutUsViewController ()

@end

@implementation NoaAboutUsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navTitleStr = LanguageToolMatch(@"关于我们");
    self.view.tkThemebackgroundColors = @[COLOR_F5F6F9, COLOR_11];
    
    [self setupUI];
}

- (void)setupUI {
    UIImageView *logoImgView = [[UIImageView alloc] init];
    logoImgView.image = ImgNamed(@"img_login_logo");
    [self.view addSubview:logoImgView];
    [logoImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(DNavStatusBarH + 20);
        make.centerX.equalTo(self.view);
        make.width.height.mas_equalTo(DWScale(82));
    }];
    
    UILabel *versionLbl = [[UILabel alloc] init];
    versionLbl.text = [NSString stringWithFormat:LanguageToolMatch(@"当前版本v%@ %@"), [ZTOOL getCurretnVersion], [ZTOOL getBuildVersion]];
    versionLbl.tkThemetextColors = @[COLOR_66, COLOR_66_DARK];
    versionLbl.font = FONTN(16);
    versionLbl.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:versionLbl];
    [versionLbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(logoImgView.mas_bottom).offset(16);
        make.leading.equalTo(self.view).offset(10);
        make.trailing.equalTo(self.view).offset(-10);
        make.height.mas_equalTo(DWScale(22));
    }];
    
    UIView *centerBackView = [[UIView alloc] init];
    centerBackView.tkThemebackgroundColors = @[COLORWHITE, COLOR_F5F6F9_DARK];
    [centerBackView rounded:12];
    [self.view addSubview:centerBackView];
    [centerBackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(versionLbl.mas_bottom).offset(16);
        make.leading.equalTo(self.view).offset(16);
        make.trailing.equalTo(self.view).offset(-16);
        make.height.mas_equalTo(DWScale(274));
    }];
    
    //服务协议
    UIButton *serveBtn = [[UIButton alloc] init];
    serveBtn.tag = SERVE_BTN_TAG;
    serveBtn.tkThemebackgroundColors = @[COLORWHITE, COLOR_F5F6F9_DARK];
    [serveBtn setTkThemeBackgroundImage:@[[UIImage ImageForColor:COLOR_EEEEEE],[UIImage ImageForColor:COLOR_EEEEEE_DARK]] forState:UIControlStateSelected];
    [serveBtn setTkThemeBackgroundImage:@[[UIImage ImageForColor:COLOR_EEEEEE],[UIImage ImageForColor:COLOR_EEEEEE_DARK]] forState:UIControlStateHighlighted];
    [serveBtn addTarget:self action:@selector(contentAction:) forControlEvents:UIControlEventTouchUpInside];
    [centerBackView addSubview:serveBtn];
    [serveBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(centerBackView);
        make.leading.trailing.equalTo(centerBackView);
        make.height.mas_equalTo(DWScale(54));
    }];
    
    UIImageView *serveArrow = [[UIImageView alloc] init];
    serveArrow.image = ImgNamed(@"c_arrow_right_gray");
    [centerBackView addSubview:serveArrow];
    [serveArrow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(serveBtn);
        make.trailing.equalTo(centerBackView).offset(-16);
        make.width.mas_equalTo(DWScale(8));
        make.height.mas_equalTo(DWScale(16));
    }];
    
    UILabel * serveLb = [[UILabel alloc] init];
    serveLb.text = LanguageToolMatch(@"服务协议");
    serveLb.font = FONTN(16);
    serveLb.tkThemetextColors = @[COLOR_11, COLOR_11_DARK];
    [centerBackView addSubview:serveLb];
    [serveLb mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(serveBtn);
        make.leading.equalTo(centerBackView).offset(16);
    }];
    
     
    //分割线
    UIView *lineView1 = [[UIView alloc] init];
    lineView1.tkThemebackgroundColors = @[COLOR_EEEEEE, [UIColor colorWithRed:85.0/255.0 green:85.0/255.0 blue:85.0/255.0 alpha:1]];
    [centerBackView addSubview:lineView1];
    [lineView1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(centerBackView).offset(DWScale(54));
        make.leading.equalTo(centerBackView).offset(16);
        make.trailing.equalTo(centerBackView).offset(-16);
        make.height.mas_equalTo(1.0);
    }];
    
    //隐私政策
    UIButton *privacyBtn = [[UIButton alloc] init];
    privacyBtn.tag = PRIVACY_BTN_TAG;
    privacyBtn.tkThemebackgroundColors = @[COLORWHITE, COLOR_F5F6F9_DARK];
    [privacyBtn setTkThemeBackgroundImage:@[[UIImage ImageForColor:COLOR_EEEEEE],[UIImage ImageForColor:COLOR_EEEEEE_DARK]] forState:UIControlStateSelected];
    [privacyBtn setTkThemeBackgroundImage:@[[UIImage ImageForColor:COLOR_EEEEEE],[UIImage ImageForColor:COLOR_EEEEEE_DARK]] forState:UIControlStateHighlighted];
    [privacyBtn addTarget:self action:@selector(contentAction:) forControlEvents:UIControlEventTouchUpInside];
    [centerBackView addSubview:privacyBtn];
    [privacyBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(lineView1.mas_bottom);
        make.leading.trailing.equalTo(centerBackView);
        make.height.mas_equalTo(DWScale(54));
    }];
    
    UIImageView *privacyArrow = [[UIImageView alloc] init];
    privacyArrow.image = ImgNamed(@"c_arrow_right_gray");
    [centerBackView addSubview:privacyArrow];
    [privacyArrow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(privacyBtn);
        make.trailing.equalTo(centerBackView).offset(-16);
        make.width.mas_equalTo(DWScale(8));
        make.height.mas_equalTo(DWScale(16));
    }];
    
    UILabel * privacyLb = [[UILabel alloc] init];
    privacyLb.text = LanguageToolMatch(@"隐私政策");
    privacyLb.font = FONTN(16);
    privacyLb.tkThemetextColors = @[COLOR_11, COLOR_11_DARK];
    [centerBackView addSubview:privacyLb];
    [privacyLb mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(privacyBtn);
        make.leading.equalTo(centerBackView).offset(16);
    }];
    
    //分割线
    UIView *lineView2 = [[UIView alloc] init];
    lineView2.tkThemebackgroundColors = @[COLOR_EEEEEE, [UIColor colorWithRed:85.0/255.0 green:85.0/255.0 blue:85.0/255.0 alpha:1]];
    [centerBackView addSubview:lineView2];
    [lineView2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(centerBackView).offset(16);
        make.trailing.equalTo(centerBackView).offset(-16);
        make.height.mas_equalTo(1.0);
        make.top.equalTo(privacyBtn.mas_bottom);
    }];
    
    //去评分
    UIButton *scoreBtn = [[UIButton alloc] init];
    scoreBtn.tag = SCORE_BTN_TAG;
    scoreBtn.tkThemebackgroundColors = @[COLORWHITE, COLOR_F5F6F9_DARK];
    [scoreBtn setTkThemeBackgroundImage:@[[UIImage ImageForColor:COLOR_EEEEEE],[UIImage ImageForColor:COLOR_EEEEEE_DARK]] forState:UIControlStateSelected];
    [scoreBtn setTkThemeBackgroundImage:@[[UIImage ImageForColor:COLOR_EEEEEE],[UIImage ImageForColor:COLOR_EEEEEE_DARK]] forState:UIControlStateHighlighted];
    [scoreBtn addTarget:self action:@selector(contentAction:) forControlEvents:UIControlEventTouchUpInside];
    [centerBackView addSubview:scoreBtn];
    [scoreBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(lineView2.mas_bottom);
        make.leading.trailing.equalTo(centerBackView);
        make.height.mas_equalTo(DWScale(54));
    }];
    
    UIImageView *scoreArrow = [[UIImageView alloc] init];
    scoreArrow.image = ImgNamed(@"c_arrow_right_gray");
    [centerBackView addSubview:scoreArrow];
    [scoreArrow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(scoreBtn);
        make.trailing.equalTo(centerBackView).offset(-16);
        make.width.mas_equalTo(DWScale(8));
        make.height.mas_equalTo(DWScale(16));
    }];
    
    UILabel * scoreLb = [[UILabel alloc] init];
    scoreLb.text = LanguageToolMatch(@"去评分");
    scoreLb.font = FONTN(16);
    scoreLb.tkThemetextColors = @[COLOR_11, COLOR_11_DARK];
    [centerBackView addSubview:scoreLb];
    [scoreLb mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(scoreBtn);
        make.leading.equalTo(centerBackView).offset(16);
    }];
    
    //分割线
    UIView *lineView3 = [[UIView alloc] init];
    lineView3.tkThemebackgroundColors = @[COLOR_EEEEEE, [UIColor colorWithRed:85.0/255.0 green:85.0/255.0 blue:85.0/255.0 alpha:1]];
    [centerBackView addSubview:lineView3];
    [lineView3 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(centerBackView).offset(16);
        make.trailing.equalTo(centerBackView).offset(-16);
        make.height.mas_equalTo(1.0);
        make.top.equalTo(scoreBtn.mas_bottom);
    }];
    
    //检查更新
    UIButton *checkVersionBtn = [[UIButton alloc] init];
    checkVersionBtn.tag = VERSION_BTN_TAG;
    checkVersionBtn.tkThemebackgroundColors = @[COLORWHITE, COLOR_F5F6F9_DARK];
    [checkVersionBtn setTkThemeBackgroundImage:@[[UIImage ImageForColor:COLOR_EEEEEE],[UIImage ImageForColor:COLOR_EEEEEE_DARK]] forState:UIControlStateSelected];
    [checkVersionBtn setTkThemeBackgroundImage:@[[UIImage ImageForColor:COLOR_EEEEEE],[UIImage ImageForColor:COLOR_EEEEEE_DARK]] forState:UIControlStateHighlighted];
    [checkVersionBtn addTarget:self action:@selector(contentAction:) forControlEvents:UIControlEventTouchUpInside];
    [centerBackView addSubview:checkVersionBtn];
    [checkVersionBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(lineView3.mas_bottom);
        make.leading.trailing.equalTo(centerBackView);
        make.height.mas_equalTo(DWScale(54));
    }];
    
    UIImageView *checkVersionArrow = [[UIImageView alloc] init];
    checkVersionArrow.image = ImgNamed(@"c_arrow_right_gray");
    [centerBackView addSubview:checkVersionArrow];
    [checkVersionArrow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(checkVersionBtn);
        make.trailing.equalTo(centerBackView).offset(-16);
        make.width.mas_equalTo(DWScale(8));
        make.height.mas_equalTo(DWScale(16));
    }];
    
    UILabel *checkVersionLb = [[UILabel alloc] init];
    checkVersionLb.text = LanguageToolMatch(@"检查更新");
    checkVersionLb.font = FONTN(16);
    checkVersionLb.tkThemetextColors = @[COLOR_11, COLOR_11_DARK];
    [centerBackView addSubview:checkVersionLb];
    [checkVersionLb mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(checkVersionBtn);
        make.leading.equalTo(centerBackView).offset(16);
    }];
    
    //分割线
    UIView *lineView4 = [[UIView alloc] init];
    lineView4.tkThemebackgroundColors = @[COLOR_EEEEEE, [UIColor colorWithRed:85.0/255.0 green:85.0/255.0 blue:85.0/255.0 alpha:1]];
    [centerBackView addSubview:lineView4];
    [lineView4 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(checkVersionBtn.mas_bottom);
        make.leading.equalTo(centerBackView).offset(16);
        make.trailing.equalTo(centerBackView).offset(-16);
        make.height.mas_equalTo(1.0);
    }];
    
    //日志上报
    UIButton *btnLogan = [UIButton buttonWithType:UIButtonTypeCustom];
    btnLogan.tag = LOGAN_BTN_TAG;
    btnLogan.tkThemebackgroundColors = @[COLORWHITE, COLOR_F5F6F9_DARK];
    [btnLogan setTkThemeBackgroundImage:@[[UIImage ImageForColor:COLOR_EEEEEE],[UIImage ImageForColor:COLOR_EEEEEE_DARK]] forState:UIControlStateSelected];
    [btnLogan setTkThemeBackgroundImage:@[[UIImage ImageForColor:COLOR_EEEEEE],[UIImage ImageForColor:COLOR_EEEEEE_DARK]] forState:UIControlStateHighlighted];
    [btnLogan addTarget:self action:@selector(contentAction:) forControlEvents:UIControlEventTouchUpInside];
    [centerBackView addSubview:btnLogan];
    [btnLogan mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(lineView4.mas_bottom);
        make.leading.trailing.equalTo(centerBackView);
        make.height.mas_equalTo(DWScale(54));
    }];
    
    UIImageView *loganArrow = [[UIImageView alloc] init];
    loganArrow.image = ImgNamed(@"c_arrow_right_gray");
    [centerBackView addSubview:loganArrow];
    [loganArrow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(btnLogan);
        make.trailing.equalTo(centerBackView).offset(-16);
        make.width.mas_equalTo(DWScale(8));
        make.height.mas_equalTo(DWScale(16));
    }];
    
    UILabel * loganLb = [[UILabel alloc] init];
    loganLb.text = LanguageToolMatch(@"日志上报");
    loganLb.font = FONTN(16);
    loganLb.tkThemetextColors = @[COLOR_11, COLOR_11_DARK];
    [centerBackView addSubview:loganLb];
    [loganLb mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(btnLogan);
        make.leading.equalTo(centerBackView).offset(16);
    }];
}

#pragma mark - Action
- (void)contentAction:(id)sender {
    UIButton *btn = (UIButton *)sender;
    
    if (btn.tag == SERVE_BTN_TAG) {
        //服务协议
        [ZTOOL setupServeAgreement];
    }
    
    if (btn.tag == PRIVACY_BTN_TAG) {
        //隐私政策
        [ZTOOL setupPrivePolicy];
    }
    
    if (btn.tag == SCORE_BTN_TAG) {
        //去评分，跳商店
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:APP_IN_APPLE_STORE_URL] options:@{} completionHandler:nil];
    }
    if (btn.tag == VERSION_BTN_TAG) {
        //检查更新
        [NoaAppUpdateTools getAppUpdateInfoWithShowDefaultTips:YES completion:nil];
    }
    
    if (btn.tag == LOGAN_BTN_TAG) {
        //日志上报
        [HUD showActivityMessage:LanguageToolMatch(@"日志上报")];

        //上传当天日志 日志日期 格式："2018-11-21"
        [IMSDKManager imSdkUploadLoganWith:loganTodaysDate() complete:^(NSError * _Nullable error) {
            if (error) {
                [HUD showMessage:LanguageToolMatch(@"操作失败")];
            }else {
                [HUD showMessage:LanguageToolMatch(@"操作成功")];
            }
        }];

        //上传前一天的日志
        NSDate *todayDate = [NSDate date];
        NSDate *lastDayDate = [NSDate dateWithTimeInterval:-24 * 60 * 60 sinceDate:todayDate];
        NSString *lastDayDateStr = [lastDayDate dateForStringWith:@"yyyy-MM-dd"];
        [IMSDKManager imSdkUploadLoganWith:lastDayDateStr complete:^(NSError * _Nullable error) {
        }];

    }
}

@end
