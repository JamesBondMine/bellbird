//
//  NoaTeamCreateView.m
//  NoaKit
//
//  Created by phl on 2025/7/21.
//

#import "NoaTeamCreateView.h"
#import "NoaInputTextView.h"
#import "NoaTeamCreateDataHandle.h"
#import "NoaTeamInviteCustomTextField.h"

@interface NoaTeamCreateView()

/// 团队名称标题label
@property (nonatomic, strong) UILabel *teamNameLabel;

/// 团队名称输入
@property (nonatomic, strong) NoaTeamInviteCustomTextField *teamNameInputTF;

/// 邀请码标题label
@property (nonatomic, strong) UILabel *codeLabel;

/// 邀请码输入底部背景view
@property (nonatomic, strong) UIView *codeInputBgView;

/// 邀请码输入
@property (nonatomic, strong) NoaTeamInviteCustomTextField *codeInputTF;

/// 邀请码输入右侧分割线
@property (nonatomic, strong) UIView *codeInputDividingLine;

/// 随机生成验证码按钮
@property (nonatomic, strong) UIButton *randomGenerationButton;

/// 邀请码错误提示label
@property (nonatomic, strong) UILabel *codeErrorTipLabel;

/// 是否置顶文案
@property (nonatomic, strong) UILabel *topTipLabel;

/// 是否置顶开关
@property (nonatomic, strong) UISwitch *topSwitch;

/// 保存按钮
@property (nonatomic, strong) UIButton *saveButton;

/// 创建团队处理类
@property (nonatomic, strong) NoaTeamCreateDataHandle *teamListDataHandle;

/// 验证码边框(异常红色，其余情况与codeInputBgView颜色一致)
@property (nonatomic, strong) CAShapeLayer *codeInputBgLayer;

@end

@implementation NoaTeamCreateView

- (void)dealloc {
    CIMLog(@"%@ dealloc", [self class]);
}

- (UILabel *)teamNameLabel {
    if (!_teamNameLabel) {
        _teamNameLabel = [UILabel new];
        _teamNameLabel.tkThemetextColors = @[COLOR_11, COLOR_11_DARK];
        _teamNameLabel.font = FONTR(14);
        _teamNameLabel.text = LanguageToolMatch(@"请输入团队名称");
    }
    return _teamNameLabel;
}

- (NoaTeamInviteCustomTextField *)teamNameInputTF {
    if (!_teamNameInputTF) {
        _teamNameInputTF = [NoaTeamInviteCustomTextField new];
        // 为了适配rtl（阿拉伯、波斯语布局，只能用NSMutableAttributedString）
        NSMutableAttributedString *placeHolderAttStr = [[NSMutableAttributedString alloc] initWithString:LanguageToolMatch(@"请输入团队名称") attributes:@{
            NSForegroundColorAttributeName: COLOR_99
        }];
        _teamNameInputTF.textField.attributedPlaceholder = placeHolderAttStr;
        _teamNameInputTF.textField.font = FONTM(14);
        _teamNameInputTF.textField.tkThemetextColors = @[COLOR_11, COLOR_11_DARK];
        _teamNameInputTF.textField.tkThemebackgroundColors = @[COLORWHITE, COLORWHITE_DARK];
        _teamNameInputTF.isShowClearButton = YES;
        
        // 获取当前首选语言，判断是否为阿拉伯语(ar)或波斯语(fa)
        NSString *preferredLanguage = [NSLocale preferredLanguages].firstObject;
        BOOL isArabic = [preferredLanguage hasPrefix:@"ar"]; // 阿拉伯语代码以"ar"开头
        BOOL isPersian = [preferredLanguage hasPrefix:@"fa"]; // 波斯语代码以"fa"开头
        
        if (isArabic || isPersian) {
            _teamNameInputTF.textField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 0)];
            _teamNameInputTF.textField.leftViewMode = UITextFieldViewModeAlways;
        }else {
            // 左侧占用12个单位像素(阿拉伯语语波斯语在右侧)
            if ([ZLanguageTOOL.currentLanguage.languageName_zn isEqualToString:@"阿拉伯语"] ||
                [ZLanguageTOOL.currentLanguage.languageName_zn isEqualToString:@"波斯语"]) {
                _teamNameInputTF.textField.rightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 0)];
                _teamNameInputTF.textField.rightViewMode = UITextFieldViewModeAlways;
            }   else {
                _teamNameInputTF.textField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 0)];
                _teamNameInputTF.textField.leftViewMode = UITextFieldViewModeAlways;
            }
        }
    }
    return _teamNameInputTF;
}

- (UILabel *)codeLabel {
    if (!_codeLabel) {
        _codeLabel = [UILabel new];
        _codeLabel.tkThemetextColors = @[COLOR_11, COLOR_11_DARK];
        _codeLabel.font = FONTR(14);
        _codeLabel.text = LanguageToolMatch(@"请输入邀请码");
    }
    return _codeLabel;
}

- (UIView *)codeInputBgView {
    if (!_codeInputBgView) {
        _codeInputBgView = [UIView new];
        _codeInputBgView.tkThemebackgroundColors = @[COLORWHITE, COLORWHITE_DARK];
    }
    return _codeInputBgView;
}

- (NoaTeamInviteCustomTextField *)codeInputTF {
    if (!_codeInputTF) {
        _codeInputTF = [NoaTeamInviteCustomTextField new];
        // 为了适配rtl（阿拉伯、波斯语布局，只能用NSMutableAttributedString）
        NSMutableAttributedString *placeHolderAttStr = [[NSMutableAttributedString alloc] initWithString:LanguageToolMatch(@"请输入邀请码") attributes:@{
            NSForegroundColorAttributeName: COLOR_99
        }];
        _codeInputTF.textField.attributedPlaceholder = placeHolderAttStr;
        _codeInputTF.isShowClearButton = YES;
        _codeInputTF.textField.font = FONTM(14);
        _codeInputTF.textField.tkThemetextColors = @[COLOR_11, COLOR_11_DARK];
    }
    return _codeInputTF;
}

- (UIView *)codeInputDividingLine {
    if (!_codeInputDividingLine) {
        _codeInputDividingLine = [UIView new];
        _codeInputDividingLine.tkThemebackgroundColors = @[COLOR_EEEEEE, COLOR_EEEEEE_DARK];
    }
    return _codeInputDividingLine;
}

- (UIButton *)randomGenerationButton {
    if (!_randomGenerationButton) {
        _randomGenerationButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_randomGenerationButton setTitle:LanguageToolMatch(@"随机生成") forState:UIControlStateNormal];
        [_randomGenerationButton setTitleColor:COLOR_5966F2 forState:UIControlStateNormal];
        _randomGenerationButton.titleLabel.font = FONTR(14);
        _randomGenerationButton.titleLabel.tkThemetextColors = @[COLOR_5966F2, COLOR_5966F2_DARK];
        _randomGenerationButton.contentEdgeInsets = UIEdgeInsetsMake(16, 14, 14, 16);
    }
    return _randomGenerationButton;
}

- (UILabel *)codeErrorTipLabel {
    if (!_codeErrorTipLabel) {
        _codeErrorTipLabel = [UILabel new];
        _codeErrorTipLabel.tkThemetextColors = @[COLOR_F93A2F, COLOR_F93A2F_DARK];;
        _codeErrorTipLabel.font = FONTR(12);
        _codeErrorTipLabel.text = LanguageToolMatch(@"邀请码暂时无法使用，请更换其他邀请码");
        // 默认隐藏
        _codeErrorTipLabel.hidden = YES;
    }
    return _codeErrorTipLabel;
}

- (UILabel *)topTipLabel {
    if (!_topTipLabel) {
        _topTipLabel = [UILabel new];
        _topTipLabel.tkThemetextColors = @[COLOR_11, COLOR_11_DARK];
        _topTipLabel.font = FONTR(16);
        _topTipLabel.text = LanguageToolMatch(@"是否设为置顶");
    }
    return _topTipLabel;
}

- (UISwitch *)topSwitch {
    if (!_topSwitch) {
        _topSwitch = [UISwitch new];
        // 开启颜色
        _topSwitch.tkThemeonTintColors = @[COLOR_5966F2, COLOR_5966F2_DARK];
        _topSwitch.tkThemetintColors = @[HEXCOLOR(@"D4D4D4"), HEXCOLOR(@"D4D4D4")];
    }
    return _topSwitch;
}

- (UIButton *)saveButton {
    if (!_saveButton) {
        _saveButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_saveButton setTitle:LanguageToolMatch(@"保存") forState:UIControlStateNormal];
        _saveButton.titleLabel.font = FONTM(16);
        _saveButton.titleLabel.tkThemetextColors = @[COLORWHITE, COLORWHITE];
        _saveButton.tkThemebackgroundColors = @[COLOR_5966F2, COLOR_5966F2_DARK];
        _saveButton.enabled = NO;
        _saveButton.alpha = 0.5;
    }
    return _saveButton;
}

- (instancetype)initWithFrame:(CGRect)frame
         TeamCreateDataHandle:(NoaTeamCreateDataHandle *)dataHandle {
    self = [super initWithFrame:frame];
    if (self) {
        self.teamListDataHandle = dataHandle;
        [self setupUI];
        [self processData];
    }
    return self;
}

- (void)setupUI {
    // 背景图片
    UIImageView *bgImageView = [UIImageView new];
    bgImageView.image = [UIImage imageNamed:@"team_list_top_bgImg"];
    [self addSubview:bgImageView];
    [bgImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    
    
    // 团队名称
    [self addSubview:self.teamNameLabel];
    [self addSubview:self.teamNameInputTF];
    
    // 验证码
    [self addSubview:self.codeLabel];
    [self addSubview:self.codeInputBgView];
    
    [self.codeInputBgView addSubview:self.codeInputTF];
    [self.codeInputBgView addSubview:self.codeInputDividingLine];
    [self.codeInputBgView addSubview:self.randomGenerationButton];
    
    [self addSubview:self.codeErrorTipLabel];
    
    // 是否置顶
    [self addSubview:self.topTipLabel];
    [self addSubview:self.topSwitch];
    
    // 保存
    [self addSubview:self.saveButton];
    
    [self.teamNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self).offset(DNavStatusBarH + 24);
        make.leading.equalTo(@16);
        make.height.equalTo(@20);
    }];
    
    [self.teamNameInputTF mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.teamNameLabel.mas_bottom).offset(12);
        make.leading.equalTo(@16);
        make.trailing.equalTo(self).offset(-16);
        make.height.equalTo(@48);
    }];
    
    [self.codeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.teamNameInputTF.mas_bottom).offset(24);
        make.leading.equalTo(@16);
        make.height.equalTo(@20);
    }];
    
    [self.codeInputBgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.codeLabel.mas_bottom).offset(12);
        make.leading.equalTo(@16);
        make.trailing.equalTo(self).offset(-16);
        make.height.equalTo(@48);
    }];
    
    [self.codeInputTF mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(@12);
        make.top.bottom.equalTo(self.codeInputBgView);
    }];
    
    [self.codeInputDividingLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@1);
        make.top.equalTo(@14);
        make.bottom.equalTo(self.codeInputBgView).offset(-14);
        make.leading.equalTo(self.codeInputTF.mas_trailing).offset(10);
    }];
    
    // 计算按钮宽度
    CGFloat randomGenerationButtonWidth = [self calculateButtonWidthForText:self.randomGenerationButton.titleLabel.text font:FONTR(14)];
    [self.randomGenerationButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@(randomGenerationButtonWidth));
        make.leading.equalTo(self.codeInputDividingLine.mas_trailing);
        make.top.trailing.bottom.equalTo(self.codeInputBgView);
    }];
    
    [self.codeErrorTipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.codeInputBgView.mas_bottom).offset(8);
        make.leading.equalTo(@16);
        make.height.equalTo(@17);
    }];
    
    // 这个控件，在不展示验证码错误时，在输入验证码页面下面，在展示验证码错误时，在codeErrorTipLabel下面
    [self.topTipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.codeInputBgView.mas_bottom).offset(24);
        make.leading.equalTo(@16);
        make.height.equalTo(@26);
        make.trailing.equalTo(self.topSwitch.mas_leading).offset(-16);
    }];
    
    [self.topSwitch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.topTipLabel);
        make.height.equalTo(@26);
        make.trailing.equalTo(self).offset(-16);
    }];
    
    [self.saveButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.topTipLabel.mas_bottom).offset(48);
        make.leading.equalTo(@16);
        make.trailing.equalTo(self).offset(-16);
        make.height.equalTo(@48);
    }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 切圆角
        CAShapeLayer *teamNameInputTFLayer = [self configCornerRect:UIRectCornerAllCorners radius:8.0 rect:self.teamNameInputTF.bounds isShowBorder:NO];
        self.teamNameInputTF.layer.mask = teamNameInputTFLayer;
        
        CAShapeLayer *codeInputBgViewLayer = [self configCornerRect:UIRectCornerAllCorners radius:8.0 rect:self.codeInputBgView.bounds isShowBorder:YES];
        self.codeInputBgLayer = codeInputBgViewLayer;
        self.codeInputBgView.layer.mask = codeInputBgViewLayer;
        
        CAShapeLayer *saveButtonLayer = [self configCornerRect:UIRectCornerAllCorners radius:8.0 rect:self.saveButton.bounds isShowBorder:NO];
        self.saveButton.layer.mask = saveButtonLayer;
    });
}

- (void)processData {
    @weakify(self)
    [self.teamListDataHandle.createTeamCommand.executionSignals.switchToLatest subscribeNext:^(id  _Nullable x) {
        @strongify(self)
        BOOL isSuccess = [x boolValue];
        if (!isSuccess) {
            return;
        }
        [self.teamListDataHandle.backSubject sendNext:@1];
    }];
    
    [self.teamListDataHandle.requestRandomCodeCommand.executionSignals.switchToLatest subscribeNext:^(id  _Nullable x) {
        @strongify(self)
        BOOL isSuccess = [x boolValue];
        if (!isSuccess) {
            return;
        }
        self.codeInputTF.textField.text = self.teamListDataHandle.randomCode;
        // 触发self.teamNameInputTF.rac_textSignal
        [self.codeInputTF.textField sendActionsForControlEvents:UIControlEventEditingChanged];
        [self showCodeError:NO];
    }];
    
    // 添加RAC信号处理输入长度限制
    // throttle:用于限制信号发送的频率。在这里，0.1表示信号在0.1秒内最多发送一次
    [[self.teamNameInputTF.textField.rac_textSignal throttle:0.1] subscribeNext:^(NSString *text) {
        @strongify(self)
        [self showCodeError:NO];
        if (text.length > 50) {
            self.teamNameInputTF.textField.text = [text substringToIndex:50];
        }
    }];
    
    [[self.saveButton rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        @strongify(self)
        if (![self.teamListDataHandle validateInviteCode:self.codeInputTF.textField.text]) {
            return;
        }
        NSDictionary *param = @{
            @"teamName": self.teamNameInputTF.textField.text,
            @"code": self.codeInputTF.textField.text,
            @"isTop": self.topSwitch.isOn ? @1 : @0
        };
        [self.teamListDataHandle.createTeamCommand execute:param];
    }];
    
    [[self.randomGenerationButton rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        @strongify(self)
        [self.teamListDataHandle.requestRandomCodeCommand execute:nil];
    }];
    
    [self.teamListDataHandle.showCodeErrorSubject subscribeNext:^(id  _Nullable x) {
        @strongify(self)
        [self showCodeError:YES];
    }];
    
    // 监听两个输入框的内容变化
    RAC(_saveButton, enabled) = [RACSignal
                                 combineLatest:@[
        self.teamNameInputTF.textField.rac_textSignal,
        self.codeInputTF.textField.rac_textSignal]
                                 reduce:^(NSString *teamName, NSString *code) {
        @strongify(self)
        BOOL isEnable = (teamName.length > 0 && code.length > 0);
        if (isEnable) {
            self.saveButton.alpha = 1;
        }else {
            self.saveButton.alpha = 0.5;
        }
        return @(isEnable);
    }];
}

- (void)showCodeError:(BOOL)isShow {
    if (isShow) {
        if (self.codeErrorTipLabel.hidden == NO) {
            return;
        }
        self.codeErrorTipLabel.hidden = NO;
        // 这个控件，在不展示验证码错误时，在输入验证码页面下面，在展示验证码错误时，在codeErrorTipLabel下面
        [self.topTipLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.codeErrorTipLabel.mas_bottom).offset(24);
            make.leading.equalTo(@16);
            make.height.equalTo(@26);
            make.trailing.equalTo(self.topSwitch.mas_leading).offset(-16);
        }];
        
        self.codeInputBgLayer.strokeColor = COLOR_F93A2F.CGColor;
        @weakify(self)
        self.codeInputBgLayer.tkThemeChangeBlock = ^(id  _Nullable itself, NSUInteger themeIndex) {
            @strongify(self)
            if (themeIndex == 0) {
                self.codeInputBgLayer.strokeColor = COLOR_F93A2F.CGColor;
            } else {
                self.codeInputBgLayer.strokeColor = COLOR_F93A2F_DARK.CGColor;
            }
        };
    }else {
        if (self.codeErrorTipLabel.hidden == YES) {
            return;
        }
        self.codeErrorTipLabel.hidden = YES;
        // 这个控件，在不展示验证码错误时，在输入验证码页面下面，在展示验证码错误时，在codeErrorTipLabel下面
        [self.topTipLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.codeInputBgView.mas_bottom).offset(24);
            make.leading.equalTo(@16);
            make.height.equalTo(@26);
            make.trailing.equalTo(self.topSwitch.mas_leading).offset(-16);
        }];
        
        self.codeInputBgLayer.strokeColor = COLORWHITE.CGColor;
        @weakify(self)
        self.codeInputBgLayer.tkThemeChangeBlock = ^(id  _Nullable itself, NSUInteger themeIndex) {
            @strongify(self)
            if (themeIndex == 0) {
                self.codeInputBgLayer.strokeColor = COLORWHITE.CGColor;
            } else {
                self.codeInputBgLayer.strokeColor = COLORWHITE_DARK.CGColor;
            }
        };
    }
}

/// 将控件画圆角
/// - Parameters:
///   - corners: 哪个角绘制圆角
///   - cornerRadius: 半径
///   - rect: 控件的frame
- (CAShapeLayer *)configCornerRect:(UIRectCorner)corners
                            radius:(CGFloat)cornerRadius
                              rect:(CGRect)rect
                      isShowBorder:(BOOL)isShowBorder {
    //  创建圆角路径
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:rect
                                                   byRoundingCorners:corners
                                                         cornerRadii:CGSizeMake(cornerRadius, cornerRadius)];
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.frame = rect;
    maskLayer.path = maskPath.CGPath;
    
    if (!isShowBorder) {
        return maskLayer;
    }
    // 边框相关设置
    maskLayer.lineWidth = 1;
    maskLayer.strokeColor = COLORWHITE.CGColor;
    maskLayer.fillColor = COLORWHITE.CGColor;
    @weakify(maskLayer)
    maskLayer.tkThemeChangeBlock = ^(id  _Nullable itself, NSUInteger themeIndex) {
        @strongify(maskLayer)
        if (themeIndex == 0) {
            maskLayer.strokeColor = COLORWHITE.CGColor;
            maskLayer.fillColor = COLORWHITE.CGColor;
        } else {
            maskLayer.strokeColor = COLORWHITE_DARK.CGColor;
            maskLayer.fillColor = COLORWHITE_DARK.CGColor;
        }
    };
    
    return maskLayer;
}

/// MARK: 计算按钮长度
/// 计算文本宽度的方法
- (CGFloat)calculateButtonWidthForText:(NSString *)text font:(UIFont *)font {
    NSDictionary *attributes = @{NSFontAttributeName: font};
    CGSize size = [text sizeWithAttributes:attributes];
    CGFloat textWidth = size.width + 35; // 左右各16的内边距,多余出来一点
    return MIN(textWidth, 150); // 最大不超过150
}


/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect {
 // Drawing code
 }
 */

@end
