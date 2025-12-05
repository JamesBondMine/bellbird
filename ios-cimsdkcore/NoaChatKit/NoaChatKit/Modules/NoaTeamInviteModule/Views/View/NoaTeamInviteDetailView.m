//
//  NoaTeamInviteDetailView.m
//  NoaKit
//
//  Created by phl on 2025/7/24.
//

#import "NoaTeamInviteDetailView.h"
#import "NoaTeamListHeaderView.h"
#import "NoaTeamInviteDetailDataHandle.h"
#import "NoaTeamDetailModel.h"

/// 团队邀请-团队详情页面上方视图
typedef void(^ClickAllGroupCountBlock)(void);
@interface NoaTeamInviteTeamDetailTopView : UIView

/// 获取到的团队详情信息
@property (nonatomic, strong) NoaTeamDetailModel *teamDetailModel;

/// 背景图
@property (nonatomic, strong) UIImageView *bgImgView;

/// 团队总人数item
@property (nonatomic, strong) NoaTeamListHeaderInfoItemView *teamAllPeopleCountItemView;

/// 昨日邀请item
@property (nonatomic, strong) NoaTeamListHeaderInfoItemView *yesterdayItemView;

/// 今日邀请item
@property (nonatomic, strong) NoaTeamListHeaderInfoItemView *todayItemView;

/// 本月邀请item
@property (nonatomic, strong) NoaTeamListHeaderInfoItemView *monthItemView;

@property (nonatomic, copy) ClickAllGroupCountBlock clickAllGroupCountBlock;

@end

@implementation NoaTeamInviteTeamDetailTopView

- (UIImageView *)bgImgView {
    if (!_bgImgView) {
        _bgImgView = [UIImageView new];
        _bgImgView.image = [UIImage imageNamed:@"team_detail_top_bgImg"];
        _bgImgView.userInteractionEnabled = YES;
    }
    return _bgImgView;
}

- (NoaTeamListHeaderInfoItemView *)teamAllPeopleCountItemView {
    if (!_teamAllPeopleCountItemView) {
        _teamAllPeopleCountItemView = [[NoaTeamListHeaderInfoItemView alloc] initWithFrame:CGRectZero];
        _teamAllPeopleCountItemView.title = LanguageToolMatch(@"团队成员");
        // 默认0
        _teamAllPeopleCountItemView.count = @"0";
    }
    return _teamAllPeopleCountItemView;
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

- (void)setTeamDetailModel:(NoaTeamDetailModel *)teamDetailModel {
    if (!teamDetailModel) {
        return;
    }
    _teamDetailModel = teamDetailModel;
    // 昨日邀请人数
    self.yesterdayItemView.count = [NSString stringWithFormat:@"%ld", _teamDetailModel.yesterdayInviteNum];
    // 今日邀请人数
    self.todayItemView.count = [NSString stringWithFormat:@"%ld", _teamDetailModel.todayInviteNum];
    // 本月邀请人数
    self.monthItemView.count = [NSString stringWithFormat:@"%ld", _teamDetailModel.mouthInviteCount];
    // 团队总人数
    self.teamAllPeopleCountItemView.count = [NSString stringWithFormat:@"%ld", _teamDetailModel.totalInviteNum];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setUpUI];
    }
    return self;
}

- (void)setUpUI {
    [self addSubview:self.bgImgView];
    [self.bgImgView addSubview:self.teamAllPeopleCountItemView];
    [self.bgImgView addSubview:self.yesterdayItemView];
    [self.bgImgView addSubview:self.todayItemView];
    [self.bgImgView addSubview:self.monthItemView];
    
    [self.bgImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    
    [self.teamAllPeopleCountItemView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.bgImgView);
        make.leading.equalTo(@16);
        make.width.equalTo(self.yesterdayItemView);
    }];
    
    [self.yesterdayItemView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.bgImgView);
        make.leading.equalTo(self.teamAllPeopleCountItemView.mas_trailing).offset(15);
        make.trailing.equalTo(self.bgImgView).offset(-16);
        make.height.equalTo(self.teamAllPeopleCountItemView);
    }];
    
    [self.todayItemView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.teamAllPeopleCountItemView.mas_bottom).offset(-20);
        make.leading.equalTo(@16);
        make.width.equalTo(self.monthItemView);
    }];
    
    [self.monthItemView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.todayItemView);
        make.leading.equalTo(self.todayItemView.mas_trailing).offset(15);
        make.trailing.equalTo(self.bgImgView).offset(-16);
        make.height.equalTo(self.todayItemView);
        make.width.equalTo(self.todayItemView);
    }];
    
    UITapGestureRecognizer *tapGestureRecognizer = [UITapGestureRecognizer new];
    [self.teamAllPeopleCountItemView addGestureRecognizer:tapGestureRecognizer];
    @weakify(self)
    [[tapGestureRecognizer rac_gestureSignal] subscribeNext:^(__kindof UIGestureRecognizer * _Nullable x) {
        @strongify(self)
        if (self.clickAllGroupCountBlock) {
            self.clickAllGroupCountBlock();
        }
    }];
}

@end

typedef void(^ClickCopyButtonActionBlock)(void);
@interface NoaTeamInviteTeamDetailTextView : UIView

/// 需要显示的标题
@property (nonatomic, copy) NSString *title;

/// 需要显示的下方文字内容，一般为邀请码或者链接地址等。
@property (nonatomic, copy) NSString *detailTitle;

/// 顶部标题Label
@property (nonatomic, strong) UILabel *titleLabel;

/// 底部文字+复制按钮的view
@property (nonatomic, strong) UIView *detailTextView;

/// 底部文字Label
@property (nonatomic, strong) UILabel *detailLabel;

/// 复制按钮
@property (nonatomic, strong) UIButton *copybutton;

@property (nonatomic, copy) ClickCopyButtonActionBlock clickCopyButtonActionBlock;

@end

@implementation NoaTeamInviteTeamDetailTextView

- (void)setTitle:(NSString *)title {
    if (!title) {
        self.titleLabel.text = @"";
        return;
    }
    _title = title;
    self.titleLabel.text = _title;
}

- (void)setDetailTitle:(NSString *)detailTitle {
    if (!detailTitle) {
        self.detailLabel.text = @"";
        return;
    }
    _detailTitle = detailTitle;
    self.detailLabel.text = _detailTitle;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.tkThemetextColors = @[COLOR_66, COLOR_99];
        _titleLabel.font = FONTR(12);
    }
    return _titleLabel;
}

- (UIView *)detailTextView {
    if (!_detailTextView) {
        _detailTextView = [UIView new];
        _detailTextView.tkThemebackgroundColors = @[COLOR_F5F6F9, COLOR_F5F6F9_DARK];
    }
    return _detailTextView;
}

- (UILabel *)detailLabel {
    if (!_detailLabel) {
        _detailLabel = [UILabel new];
        _detailLabel.tkThemetextColors = @[COLOR_11, COLOR_11_DARK];
        _detailLabel.font = FONTM(16);
    }
    return _detailLabel;
}

- (UIButton *)copybutton {
    if (!_copybutton) {
        _copybutton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_copybutton setImage:[UIImage imageNamed:@"team_invite_code_copy"] forState:UIControlStateNormal];
    }
    return _copybutton;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setUpUI];
    }
    return self;
}

- (void)setUpUI {
    [self addSubview:self.titleLabel];
    [self addSubview:self.detailTextView];
    [self.detailTextView addSubview:self.detailLabel];
    [self.detailTextView addSubview:self.copybutton];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(@28);
        make.top.equalTo(self);
        make.height.equalTo(@17);
    }];
    
    [self.detailTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(@16);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(8);
        make.trailing.equalTo(self).offset(-16);
        make.height.equalTo(@44);
        make.bottom.equalTo(self);
    }];
    
    [self.detailLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(@16);
        make.top.bottom.equalTo(self.detailTextView);
        make.trailing.equalTo(self.copybutton.mas_leading).offset(-16);
    }];
    
    [self.copybutton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.detailTextView).offset(-16);
        make.centerY.equalTo(self.detailTextView);
        make.width.height.equalTo(@20);
    }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 切圆角
        CAShapeLayer *detailTextViewLayer = [self configCornerRect:UIRectCornerAllCorners radius:8 rect:self.detailTextView.bounds];
        self.detailTextView.layer.mask = detailTextViewLayer;
    });
    
    @weakify(self)
    [[self.copybutton rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        @strongify(self)
        if (self.clickCopyButtonActionBlock) {
            self.clickCopyButtonActionBlock();
        }
    }];
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


@end

/// 团队邀请-团队详情页面下方视图
typedef void(^LongPressQRImageViewActionBlock)(UIImage *image);
@interface NoaTeamInviteTeamDetailBottomView : UIView

/// 获取到的团队详情信息
@property (nonatomic, strong) NoaTeamDetailModel *teamDetailModel;

/// 背景图
@property (nonatomic, strong) UIImageView *bgImgView;

/// 二维码背景
@property (nonatomic, strong) UIView *qrCodeBgView;

/// 二维码
@property (nonatomic, strong) UIImageView *qrCodeImgView;

/// 团队邀请码
@property (nonatomic, strong) NoaTeamInviteTeamDetailTextView *teamInviteCodeView;

/// 下载链接
@property (nonatomic, strong) NoaTeamInviteTeamDetailTextView *teamInviteDownloadLinkView;

/// 长按手势触发
@property (nonatomic, strong) LongPressQRImageViewActionBlock longPressQRImageViewActionBlock;

@end

@implementation NoaTeamInviteTeamDetailBottomView

- (UIImageView *)bgImgView {
    if (!_bgImgView) {
        _bgImgView = [UIImageView new];
        _bgImgView.contentMode = UIViewContentModeScaleAspectFill;
        _bgImgView.image = [UIImage imageNamed:@"team_detail_qrcode_bgImg"];
        _bgImgView.userInteractionEnabled = YES;
    }
    return _bgImgView;
}

- (UIView *)qrCodeBgView {
    if (!_qrCodeBgView) {
        _qrCodeBgView = [UIView new];
    }
    return _qrCodeBgView;
}

- (UIImageView *)qrCodeImgView {
    if (!_qrCodeImgView) {
        _qrCodeImgView = [UIImageView new];
        _qrCodeImgView.userInteractionEnabled = YES;
    }
    return _qrCodeImgView;
}

- (NoaTeamInviteTeamDetailTextView *)teamInviteCodeView {
    if (!_teamInviteCodeView) {
        _teamInviteCodeView = [[NoaTeamInviteTeamDetailTextView alloc] initWithFrame:CGRectZero];
        _teamInviteCodeView.title = LanguageToolMatch(@"团队邀请码");
        _teamInviteCodeView.detailTitle = @"";
        @weakify(self)
        _teamInviteCodeView.clickCopyButtonActionBlock = ^{
            @strongify(self)
            // 复制团队邀请码
            if (![NSString isNil:self.teamDetailModel.inviteCode]) {
                UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                pasteboard.string = self.teamDetailModel.inviteCode;
                [HUD showMessage:LanguageToolMatch(@"复制成功")];
            }
        };
    }
    return _teamInviteCodeView;
}

- (NoaTeamInviteTeamDetailTextView *)teamInviteDownloadLinkView {
    if (!_teamInviteDownloadLinkView) {
        _teamInviteDownloadLinkView = [[NoaTeamInviteTeamDetailTextView alloc] initWithFrame:CGRectZero];
        _teamInviteDownloadLinkView.title = LanguageToolMatch(@"下载链接");
        _teamInviteDownloadLinkView.detailTitle = @"";
        @weakify(self)
        _teamInviteDownloadLinkView.clickCopyButtonActionBlock = ^{
            @strongify(self)
            // 复制下载链接
            if (![NSString isNil:self.teamDetailModel.shareLink]) {
                UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                pasteboard.string = self.teamDetailModel.shareLink;
                [HUD showMessage:LanguageToolMatch(@"复制成功")];
            }
        };
    }
    return _teamInviteDownloadLinkView;
}

- (void)setTeamDetailModel:(NoaTeamDetailModel *)teamDetailModel {
    if (!teamDetailModel) {
        return;
    }
    _teamDetailModel = teamDetailModel;
    
    // 邀请码
    self.teamInviteCodeView.detailTitle = [NSString isNil:_teamDetailModel.inviteCode] ? @"" : _teamDetailModel.inviteCode;
    
    // 下载链接
    self.teamInviteDownloadLinkView.detailTitle = _teamDetailModel.shareLink;
    
    // 二维码
    self.qrCodeImgView.image = [UIImage getQRCodeImageWithString:self.teamInviteDownloadLinkView.detailTitle qrCodeColor:COLOR_00 inputCorrectionLevel:QRCodeInputCorrectionLevel_M];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setUpUI];
    }
    return self;
}

- (void)setUpUI {
    [self addSubview:self.bgImgView];
    [self.bgImgView addSubview:self.qrCodeBgView];
    [self.bgImgView addSubview:self.qrCodeImgView];
    [self.bgImgView addSubview:self.teamInviteCodeView];
    [self.bgImgView addSubview:self.teamInviteDownloadLinkView];
    
    [self.bgImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    
    [self.qrCodeBgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@40);
        make.centerX.equalTo(self.bgImgView);
        make.width.height.equalTo(@140);
    }];
    
    [self.qrCodeImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.qrCodeBgView);
        make.width.height.equalTo(@136);
    }];
    
    [self.teamInviteCodeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.qrCodeBgView.mas_bottom).offset(24);
        make.leading.trailing.equalTo(self.bgImgView);
    }];
    
    [self.teamInviteDownloadLinkView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.teamInviteCodeView.mas_bottom).offset(24);
        make.leading.trailing.equalTo(self.bgImgView);
    }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 切圆角
        CAShapeLayer *qrCodeBgViewLayer = [self configCornerRect:UIRectCornerAllCorners radius:3.83 rect:self.qrCodeBgView.bounds];
        [self.qrCodeBgView.layer addSublayer:qrCodeBgViewLayer];
    });
    
    
    UILongPressGestureRecognizer *longGestureRecognizer = [UILongPressGestureRecognizer new];
    [self.qrCodeImgView addGestureRecognizer:longGestureRecognizer];
    @weakify(self)
    [[longGestureRecognizer rac_gestureSignal] subscribeNext:^(__kindof UIGestureRecognizer * _Nullable x) {
        @strongify(self)
        if (x.state == UIGestureRecognizerStateBegan) {
            if (self.longPressQRImageViewActionBlock) {
                self.longPressQRImageViewActionBlock(self.qrCodeImgView.image);
            }
        }
    }];
}

/// 将控件画圆角
/// - Parameters:
///   - corners: 哪个角绘制圆角
///   - cornerRadius: 半径
///   - rect: 控件的frame
- (CAShapeLayer *)configCornerRect:(UIRectCorner)corners
                            radius:(CGFloat)cornerRadius
                              rect:(CGRect)rect {
    // 创建圆角路径
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:rect
                                                   byRoundingCorners:corners
                                                         cornerRadii:CGSizeMake(cornerRadius, cornerRadius)];
    // 创建基础圆角 Layer
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.frame = rect;
    maskLayer.path = maskPath.CGPath;
   
    // 边框相关设置
    maskLayer.lineWidth = 3.83;
    maskLayer.fillColor = COLOR_CLEAR.CGColor;
    maskLayer.strokeColor = HEXACOLOR(@"4791FF", 0.4).CGColor;
    @weakify(maskLayer)
    maskLayer.tkThemeChangeBlock = ^(id  _Nullable itself, NSUInteger themeIndex) {
        @strongify(maskLayer)
        if (themeIndex == 0) {
            maskLayer.strokeColor = HEXACOLOR(@"4791FF", 0.4).CGColor;
        } else {
            maskLayer.strokeColor = HEXACOLOR(@"4791FF", 0.4).CGColor;
        }
    };
    
    return maskLayer;
}

@end

@interface NoaTeamInviteDetailView()

/// scrollView
@property (nonatomic, strong) UIScrollView *scrollView;

/// 编辑我的团队名称Label
@property (nonatomic, strong) UILabel *myTeamNameLabel;

/// 编辑我的团队图片
@property (nonatomic, strong) UIImageView *editMyTeamNameImageView;

/// 编辑我的团队名称按钮
@property (nonatomic, strong) UIButton *editMyTeamNameButton;

/// 设为置顶按钮容器
@property (nonatomic, strong) UIView *configureTopContainerView;

/// 设为置顶按钮
@property (nonatomic, strong) UIButton *configureTopButton;

/// 详情页面上方总人数、邀请数量展示页面
@property (nonatomic, strong) NoaTeamInviteTeamDetailTopView *teamInfoTopView;

/// 设为详情页面上方总人数、邀请数量容器
@property (nonatomic, strong) UIView *teamInfoTopContainerView;

/// 团队详情页面西方二维码、下载链接等展示页面
@property (nonatomic, strong) NoaTeamInviteTeamDetailBottomView *teamInfoBottomView;

/// 设为团队详情页面西方二维码、下载链接等展示页面容器
@property (nonatomic, strong) UIView *teamInfoBottomContainerView;

/// 团队详情处理类
@property (nonatomic, strong) NoaTeamInviteDetailDataHandle *teamDetailDataHandle;

@end

@implementation NoaTeamInviteDetailView

- (void)dealloc {
    CIMLog(@"%@ dealloc", [self class]);
}

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [UIScrollView new];
    }
    return _scrollView;
}

- (UILabel *)myTeamNameLabel {
    if (!_myTeamNameLabel) {
        _myTeamNameLabel = [UILabel new];
        _myTeamNameLabel.tkThemetextColors = @[COLOR_11, COLOR_11_DARK];
        _myTeamNameLabel.font = FONTM(16);
    }
    return _myTeamNameLabel;
}

- (UIImageView *)editMyTeamNameImageView {
    if (!_editMyTeamNameImageView) {
        _editMyTeamNameImageView = [UIImageView new];
        _editMyTeamNameImageView.image = [UIImage imageNamed:@"team_detail_edit"];
    }
    return _editMyTeamNameImageView;
}

- (UIButton *)editMyTeamNameButton {
    if (!_editMyTeamNameButton) {
        _editMyTeamNameButton = [UIButton buttonWithType:UIButtonTypeCustom];
    }
    return _editMyTeamNameButton;
}

- (UIView *)configureTopContainerView {
    if (!_configureTopContainerView) {
        _configureTopContainerView = [UIView new];
        _configureTopContainerView.backgroundColor = [UIColor clearColor];
    }
    return _configureTopContainerView;
}

- (UIButton *)configureTopButton {
    if (!_configureTopButton) {
        _configureTopButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_configureTopButton setTitle:LanguageToolMatch(@"设为置顶") forState:UIControlStateNormal];
        _configureTopButton.titleLabel.font = FONTM(14);
        _configureTopButton.titleLabel.tkThemetextColors = @[COLORWHITE, COLORWHITE];
        _configureTopButton.tkThemebackgroundColors = @[COLOR_5966F2, COLOR_5966F2_DARK];
        _configureTopButton.titleEdgeInsets = UIEdgeInsetsMake(6, 16, 6, 12);
    }
    return _configureTopButton;
}

- (NoaTeamInviteTeamDetailTopView *)teamInfoTopView {
    if (!_teamInfoTopView) {
        _teamInfoTopView = [[NoaTeamInviteTeamDetailTopView alloc] initWithFrame:CGRectZero];
        @weakify(self)
        _teamInfoTopView.clickAllGroupCountBlock = ^{
            @strongify(self)
            [self.teamDetailDataHandle.jumpAllGroupPeoplePageSubject sendNext:@1];
        };
    }
    return _teamInfoTopView;
}

- (UIView *)teamInfoTopContainerView {
    if (!_teamInfoTopContainerView) {
        _teamInfoTopContainerView = [UIView new];
        _teamInfoTopContainerView.backgroundColor = [UIColor clearColor];
    }
    return _teamInfoTopContainerView;
}

- (NoaTeamInviteTeamDetailBottomView *)teamInfoBottomView {
    if (!_teamInfoBottomView) {
        _teamInfoBottomView = [[NoaTeamInviteTeamDetailBottomView alloc] initWithFrame:CGRectZero];
        @weakify(self)
        _teamInfoBottomView.longPressQRImageViewActionBlock = ^(UIImage *image) {
            @strongify(self)
            [self saveImage:image];
        };
    }
    return _teamInfoBottomView;
}

- (UIView *)teamInfoBottomContainerView {
    if (!_teamInfoBottomContainerView) {
        _teamInfoBottomContainerView = [UIView new];
        _teamInfoBottomContainerView.backgroundColor = [UIColor clearColor];
    }
    return _teamInfoBottomContainerView;
}

- (RACSubject *)editTeamNameSubject {
    if (!_editTeamNameSubject) {
        _editTeamNameSubject = [RACSubject subject];
    }
    return _editTeamNameSubject;
}

- (instancetype)initWithFrame:(CGRect)frame
   TeamInviteDetailDataHandle:(NoaTeamInviteDetailDataHandle *)dataHandle {
    self = [super initWithFrame:frame];
    if (self) {
        self.teamDetailDataHandle = dataHandle;
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

    // scroll view
    [self addSubview:self.scrollView];
    
    // 团队名称
    [self.scrollView addSubview:self.myTeamNameLabel];
    [self.scrollView addSubview:self.editMyTeamNameImageView];
    [self.scrollView addSubview:self.editMyTeamNameButton];
    
    // 设为置顶
    [self.scrollView addSubview:self.configureTopContainerView];
    [self.configureTopContainerView addSubview:self.configureTopButton];
    
    // 详情数量
    [self.scrollView addSubview:self.teamInfoTopContainerView];
    [self.teamInfoTopContainerView addSubview:self.teamInfoTopView];
    
    // 邀请码、二维码等
    [self.scrollView addSubview:self.teamInfoBottomContainerView];
    [self.teamInfoBottomContainerView addSubview:self.teamInfoBottomView];
    //
    
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self).offset(DNavStatusBarH);
        make.leading.bottom.trailing.equalTo(self);
    }];
    
    [self.myTeamNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.scrollView).offset(16);
        make.leading.equalTo(@16);
        make.height.equalTo(@22);
    }];
    
    [self.editMyTeamNameImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.myTeamNameLabel.mas_trailing).offset(4);
        make.centerY.equalTo(self.myTeamNameLabel);
        make.width.height.equalTo(@20);
    }];
    
    [self.editMyTeamNameButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.bottom.equalTo(self.myTeamNameLabel);
        make.trailing.equalTo(self.editMyTeamNameImageView).offset(4);
    }];
    
    [self.configureTopContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.greaterThanOrEqualTo(@84);
        make.trailing.equalTo(self.scrollView);
        make.top.equalTo(self.scrollView).offset(2);
        make.height.equalTo(@36);
        make.leading.greaterThanOrEqualTo(self.editMyTeamNameImageView.mas_trailing).offset(12);
    }];
    
    [self.configureTopButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.configureTopContainerView);
    }];
    
    [self.teamInfoTopContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.myTeamNameLabel.mas_bottom).offset(16);
        make.leading.equalTo(@16);
        make.trailing.equalTo(self.scrollView).offset(-16);
        make.height.equalTo(@152);
        make.width.equalTo(@(DScreenWidth - 32));
    }];
    
    [self.teamInfoTopView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.teamInfoTopContainerView);
    }];
    
    [self.teamInfoBottomContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.teamInfoTopContainerView.mas_bottom).offset(16);
        make.leading.equalTo(@16);
        make.trailing.equalTo(self.scrollView).offset(-16);
        make.height.equalTo(@398);
        make.width.equalTo(@(DScreenWidth - 32));
    }];
    
    [self.teamInfoBottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.teamInfoBottomContainerView);
    }];
    
    UIView *bottomView = [UIView new];
    [self.scrollView addSubview:bottomView];
    [bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.teamInfoBottomContainerView.mas_bottom);
        make.leading.trailing.bottom.equalTo(self.scrollView);
        make.height.equalTo(@102);
        make.width.equalTo(@(DScreenWidth));
    }];
    
    @weakify(self)
    [[self.editMyTeamNameButton rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        @strongify(self)
        [self.editTeamNameSubject sendNext:@1];
    }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

        /**
         * 为什么不直接赋值圆角，而是使用container容器包裹一下呢，因为圆角与阴影不能同时存在，故container容器设置阴影显示，content视图使用圆角来显示
         */
        
        // 设置内容视图的圆角
        [self configureTopButtonLayer];
        
        //
        [self configureTeamInfoTopViewLayer];
        
        //
        [self configureTeamInfoBottomViewLayer];
    });
}

- (void)configureTopButtonLayer {
    // 设置内容视图的圆角
    UIBezierPath *path;
    if ([ZLanguageTOOL.currentLanguage.languageName_zn isEqualToString:@"阿拉伯语"] ||
        [ZLanguageTOOL.currentLanguage.languageName_zn isEqualToString:@"波斯语"]) {
        path = [UIBezierPath bezierPathWithRoundedRect:self.configureTopContainerView.bounds
                                     byRoundingCorners:(UIRectCornerTopRight | UIRectCornerBottomRight)
                                           cornerRadii:CGSizeMake(18, 18)];
    } else {
        path = [UIBezierPath bezierPathWithRoundedRect:self.configureTopContainerView.bounds
                                     byRoundingCorners:(UIRectCornerTopLeft | UIRectCornerBottomLeft)
                                           cornerRadii:CGSizeMake(18, 18)];
    }
    
    // 2. 设置容器视图的阴影
    self.configureTopContainerView.layer.shadowColor = COLOR_5966F2
        .CGColor;
    self.configureTopContainerView.layer.shadowOffset = CGSizeMake(4, 4);
    self.configureTopContainerView.layer.shadowOpacity = 0.4;
    self.configureTopContainerView.layer.shadowRadius = 12;
    self.configureTopContainerView.layer.shadowPath = path.CGPath;
   
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.path = path.CGPath;
    self.configureTopButton.layer.mask = maskLayer;
}

- (void)configureTeamInfoTopViewLayer {
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.teamInfoTopContainerView.bounds
                                               byRoundingCorners:UIRectCornerAllCorners
                                                    cornerRadii:CGSizeMake(12, 12)];
    
    // 2. 设置容器视图的阴影
    self.teamInfoTopContainerView.layer.shadowColor = HEXCOLOR(@"A7BBDA").CGColor;
    self.teamInfoTopContainerView.layer.shadowOffset = CGSizeMake(0, 8);
    self.teamInfoTopContainerView.layer.shadowOpacity = 0.2;
    self.teamInfoTopContainerView.layer.shadowRadius = 12;
    self.teamInfoTopContainerView.layer.shadowPath = path.CGPath;
   
    @weakify(self)
    self.tkThemeChangeBlock = ^(id  _Nullable itself, NSUInteger themeIndex) {
        @strongify(self)
        if (themeIndex == 0) {
            self.teamInfoTopContainerView.layer.shadowColor = HEXCOLOR(@"A7BBDA").CGColor;
        } else {
            self.teamInfoTopContainerView.layer.shadowColor = HEXCOLOR(@"3E4652").CGColor;
        }
    };
    
    // 子视图切圆
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.path = path.CGPath;
    self.teamInfoTopView.layer.mask = maskLayer;
}

- (void)configureTeamInfoBottomViewLayer {
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.teamInfoBottomContainerView.bounds
                                              byRoundingCorners:(UIRectCornerTopLeft | UIRectCornerBottomLeft)
                                                    cornerRadii:CGSizeMake(12, 12)];
    
    // 2. 设置容器视图的阴影
    self.teamInfoBottomContainerView.layer.shadowColor = HEXCOLOR(@"A7BBDA").CGColor;
    self.teamInfoBottomContainerView.layer.shadowOffset = CGSizeMake(0, 2);
    self.teamInfoBottomContainerView.layer.shadowOpacity = 0.1;
    self.teamInfoBottomContainerView.layer.shadowRadius = 16;
    self.teamInfoBottomContainerView.layer.shadowPath = path.CGPath;
   
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.path = path.CGPath;
    self.teamInfoBottomView.layer.mask = maskLayer;
}

- (void)processData {
    @weakify(self)
    [self.teamDetailDataHandle.requestTeamDetailDataCommand.executionSignals.switchToLatest subscribeNext:^(id  _Nullable x) {
        @strongify(self)
        BOOL isSuccess = [x boolValue];
        if (!isSuccess) {
            return;
        }
        
        self.myTeamNameLabel.text = [NSString isNil:self.teamDetailDataHandle.teamDetailModel.teamName] ? @"" : self.teamDetailDataHandle.teamDetailModel.teamName;
        self.teamInfoTopView.teamDetailModel = self.teamDetailDataHandle.teamDetailModel;
        self.teamInfoBottomView.teamDetailModel = self.teamDetailDataHandle.teamDetailModel;
    }];
    
    [[self.configureTopButton rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        @strongify(self)
        [self.teamDetailDataHandle.editTeamDetailInfoCommand execute:nil];
    }];
    
    [self.teamDetailDataHandle.editTeamDetailInfoCommand.executionSignals.switchToLatest subscribeNext:^(id  _Nullable x) {
        @strongify(self)
        BOOL isSuccess = [x boolValue];
        if (!isSuccess) {
            return;
        }
        // 置顶后的操作
        // 记录用户操作，返回上一级列表需要刷新
        self.teamDetailDataHandle.isOperation = YES;
    }];
    
    [self.teamDetailDataHandle.changeNewTeamSubject subscribeNext:^(id  _Nullable x) {
        @strongify(self)
        NSString *newName = x;
        self.myTeamNameLabel.text = [NSString isNil:newName] ? @"" : newName;
        // 修改名称缓存
        [self.teamDetailDataHandle changeNewTeamName:newName];
        
        // 记录用户操作，返回上一级列表需要刷新
        self.teamDetailDataHandle.isOperation = YES;
    }];
    
    [self reloadData];
}

/// 刷新数据
- (void)reloadData {
    [self.teamDetailDataHandle.requestTeamDetailDataCommand execute:nil];
}

- (void)saveImage:(UIImage *)image {
    //此处需做判断
    @weakify(self)
    NoaPresentItem *saveAlbumItem = [NoaPresentItem creatPresentViewItemWithText:LanguageToolMatch(@"保存相册") textColor:COLOR_11 font:FONTR(17) itemHeight:DWScale(54) backgroundColor:COLORWHITE];
    self.tkThemeChangeBlock = ^(id  _Nullable itself, NSUInteger themeIndex) {
        if (themeIndex == 0) {
            saveAlbumItem.textColor = COLOR_11;
            saveAlbumItem.backgroundColor = COLORWHITE;
        }else {
            saveAlbumItem.textColor = COLORWHITE;
            saveAlbumItem.backgroundColor = COLOR_11;
        }
    };
    
    NoaPresentItem *cancelItem = [NoaPresentItem creatPresentViewItemWithText:LanguageToolMatch(@"取消") textColor:COLOR_99 font:FONTR(17) itemHeight:DWScale(54) backgroundColor:COLORWHITE];
    self.tkThemeChangeBlock = ^(id  _Nullable itself, NSUInteger themeIndex) {
        if (themeIndex == 0) {
            cancelItem.textColor = COLOR_B3B3B3;
            cancelItem.backgroundColor = COLORWHITE;
        }else {
            cancelItem.textColor = COLOR_99;
            cancelItem.backgroundColor = COLOR_11;
        }
    };
    NoaPresentView *viewAlert = [[NoaPresentView alloc] initWithFrame:CGRectMake(0, 0, DScreenWidth, DScreenHeight) titleItem:nil selectItems:@[saveAlbumItem] cancleItem:cancelItem doneClick:^(NSInteger index) {
        @strongify(self)
        if (index == 0) {
            [ZTOOL doInMain:^{
                [self saveShareScreenshotToAlbum:image];
            }];
        }
    } cancleClick:^{
        // 取消，暂不处理
    }];
    [self addSubview:viewAlert];
    [viewAlert showPresentView];
}

#pragma mark - Other
//保存到相册
- (void)saveShareScreenshotToAlbum:(UIImage *)image {
    //保存到相册
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(imageSavedToPhotosAlbum:didFinishSavingWithError:contextInfo:), nil);
}

- (void)imageSavedToPhotosAlbum:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    NSString *message = nil;
    if (!error) {
        message = LanguageToolMatch(@"已保存至相册");
    } else {
        message = [error description];
    }
    [HUD showMessage:message];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
