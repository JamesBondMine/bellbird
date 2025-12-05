//
//  NoaMyQRCodeViewController.m
//  NoaKit
//
//  Created by Mac on 2023/4/3.
//

#import "NoaMyQRCodeViewController.h"
#import "NoaBaseImageView.h"
#import "UIImage+YYImageHelper.h"
#import "NoaChatMultiSelectViewController.h"
#import "NoaMyQRCodeView.h"

@interface NoaMyQRCodeViewController ()

/// 全屏背景
@property (nonatomic, strong) UIImageView *bgImgView;

/// 二维码底部透明view
@property (nonatomic, strong) UIView *bgView;

/// 二维码图片
@property (nonatomic, strong) NoaBaseImageView *qrcodeImgView;

/// 二维码背景图
@property (nonatomic, strong) NoaMyQRCodeView *qrCodeView;

/// 头像容器视图（用于渐变边框）
@property (nonatomic, strong) UIView *avatarContainer;

/// 渐变图层
@property (nonatomic, strong) CAGradientLayer *gradientLayer;

/// 遮罩图层
@property (nonatomic, strong) CAShapeLayer *maskLayer;

@end

@implementation NoaMyQRCodeViewController

// MARK: Get/Set
- (UIImageView *)bgImgView {
    if (!_bgImgView) {
        _bgImgView = [[UIImageView alloc] initWithImage:ImgNamed(@"g_qrcode_bgiew")];
    }
    return _bgImgView;
}

- (UIView *)bgView {
    if (!_bgView) {
        _bgView = [[UIView alloc] initWithFrame:CGRectZero];
        _bgView.backgroundColor = UIColor.clearColor;
    }
    return _bgView;
}

- (NoaMyQRCodeView *)qrCodeView {
    if (!_qrCodeView) {
        _qrCodeView = [[NoaMyQRCodeView alloc] initWithFrame:CGRectZero];
    }
    return _qrCodeView;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.tkThemebackgroundColors = @[COLOR_F5F6F9, COLOR_11];
    [self setupNavUI];
    [self setupUI];
}

#pragma mark - 界面布局
- (void)setupNavUI {
    self.navTitleStr = LanguageToolMatch(@"我的二维码");
    self.navBtnRight.hidden = YES;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // 更新渐变图层和遮罩层的 frame
    if (self.avatarContainer && self.gradientLayer && self.maskLayer) {
        CGRect containerBounds = self.avatarContainer.bounds;
        if (!CGRectIsEmpty(containerBounds)) {
            // 更新渐变图层 frame
            self.gradientLayer.frame = containerBounds;
            
            // 更新遮罩层路径
            CGFloat centerX = CGRectGetMidX(containerBounds);
            CGFloat centerY = CGRectGetMidY(containerBounds);
            CGFloat radius = containerBounds.size.width / 2.0;
            CGFloat borderWidth = 2.11;
            
            UIBezierPath *outerPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(centerX, centerY)
                                                                      radius:radius
                                                                  startAngle:0
                                                                    endAngle:M_PI * 2
                                                                   clockwise:YES];
            UIBezierPath *innerPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(centerX, centerY)
                                                                      radius:radius - borderWidth
                                                                  startAngle:0
                                                                    endAngle:M_PI * 2
                                                                   clockwise:YES];
            [outerPath appendPath:innerPath];
            [outerPath setUsesEvenOddFillRule:YES];
            self.maskLayer.path = outerPath.CGPath;
        }
    }
}

- (void)setupUI {
    [self.view addSubview:self.bgImgView];
    [self.bgImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.view);
    }];
    
    [self.view addSubview:self.bgView];
    [self.bgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(37.5);
        make.trailing.mas_equalTo(-37.5);
        make.top.mas_equalTo(self.navView.mas_bottom).offset(34.5);
        make.bottom.mas_equalTo(-(80 + DHomeBarH));
    }];
    
    [self.bgView addSubview:self.qrCodeView];
    [self.qrCodeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(@22.5);
        make.leading.trailing.bottom.equalTo(self.bgView);
    }];
    
    // 创建头像容器视图（用于渐变边框）
    self.avatarContainer = [UIView new];
    self.avatarContainer.backgroundColor = UIColor.clearColor;
    [self.bgView addSubview:self.avatarContainer];
    [self.avatarContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(0);
        make.centerX.mas_equalTo(self.bgView);
        make.size.mas_equalTo(CGSizeMake(80, 80));
    }];
    
    // 创建渐变图层
    self.gradientLayer = [CAGradientLayer layer];
    // 渐变方向：360deg 表示从上到下（在 iOS 中，0 度是从上到下）
    self.gradientLayer.startPoint = CGPointMake(0.5, 0); // 顶部
    self.gradientLayer.endPoint = CGPointMake(0.5, 1);   // 底部
    // 渐变颜色：从 #76ADFF 到 #FF33E7
    self.gradientLayer.colors = @[
        (__bridge id)HEXCOLOR(@"FF33E7").CGColor, // #76ADFF
        (__bridge id)HEXCOLOR(@"76ADFF").CGColor   // #FF33E7
    ];
    self.gradientLayer.cornerRadius = 40;
    [self.avatarContainer.layer addSublayer:self.gradientLayer];
    
    // 创建遮罩层，只显示边框部分（圆环）
    self.maskLayer = [CAShapeLayer layer];
    self.maskLayer.fillRule = kCAFillRuleEvenOdd;
    self.gradientLayer.mask = self.maskLayer;
    
    // 创建头像视图
    NoaBaseImageView *userAvatar = [NoaBaseImageView new];
    userAvatar.backgroundColor = UIColor.clearColor;
    CGFloat avatarSize = 80 - 2.11 * 2;
    CGFloat avatarRadius = 40 - 2.11;
    [userAvatar rounded:avatarRadius];
    [userAvatar sd_setImageWithURL:[UserManager.userInfo.avatar getImageFullUrl] placeholderImage:DefaultAvatar options:SDWebImageAllowInvalidSSLCertificates];
    [self.avatarContainer addSubview:userAvatar];
    [userAvatar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.avatarContainer);
        make.size.mas_equalTo(CGSizeMake(avatarSize, avatarSize));
    }];
    
    UILabel *userNameLabel = [UILabel new];
    userNameLabel.font = FONTM(16);
    userNameLabel.text = [NSString stringWithFormat:@"%@", UserManager.userInfo.nickname];
    userNameLabel.tkThemetextColors = @[COLOR_11, COLOR_11_DARK];
    userNameLabel.textAlignment = NSTextAlignmentCenter;
    [self.bgView addSubview:userNameLabel];
    [userNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(16);
        make.trailing.mas_equalTo(-16);
        make.top.equalTo(userAvatar.mas_bottom).offset(10);
        make.height.mas_equalTo(22);
    }];
    
    UILabel *accountLbl = [UILabel new];
    accountLbl.font = FONTR(14);
    accountLbl.text = [NSString stringWithFormat:LanguageToolMatch(@"账号:%@"), UserManager.userInfo.userName];
    accountLbl.tkThemetextColors = @[COLOR_66,COLOR_66_DARK];
    accountLbl.textAlignment = NSTextAlignmentCenter;
    [self.bgView addSubview:accountLbl];
    [accountLbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(userNameLabel);
        make.top.equalTo(userNameLabel.mas_bottom).offset(3);
        make.height.mas_equalTo(20);
    }];
    
    UIImageView *codeBgview =[[UIImageView alloc] initWithImage:ImgNamed(@"mine_qr_bg")];
    [self.bgView addSubview:codeBgview];
    [codeBgview mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.bgView);
        make.top.mas_equalTo(accountLbl.mas_bottom).offset(40);
        make.leading.equalTo(@40);
        make.trailing.equalTo(self.bgView).offset(-40);
        make.height.equalTo(codeBgview.mas_width); // 正方形：宽度等于高度
    }];
    
    _qrcodeImgView = [NoaBaseImageView new] ;
    UIImage *qrcodeImage = [UIImage getQRCodeImageWithString:self.qrcodeContent qrCodeColor:COLOR_00 inputCorrectionLevel:QRCodeInputCorrectionLevel_M];
    _qrcodeImgView.image = qrcodeImage;
    [codeBgview addSubview:_qrcodeImgView];
    [_qrcodeImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.top.mas_equalTo(codeBgview).offset(23.5);
        make.trailing.bottom.mas_equalTo(codeBgview).offset(-24);
        make.height.equalTo(_qrcodeImgView.mas_width); // 正方形：宽度等于高度
    }];
    
    UIView *line = [UIView new];
    line.tkThemebackgroundColors = @[COLOR_EEF1FA, COLOR_EEF1FA_DARK];
    [self.bgView addSubview:line];
    [line mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(codeBgview.mas_bottom).offset(22);
        make.leading.mas_equalTo(27.5);
        make.trailing.mas_equalTo(-27.5);
        make.height.mas_equalTo(1);
    }];
    
    UILabel *tipLbl1 = [UILabel new];
    tipLbl1.font = FONTR(14);
    tipLbl1.text = LanguageToolMatch(@"扫一扫我的二维码，添加我为好友。");
    tipLbl1.tkThemetextColors = @[COLOR_11, COLOR_11_DARK];
    tipLbl1.textAlignment = NSTextAlignmentCenter;
    tipLbl1.numberOfLines = 0;
    [self.bgView addSubview:tipLbl1];
    [tipLbl1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(line.mas_bottom).offset(24);
        make.leading.mas_equalTo(35);
        make.trailing.mas_equalTo(-35);
        make.bottom.equalTo(self.bgView.mas_bottom).offset(-24);
    }];
    
    //保存相册
    UIButton *savePhotoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [savePhotoBtn setBackgroundColor:[UIColor whiteColor]];
    savePhotoBtn.layer.cornerRadius = 21;
    savePhotoBtn.clipsToBounds = YES;
    [savePhotoBtn setImage:ImgNamed(@"g_savephoto_logo") forState:UIControlStateNormal];
    [savePhotoBtn setTitle:LanguageToolMatch(@"保存相册") forState:UIControlStateNormal];
    [savePhotoBtn setTkThemeTitleColor:@[COLOR_11, COLOR_11] forState:UIControlStateNormal];
    [savePhotoBtn addTarget:self action:@selector(savePhotoBtnAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:savePhotoBtn];
    [savePhotoBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.bgView.mas_bottom).offset(16);
        make.leading.mas_equalTo(self.view).offset(37.5);
        make.trailing.mas_equalTo(self.view.mas_centerX).offset(-10);
        make.height.mas_equalTo(52);
    }];
    
    //分享二维码
    UIButton *shanerQRBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [shanerQRBtn setTkThemebackgroundColors:@[COLOR_5966F2, COLOR_5966F2_DARK]];
    shanerQRBtn.layer.cornerRadius = 21;
    shanerQRBtn.clipsToBounds = YES;
    [shanerQRBtn setImage:ImgNamed(@"g_share_logo") forState:UIControlStateNormal];
    [shanerQRBtn setTitle:LanguageToolMatch(@"分享") forState:UIControlStateNormal];
    [shanerQRBtn setTkThemeTitleColor:@[COLORWHITE, COLORWHITE] forState:UIControlStateNormal];
    [shanerQRBtn addTarget:self action:@selector(shareQRcodeBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:shanerQRBtn];
    [shanerQRBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(savePhotoBtn);
        make.trailing.equalTo(self.view).offset(-37.5);
        make.leading.mas_equalTo(self.view.mas_centerX).offset(10);
        make.height.mas_equalTo(52);
    }];
}

- (void)savePhotoBtnAction {
    UIGraphicsBeginImageContextWithOptions(self.bgView.bounds.size, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self.bgView.layer renderInContext:context];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    //保存到相册
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(imageSavedToPhotosAlbum:didFinishSavingWithError:contextInfo:), nil);
}

- (void)shareQRcodeBtnClick {
    UIGraphicsBeginImageContextWithOptions(self.bgView.bounds.size, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self.bgView.layer renderInContext:context];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //分享二维码
    NoaChatMultiSelectViewController *vc = [NoaChatMultiSelectViewController new];
    vc.multiSelectType = ZMultiSelectTypeShareQRImg;
    vc.fromSessionId = @"";
    vc.qrCodeImg = image;
    [self.navigationController pushViewController:vc animated:YES];
}
 
- (void)imageSavedToPhotosAlbum:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    NSString *message = nil;
    if (!error) {
        message = LanguageToolMatch(@"已保存至相册");
    } else {
        message = [error description];
    }
    [HUD showMessage:message];
}

@end
