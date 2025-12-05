//
//  NoaTeamListHeaderView.m
//  NoaKit
//
//  Created by phl on 2025/7/21.
//

#import "NoaTeamListHeaderView.h"

@implementation NoaTeamListHeaderInfoItemView

- (void)setTitle:(NSString *)title {
    if (!title) {
        self.titleLabel.text = @"";
        return;
    }
    _title = title;
    self.titleLabel.text = _title;
}

- (void)setCount:(NSString *)count {
    if (!count) {
        self.countLabel.text = @"";
        return;
    }
    _count = count;
    self.countLabel.text = _count;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.tkThemetextColors = @[COLOR_99, COLOR_99_DARK];
        _titleLabel.font = FONTR(12);
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

- (UILabel *)countLabel {
    if (!_countLabel) {
        _countLabel = [UILabel new];
        _countLabel.tkThemetextColors = @[COLOR_11, COLOR_11_DARK];
        _countLabel.font = FONTM(24);
        _countLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _countLabel;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setUpUI];
    }
    return self;
}

- (void)setUpUI {
    [self addSubview:self.countLabel];
    [self addSubview:self.titleLabel];
    
    [self.countLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@16);
        make.leading.equalTo(@16);
        make.trailing.equalTo(self).offset(-16);
        make.height.equalTo(@31);
    }];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.countLabel.mas_bottom);
        make.leading.equalTo(@16);
        make.trailing.equalTo(self).offset(-16);
        make.height.equalTo(@17);
        make.bottom.equalTo(self).offset(-16);
    }];
}

@end


@interface NoaTeamListHeaderView()

/// 左上方标题(团队总数据)
@property (nonatomic, strong) UILabel *titleLabel;

/// 背景图
@property (nonatomic, strong) UIImageView *bgImg;

/// 昨日邀请
@property (nonatomic, strong) NoaTeamListHeaderInfoItemView *yesterdayItemView;

/// 今日邀请
@property (nonatomic, strong) NoaTeamListHeaderInfoItemView *todayItemView;

/// 本月邀请
@property (nonatomic, strong) NoaTeamListHeaderInfoItemView *monthItemView;

/// 底部label(我创建的团队)
@property (nonatomic, strong) UILabel *bottomLabel;

@end

@implementation NoaTeamListHeaderView

- (void)dealloc {
    CIMLog(@"%@ dealloc", [self class]);
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.tkThemetextColors = @[COLOR_11, COLOR_11_DARK];
        _titleLabel.font = FONTM(18);
        _titleLabel.text = LanguageToolMatch(@"团队总数据");
    }
    return _titleLabel;
}

- (UIImageView *)bgImg {
    if (!_bgImg) {
        _bgImg = [UIImageView new];
        // 左侧占用12个单位像素(阿拉伯语语波斯语在右侧)
        if ([ZLanguageTOOL.currentLanguage.languageName_zn isEqualToString:@"阿拉伯语"] ||
            [ZLanguageTOOL.currentLanguage.languageName_zn isEqualToString:@"波斯语"]) {
            _bgImg.image = [UIImage imageNamed:@"team_list_top_team_data_rtl_bgImg"];
        } else {
            _bgImg.image = [UIImage imageNamed:@"team_list_top_team_data_bgImg"];
        }
        _bgImg.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _bgImg;
}

- (NoaTeamListHeaderInfoItemView *)yesterdayItemView {
    if (!_yesterdayItemView) {
        _yesterdayItemView = [[NoaTeamListHeaderInfoItemView alloc] initWithFrame:CGRectZero];
        _yesterdayItemView.title = LanguageToolMatch(@"昨日邀请");
        // 默认0
        _yesterdayItemView.count = @"0";
    }
    return _yesterdayItemView;
}

- (NoaTeamListHeaderInfoItemView *)todayItemView {
    if (!_todayItemView) {
        _todayItemView = [[NoaTeamListHeaderInfoItemView alloc] initWithFrame:CGRectZero];
        _todayItemView.title = LanguageToolMatch(@"今日邀请");
        // 默认0
        _todayItemView.count = @"0";
    }
    return _todayItemView;
}

- (NoaTeamListHeaderInfoItemView *)monthItemView {
    if (!_monthItemView) {
        _monthItemView = [[NoaTeamListHeaderInfoItemView alloc] initWithFrame:CGRectZero];
        _monthItemView.title = LanguageToolMatch(@"本月邀请");
        // 默认0
        _monthItemView.count = @"0";
    }
    return _monthItemView;
}

- (UILabel *)bottomLabel {
    if (!_bottomLabel) {
        _bottomLabel = [UILabel new];
        _bottomLabel.tkThemetextColors = @[COLOR_11, COLOR_11_DARK];
        _bottomLabel.font = FONTM(16);
        _bottomLabel.text = LanguageToolMatch(@"我创建的团队");
    }
    return _bottomLabel;
}

- (void)setTeamModel:(NoaTeamModel *)teamModel {
    _teamModel = teamModel;
    self.yesterdayItemView.count = [NSString stringWithFormat:@"%ld",(long)teamModel.yesterdayInviteNum];
    self.todayItemView.count = [NSString stringWithFormat:@"%ld",(long)teamModel.todayInviteNum];
    self.monthItemView.count = [NSString stringWithFormat:@"%ld",(long)teamModel.mouthInviteCount];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setUpUI];
    }
    return self;
}

- (void)setUpUI {
    self.backgroundColor = UIColor.clearColor;
    
    [self addSubview:self.bgImg];
    [self.bgImg addSubview:self.titleLabel];
    [self.bgImg addSubview:self.yesterdayItemView];
    [self.bgImg addSubview:self.todayItemView];
    [self.bgImg addSubview:self.monthItemView];
    [self addSubview:self.bottomLabel];
    
    [self.bgImg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@12);
        make.leading.equalTo(self);
        make.width.equalTo(self);
    }];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@17);
        make.leading.equalTo(@16);
        make.height.equalTo(@25);
    }];
    
    [self.yesterdayItemView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@58);
        make.leading.equalTo(self.bgImg);
        make.width.equalTo(self.bgImg).multipliedBy(1.0 / 3.0);
    }];
    
    [self.todayItemView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.yesterdayItemView.mas_trailing);
        make.top.bottom.width.height.equalTo(self.yesterdayItemView);
    }];
    
    [self.monthItemView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.todayItemView.mas_trailing);
        make.top.bottom.width.height.equalTo(self.todayItemView);
    }];
    
    [self.bottomLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@178);
        make.leading.equalTo(@16);
        make.height.equalTo(@22);
    }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 切圆角
        [self configureBgImgViewLayer];
    });
}

- (void)configureBgImgViewLayer {
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.bounds
                                               byRoundingCorners:UIRectCornerAllCorners
                                                    cornerRadii:CGSizeMake(12, 12)];
    
    // 2. 设置容器视图的阴影
    self.layer.shadowColor = HEXCOLOR(@"A7BBDA").CGColor;
    self.layer.shadowOffset = CGSizeMake(0, 8);
    self.layer.shadowOpacity = 0.2;
    self.layer.shadowRadius = 16;
    self.layer.shadowPath = path.CGPath;
    
    @weakify(self)
    self.tkThemeChangeBlock = ^(id  _Nullable itself, NSUInteger themeIndex) {
        @strongify(self)
        if (themeIndex == 0) {
            self.layer.shadowColor = HEXCOLOR(@"A7BBDA").CGColor;
        } else {
            self.layer.shadowColor = HEXCOLOR(@"3E4652").CGColor;
        }
    };
   
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.path = path.CGPath;
    self.bgImg.layer.mask = maskLayer;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
