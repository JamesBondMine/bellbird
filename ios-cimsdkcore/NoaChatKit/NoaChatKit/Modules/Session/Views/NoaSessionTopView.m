//
//  NoaSessionTopView.m
//  NoaKit
//
//  Created by mac on 2022/9/23.
//

#import "NoaSessionTopView.h"
#import "NoaBaseImageView.h"

#import "NoaSessionMoreView.h"
#import "NoaMyMiniAppView.h"

@interface NoaSessionTopView () <ZSessionMoreViewDelegate>
@property (nonatomic, strong) NoaBaseImageView *ivHeader;//头像

@property (nonatomic, strong) UILabel *lblUser;//用户
@property (nonatomic, strong) UILabel *lblRequestState;//加载数据接口状态
@property (nonatomic, strong) UIButton *btnMini;//小程序
@property (nonatomic, strong) UIButton *btnAdd;//添加
@property (nonatomic, strong) UIButton *searchView;
@end

@implementation NoaSessionTopView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
        //监听用户信息更新
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewAppearUpdateUI) name:@"MineUserInfoUpdate" object:nil];
    }
    return self;
}
#pragma mark - 界面布局
- (void)setupUI {
    _ivHeader = [[NoaBaseImageView alloc] init];
    _ivHeader.layer.cornerRadius = DWScale(34)/2;
    _ivHeader.layer.masksToBounds = YES;
    [_ivHeader sd_setImageWithURL:[UserManager.userInfo.avatar getImageFullUrl] placeholderImage:DefaultAvatar options:SDWebImageAllowInvalidSSLCertificates];
    [self addSubview:_ivHeader];
    [_ivHeader mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self).offset(DWScale(16));
        make.top.equalTo(self).offset(DWScale(5) + DStatusBarH);
        make.size.mas_equalTo(CGSizeMake(34, 34));
    }];
    _ivHeader.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onAvatarTapped)];
    [_ivHeader addGestureRecognizer:tap];
    
    _lblUser = [UILabel new];
    _lblUser.text = UserManager.userInfo.nickname;
    _lblUser.tkThemetextColors = @[COLOR_11, COLOR_11_DARK];
    _lblUser.font = FONTB(16);
    [self addSubview:_lblUser];
    [_lblUser mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(_ivHeader.mas_trailing).offset(DWScale(10));
        make.size.mas_equalTo(CGSizeMake(DWScale(200), DWScale(24)));
        make.centerY.mas_equalTo(_ivHeader);
    }];
    
    _lblRequestState = [UILabel new];
    _lblRequestState.text = LanguageToolMatch(@"数据加载中...");
    _lblRequestState.font = FONTN(10);
    _lblRequestState.hidden = YES;
    _lblRequestState.tkThemetextColors = @[[COLOR_FFA500 colorWithAlphaComponent:0.6], [COLOR_FFA500 colorWithAlphaComponent:0.6]];
    [self addSubview:_lblRequestState];
    [_lblRequestState mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_lblUser.mas_bottom);
        make.leading.equalTo(_lblUser);
        make.width.mas_equalTo(DWScale(300));
    }];
    
    _btnAdd = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnAdd setTkThemeImage:@[ImgNamed(@"s_nav_add"), ImgNamed(@"s_nav_add_dark")] forState:UIControlStateNormal];
    [_btnAdd addTarget:self action:@selector(btnAddClick) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_btnAdd];
    [_btnAdd mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(_ivHeader);
        make.trailing.equalTo(self).offset(-DWScale(10));
        make.size.mas_equalTo(CGSizeMake(22, 22));
    }];
    
    _btnMini = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnMini setImage:ImgNamed(@"mini_app_icon") forState:UIControlStateNormal];
    [_btnMini addTarget:self action:@selector(btnMiniClick) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_btnMini];
    [_btnMini mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(_btnAdd);
        make.trailing.equalTo(_btnAdd.mas_leading).offset(-DWScale(20));
        make.size.mas_equalTo(CGSizeMake(24, 24));
    }];
    
    self.searchView = [[UIButton alloc] init];
    self.searchView.tkThemebackgroundColors = @[COLOR_EFEFF2, [COLOR_EFEFF2_DARK colorWithAlphaComponent:0.14]];
    [self.searchView rounded:10.0];
    [self.searchView addTarget:self action:@selector(searchViewClickAction) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.searchView];
    [self.searchView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.mas_leading).offset(DWScale(12));
        make.trailing.mas_equalTo(self.mas_trailing).offset(-DWScale(12));
        make.top.mas_equalTo(self.ivHeader.mas_bottom).offset(DWScale(11));
        make.height.mas_equalTo(DWScale(40));
    }];
    
    UIView *view = [UIView new];
    
    UIImageView *searchIcon = [[UIImageView alloc] init];
    searchIcon.image = ImgNamed(@"cim_contacts_search_icon_grey");
    [view addSubview:searchIcon];
    [searchIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.centerY.mas_equalTo(view);
        make.width.mas_equalTo(DWScale(20));
        make.height.mas_equalTo(DWScale(20));
    }];
    
    UILabel *searchTitleLbl = [[UILabel alloc] init];
    searchTitleLbl.text = LanguageToolMatch(@"搜索");
    searchTitleLbl.tkThemetextColors = @[COLOR_B8BDCC, COLOR_B8BDCC_DARK];
    if([ZLanguageTOOL.currentLanguage.languageName_zn isEqualToString:@"法语"]){
        searchTitleLbl.font = FONTR(12);
    }else{
        searchTitleLbl.font = FONTR(16);
    }
    [view addSubview:searchTitleLbl];
    [searchTitleLbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(searchIcon.mas_trailing).offset(DWScale(8));
        make.centerY.trailing.mas_equalTo(view);
        make.height.mas_equalTo(DWScale(38));
    }];
    
    [self.searchView addSubview:view];
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.centerX.centerY.mas_equalTo(self.searchView);
    }];
}
#pragma mark - Avatar Tap
- (void)onAvatarTapped {
    if (self.avatarTapBlock) {
        self.avatarTapBlock();
    }
}
#pragma mark - 界面数据更新
- (void)viewAppearUpdateUI {
    [_ivHeader sd_setImageWithURL:[UserManager.userInfo.avatar getImageFullUrl] placeholderImage:DefaultAvatar options:SDWebImageAllowInvalidSSLCertificates];
    _lblUser.text = UserManager.userInfo.nickname;
}

- (void)setShowLoading:(BOOL)showLoading {
    _showLoading = showLoading;
    
    _lblRequestState.hidden = !_showLoading;
}

#pragma mark - 交互事件

#pragma mark - SearchClickAction
- (void)searchViewClickAction {
    if (self.searchBlock) {
        self.searchBlock();
    }
}


- (void)btnMiniClick {
    NoaMyMiniAppView *viewMyMiniApp = [NoaMyMiniAppView new];
    [viewMyMiniApp myMiniAppShow];
}

- (void)btnAddClick {
    
    [self showMoreView];
    
    WeakSelf
    [UIView animateWithDuration:0.3 animations:^{
        weakSelf.btnAdd.transform = CGAffineTransformMakeRotation(M_PI_4);
    } completion:^(BOOL finished) {}];
    
}
- (void)showMoreView {
    NoaSessionMoreView *viewMore = [NoaSessionMoreView new];
    viewMore.delegate = self;
    [viewMore viewShow];
}
#pragma mark - ZSessionMoreViewDelegate
- (void)moreViewDelegateWithAction:(ZSessionMoreActionType)actionType {
    //直接恢复原状态，交互不好看
    //_btnAdd.transform = CGAffineTransformIdentity;
    WeakSelf
    [UIView animateWithDuration:0.3 animations:^{
        weakSelf.btnAdd.transform = CGAffineTransformMakeRotation(0);
    } completion:^(BOOL finished) {
        if (weakSelf.addBlock && finished) {
            weakSelf.addBlock(actionType);
        }
    }];
    
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
