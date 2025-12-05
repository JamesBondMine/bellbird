//
//  NoaNetworkDetectionTopHeaderView.m
//  NoaChatKit
//
//  Created by phl on 2025/10/15.
//  TODO: 网络检测页面 - 顶部

#import "NoaNetworkDetectionTopHeaderView.h"
#import "NoaNetworkDetectionHandle.h"

@interface NoaNetworkDetectionTopHeaderView ()

@property (nonatomic, strong) NoaNetworkDetectionHandle *dataHandle;

@property (nonatomic, strong) UIImageView *iconImgView;

@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) UILabel *stateLabel;

@property (nonatomic, strong) UILabel *ssoLabel;

@end

@implementation NoaNetworkDetectionTopHeaderView

// MARK: set/get
- (UIImageView *)iconImgView {
    if (!_iconImgView) {
        _iconImgView = [UIImageView new];
        _iconImgView.image = [UIImage imageNamed:@"icon_network_detection_header_already"];
    }
    return _iconImgView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.tkThemetextColors = @[COLOR_11, COLOR_11_DARK];
        _titleLabel.font = FONTM(16);
        _titleLabel.text = LanguageToolMatch(@"网络检测");
    }
    return _titleLabel;
}

- (UILabel *)stateLabel {
    if (!_stateLabel) {
        _stateLabel = [UILabel new];

        // 创建富文本
        [self updateStateLabelText:LanguageToolMatch(@"检测准备就绪，请点击开始检测")
                     currentStatus:self.dataHandle.networkDetectionStatus];
        
        // 支持主题切换
        @weakify(self)
        _stateLabel.tkThemeChangeBlock = ^(id  _Nullable itself, NSUInteger themeIndex) {
            @strongify(self)
            [self updateStateLabelText:self.stateLabel.attributedText.string
                         currentStatus:self.dataHandle.networkDetectionStatus];
        };
    }
    return _stateLabel;
}

- (UILabel *)ssoLabel {
    if (!_ssoLabel) {
        _ssoLabel = [UILabel new];
        _ssoLabel.tkThemetextColors = @[COLOR_5966F2, COLOR_5966F2_DARK];
        _ssoLabel.font = FONTR(12);
        _ssoLabel.textAlignment = NSTextAlignmentCenter;
        _ssoLabel.text = [NSString stringWithFormat:LanguageToolMatch(@"企业号：%@"), self.dataHandle.currentSsoNumber];
    }
    return _ssoLabel;
}

- (instancetype)initWithFrame:(CGRect)frame
                   dataHandle:(NoaNetworkDetectionHandle *)dataHandle {
    self = [super initWithFrame:frame];
    if (self) {
        self.dataHandle = dataHandle;
        [self setupUI];
        [self processData];
    }
    return self;
}

- (void)setupUI {
    self.tkThemebackgroundColors = @[COLOR_F5F6F9, COLOR_11];
    
    [self addSubview:self.iconImgView];
    [self addSubview:self.titleLabel];
    [self addSubview:self.stateLabel];
    if (self.dataHandle.currentSsoNumber && self.dataHandle.currentSsoNumber.length > 0) {
        [self addSubview:self.ssoLabel];
    }
    
    [self.iconImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@32);
        make.centerX.equalTo(self);
        make.width.height.equalTo(@88);
    }];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.iconImgView.mas_bottom).offset(16);
        make.centerX.equalTo(self);
        make.width.greaterThanOrEqualTo(@64);
        make.width.lessThanOrEqualTo(self).offset(-60);
        make.height.equalTo(@22);
    }];
    
    [self.stateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(8);
        make.centerX.equalTo(self);
        make.width.greaterThanOrEqualTo(@64);
        make.width.lessThanOrEqualTo(self).offset(-60);
        make.height.equalTo(@20);
        if (!self.dataHandle.currentSsoNumber || self.dataHandle.currentSsoNumber.length == 0) {
            make.bottom.equalTo(self).offset(-24);
        }
    }];
    
    if (self.dataHandle.currentSsoNumber && self.dataHandle.currentSsoNumber.length > 0) {
        [self.ssoLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.stateLabel.mas_bottom).offset(12);
            make.centerX.equalTo(self);
            make.width.greaterThanOrEqualTo(@123);
            make.width.lessThanOrEqualTo(self).offset(-60);
            make.height.equalTo(@24);
            make.bottom.equalTo(self).offset(-24);
        }];
    }
}

- (void)processData {
    @weakify(self)
    [self.dataHandle.headerViewReloadDataSubject subscribeNext:^(id  _Nullable x) {
        @strongify(self)
        if ([x isKindOfClass:[NSDictionary class]]) {
            NSDictionary *headerStatusDic = x;
            ZNetworkDetectionStatus status = [[headerStatusDic objectForKey:@"status"] intValue];
            NSInteger process = 0;
            if ([headerStatusDic objectForKey:@"process"]) {
                process = [[headerStatusDic objectForKey:@"process"] intValue];
            }
            
            NSString *statusStr = @"";
            NSString *titleStr = @"";
            NSString *topImageName = @"";
            switch (status) {
                case ZNetworkDetectionAlready:
                    statusStr = LanguageToolMatch(@"检测准备就绪，请点击开始检测");
                    titleStr = LanguageToolMatch(@"网络检测");
                    topImageName = @"icon_network_detection_header_already";
                    break;
                case ZNetworkDetecting:
                    statusStr = [NSString stringWithFormat:LanguageToolMatch(@"已检测 %ld%%..."), process];
                    titleStr = LanguageToolMatch(@"网络检测");
                    topImageName = @"icon_network_detection_header_already";
                    break;
                case ZNetworkDetectFinish: {
                    NSInteger count = [self.dataHandle getAllUnPassSubResultCount];
                    if (count == 0) {
                        statusStr = LanguageToolMatch(@"完成网络检测，当前网络状况良好");
                        titleStr = LanguageToolMatch(@"网络状态正常");
                        topImageName = @"icon_network_detection_header";
                    }else {
                        statusStr = [NSString stringWithFormat:LanguageToolMatch(@"发现 %ld 个异常项"), count];
                        titleStr = LanguageToolMatch(@"网络状态异常");
                        topImageName = @"icon_network_detection_header_error";
                    }
                }
                    break;
                default:
                    break;
            }
            self.titleLabel.text = titleStr;
            self.iconImgView.image = [UIImage imageNamed:topImageName];
            [self updateStateLabelText:statusStr
                         currentStatus:self.dataHandle.networkDetectionStatus];
        }
    }];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // 每次布局变化时重新设置圆角和边框
    if (self.ssoLabel && self.ssoLabel.superview) {
        // 移除旧的 border layer
        NSArray *sublayers = [self.ssoLabel.layer.sublayers copy];
        for (CALayer *layer in sublayers) {
            if ([layer isKindOfClass:[CAShapeLayer class]]) {
                [layer removeFromSuperlayer];
            }
        }
        
        // 重新设置圆角和边框
        [self configCornerRect:UIRectCornerAllCorners 
                        radius:32.0 
                          rect:self.ssoLabel.bounds 
                       forView:self.ssoLabel];
    }
}

/// 将控件画圆角并添加边框
/// - Parameters:
///   - corners: 哪个角绘制圆角
///   - cornerRadius: 半径
///   - rect: 控件的frame
///   - view: 需要设置圆角和边框的视图
- (void)configCornerRect:(UIRectCorner)corners
                  radius:(CGFloat)cornerRadius
                    rect:(CGRect)rect
                 forView:(UIView *)view {
    // 创建圆角路径
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:rect
                                                   byRoundingCorners:corners
                                                         cornerRadii:CGSizeMake(cornerRadius, cornerRadius)];
    
    // 1. 创建 mask layer 用于裁剪圆角
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.frame = rect;
    maskLayer.path = maskPath.CGPath;
    view.layer.mask = maskLayer;
    
    // 2. 创建 border layer 用于显示边框和填充
    CAShapeLayer *borderLayer = [CAShapeLayer layer];
    borderLayer.frame = rect;
    borderLayer.path = maskPath.CGPath;
    // 边框宽度
    borderLayer.lineWidth = 1;
    // 边框颜色
    borderLayer.strokeColor = COLOR_5966F2.CGColor;
    // 填充颜色
    borderLayer.fillColor = HEXACOLOR(@"4791FF", 0.2).CGColor;
    [view.layer addSublayer:borderLayer];
    
    // 主题变化
    @weakify(borderLayer)
    borderLayer.tkThemeChangeBlock = ^(id  _Nullable itself, NSUInteger themeIndex) {
        @strongify(borderLayer)
        // 边框颜色
        borderLayer.strokeColor = COLOR_5966F2.CGColor;
        // 填充颜色
        borderLayer.fillColor = HEXACOLOR(@"4791FF", 0.2).CGColor;
    };
}

/// 更新 stateLabel 文本（支持暗黑模式，自动高亮数字和%）
/// @param text 要显示的文本，数字和%会自动高亮
- (void)updateStateLabelText:(NSString *)text
               currentStatus:(ZNetworkDetectionStatus)status {
    NSUInteger themeIndex = [TKThemeManager config].themeIndex;
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text];
    
    // 1. 设置整体字体
    [attributedString addAttribute:NSFontAttributeName
                             value:FONTR(14)
                             range:NSMakeRange(0, text.length)];
    
    // 2. 设置整体颜色（根据主题）
    UIColor *normalColor = (themeIndex == 0) ? COLOR_66 : COLOR_66_DARK;
    [attributedString addAttribute:NSForegroundColorAttributeName
                             value:normalColor
                             range:NSMakeRange(0, text.length)];
    
    // 3. 使用正则表达式找到所有"数字+可选的%"，并高亮显示
    NSString *pattern = @"\\d+%?";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                           options:0
                                                                             error:nil];
    
    if (regex) {
        NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:text
                                                                   options:0
                                                                     range:NSMakeRange(0, text.length)];
        
        // 高亮所有匹配到的数字（和可选的%）
        UIColor *highlightColor;
        if (status == ZNetworkDetecting) {
            highlightColor = (themeIndex == 0) ? COLOR_5966F2 : COLOR_5966F2_DARK;
        }else if (status == ZNetworkDetectFinish) {
            highlightColor = (themeIndex == 0) ? COLOR_F93A2F : COLOR_F93A2F_DARK;
        }else {
            // 其他情况暂未有高亮需求
        }
        for (NSTextCheckingResult *match in matches) {
            // 设置高亮颜色
            [attributedString addAttribute:NSForegroundColorAttributeName
                                     value:highlightColor
                                     range:match.range];
            
            // 可选：让数字加粗
            [attributedString addAttribute:NSFontAttributeName
                                     value:FONTB(14)
                                     range:match.range];
        }
    }
    
    self.stateLabel.attributedText = attributedString;
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
