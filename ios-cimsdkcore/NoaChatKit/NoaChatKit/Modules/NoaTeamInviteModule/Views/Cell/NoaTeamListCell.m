//
//  NoaTeamListCell.m
//  NoaKit
//
//  Created by phl on 2025/7/21.
//

#import "NoaTeamListCell.h"

@interface NoaTeamListCell()

@property (nonatomic, strong) UIView *bgView;

/// 置顶label(使用UIButton,主要是为了内边距)
@property (nonatomic, strong) UIButton *topStateButton;

/// 团队名称label
@property (nonatomic, strong) UILabel *teamNameLabel;

/// 邀请码label
@property (nonatomic, strong) UILabel *teamInviteCodeLabel;

/// 复制邀请码button
@property (nonatomic, strong) UIButton *codeCopyButton;

/// 右侧箭头
@property (nonatomic, strong) UIImageView *rightArrowImageView;

@end

@implementation NoaTeamListCell

- (void)setTeamModel:(NoaTeamModel *)teamModel {
    if (!teamModel) {
        return;
    }
    _teamModel = teamModel;
    
    // 团队名称
    NSString *teamName = [NSString isNil:_teamModel.teamName] ? @"" : _teamModel.teamName;
    NSInteger teamCount = _teamModel.totalInviteNum;
    NSString *title = [NSString stringWithFormat:@"%@(%ld)", teamName, teamCount];
    self.teamNameLabel.text = title;
    
    // 邀请码
    NSString *inviteCode = [NSString isNil:_teamModel.inviteCode] ? @"" : _teamModel.inviteCode;
    self.teamInviteCodeLabel.text = [NSString stringWithFormat:@"%@：%@", LanguageToolMatch(@"邀请码"), inviteCode];
}

- (UIView *)bgView {
    if (!_bgView) {
        _bgView = [UIView new];
        _bgView.tkThemebackgroundColors = @[COLORWHITE, COLORWHITE_DARK];
    }
    return _bgView;
}

- (UIButton *)topStateButton {
    if (!_topStateButton) {
        _topStateButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_topStateButton setTitle:LanguageToolMatch(@"已置顶") forState:UIControlStateNormal];
        _topStateButton.titleLabel.font = FONTR(11);
        [_topStateButton setTitleColor:COLOR_5966F2 forState:UIControlStateNormal];
        _topStateButton.titleLabel.tkThemetextColors = @[COLOR_5966F2, COLOR_5966F2_DARK];
        _topStateButton.tkThemebackgroundColors = @[HEXACOLOR(@"4791FF", 0.2), HEXACOLOR(@"4791FF", 0.2)];
        _topStateButton.titleEdgeInsets = UIEdgeInsetsMake(0, 16, 0, 16);
        _topStateButton.userInteractionEnabled = NO;
    }
    return _topStateButton;
}

- (UILabel *)teamNameLabel {
    if (!_teamNameLabel) {
        _teamNameLabel = [UILabel new];
        _teamNameLabel.tkThemetextColors = @[COLOR_11, COLOR_11_DARK];
        _teamNameLabel.font = FONTM(14);
    }
    return _teamNameLabel;
}

- (UILabel *)teamInviteCodeLabel {
    if (!_teamInviteCodeLabel) {
        _teamInviteCodeLabel = [UILabel new];
        _teamInviteCodeLabel.tkThemetextColors = @[COLOR_66, COLOR_66_DARK];
        _teamInviteCodeLabel.font = FONTR(14);
    }
    return _teamInviteCodeLabel;
}

- (UIButton *)codeCopyButton {
    if (!_codeCopyButton) {
        _codeCopyButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_codeCopyButton setImage:[UIImage imageNamed:@"team_invite_code_copy"] forState:UIControlStateNormal];
    }
    return _codeCopyButton;
}

- (UIImageView *)rightArrowImageView {
    if (!_rightArrowImageView) {
        _rightArrowImageView = [UIImageView new];
        _rightArrowImageView.image = [UIImage imageNamed:@"c_arrow_right_gray"];
    }
    return _rightArrowImageView;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self setUpUI];
    }
    return self;
}

- (void)setUpUI {
    self.backgroundColor = UIColor.clearColor;
    
    [self.contentView addSubview:self.bgView];
    [self.bgView addSubview:self.topStateButton];
    [self.bgView addSubview:self.teamNameLabel];
    [self.bgView addSubview:self.teamInviteCodeLabel];
    [self.bgView addSubview:self.codeCopyButton];
    [self.contentView addSubview:self.rightArrowImageView];
    
    [self.bgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@4);
        make.leading.equalTo(@16);
        make.trailing.equalTo(self.contentView).offset(-16);
        make.bottom.equalTo(self.contentView).offset(-4);
    }];
    
    [self.topStateButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.top.equalTo(self.bgView);
        make.height.equalTo(@20);
        make.width.greaterThanOrEqualTo(@65);
    }];
    
    [self.teamNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@28);
        make.leading.equalTo(@16);
        make.height.equalTo(@20);
        make.trailing.equalTo(self.rightArrowImageView).offset(-16);
    }];
    
    [self.teamInviteCodeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.teamNameLabel.mas_bottom).offset(4);
        make.leading.equalTo(self.teamNameLabel);
        make.height.equalTo(@20);
        make.width.greaterThanOrEqualTo(@65);
    }];
    
    [self.codeCopyButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.teamInviteCodeLabel);
        make.leading.equalTo(self.teamInviteCodeLabel.mas_trailing).offset(4);
        make.width.height.equalTo(@20);
    }];
    
    [self.rightArrowImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView);
        make.trailing.equalTo(self.contentView).offset(-28);
        make.width.equalTo(@7);
        make.height.equalTo(@14);
    }];
    
    @weakify(self)
    [[self.codeCopyButton rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        @strongify(self)
        // 复制团队邀请码
        if (![NSString isNil:self.teamInviteCodeLabel.text]) {
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.string = self.teamModel.inviteCode;
            [HUD showMessage:LanguageToolMatch(@"复制成功")];
        }
    }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 切圆角
        CAShapeLayer *topLabelLayer;
        if ([ZLanguageTOOL.currentLanguage.languageName_zn isEqualToString:@"阿拉伯语"] ||
            [ZLanguageTOOL.currentLanguage.languageName_zn isEqualToString:@"波斯语"]) {
            topLabelLayer = [self configCornerRect:UIRectCornerTopRight | UIRectCornerBottomLeft radius:10.0 rect:self.topStateButton.bounds];
        } else {
            topLabelLayer = [self configCornerRect:UIRectCornerTopLeft | UIRectCornerBottomRight radius:10.0 rect:self.topStateButton.bounds];
        }
        self.topStateButton.layer.mask = topLabelLayer;
        
        CAShapeLayer *bgViewLayer = [self configCornerRect:UIRectCornerAllCorners radius:12.0 rect:self.bgView.bounds];
        self.bgView.layer.mask = bgViewLayer;
    });
}

/// 根据用户置顶，展示不同布局
/// - Parameter isTop: 是否是置顶
- (void)changeTopLayout:(BOOL)isTop {
    if (isTop) {
        if (self.topStateButton.isHidden == NO) {
            return;
        }
        self.topStateButton.hidden = NO;
        [self.bgView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@4);
            make.leading.equalTo(@16);
            make.trailing.equalTo(self.contentView).offset(-16);
            make.bottom.equalTo(self.contentView).offset(-4);
            make.height.equalTo(self.contentView).offset(-8);
        }];
        
        [self.topStateButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.top.equalTo(self.bgView);
            make.height.equalTo(@20);
            make.width.greaterThanOrEqualTo(@65);
        }];
        
        [self.teamNameLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@28);
            make.leading.equalTo(@16);
            make.height.equalTo(@20);
            make.trailing.equalTo(self.rightArrowImageView).offset(-16);
        }];
    }else {
        if (self.topStateButton.isHidden == YES) {
            return;
        }
        self.topStateButton.hidden = YES;
        
        [self.bgView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@4);
            make.leading.equalTo(@16);
            make.trailing.equalTo(self.contentView).offset(-16);
            make.bottom.equalTo(self.contentView).offset(-4);
            make.height.equalTo(self.contentView).offset(-8);
        }];
        
        [self.teamNameLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@16);
            make.leading.equalTo(@16);
            make.height.equalTo(@20);
            make.trailing.equalTo(self.rightArrowImageView).offset(-16);
        }];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (CGRectIsEmpty(self.contentView.bounds)) {
        return;
    }
    
    if (!_teamModel) {
        return;
    }
    
    // 是否置顶
    BOOL isTop = _teamModel.isDefaultTeam == 1 ? YES : NO;
    [self changeTopLayout:isTop];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 切圆角
        CAShapeLayer *bgViewLayer = [self configCornerRect:UIRectCornerAllCorners radius:12.0 rect:self.bgView.bounds];
        self.bgView.layer.mask = bgViewLayer;
    });
}

/// 将控件画圆角
/// - Parameters:
///   - corners: 哪个角绘制圆角
///   - cornerRadius: 半径
///   - rect: 控件的frame
- (CAShapeLayer *)configCornerRect:(UIRectCorner)corners
                            radius:(CGFloat)cornerRadius
                              rect:(CGRect)rect {
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:rect
                                                   byRoundingCorners:corners
                                                         cornerRadii:CGSizeMake(cornerRadius, cornerRadius)];
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.frame = rect;
    maskLayer.path = maskPath.CGPath;
    return maskLayer;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

@end
