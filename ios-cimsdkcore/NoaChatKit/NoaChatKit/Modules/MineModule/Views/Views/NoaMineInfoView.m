//
//  NoaMineInfoView.m
//  NoaKit
//
//  Created by mac on 2023/6/26.
//

#import "NoaMineInfoView.h"

@interface NoaMineInfoView ()
@property (nonatomic, strong) UIImageView *ivHeaderBg;//背景图片
@property (nonatomic, strong) UIImageView *ivHeader;//头像
@property (nonatomic, strong) UILabel *ivUserRoleName;//用户角色名称
@property (nonatomic, strong) UILabel *lblNickname;//昵称
@property (nonatomic, strong) UILabel *lblAccount;//账号
@property (nonatomic, strong) UIButton *btnCopy;//复制
@property (nonatomic, strong) UIButton *btnSet;//设置
@end

@implementation NoaMineInfoView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

#pragma mark - 界面布局
- (void)setupUI {
    _ivHeaderBg = [[UIImageView alloc] initWithImage:ImgNamed(@"mine_header_bg")];
    _ivHeaderBg.userInteractionEnabled = YES;
    [self addSubview:_ivHeaderBg];
    [_ivHeaderBg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    
    _ivHeader = [[UIImageView alloc] initWithImage:DefaultAvatar];
    _ivHeader.layer.cornerRadius = DWScale(35);
    _ivHeader.layer.masksToBounds = YES;
    _ivHeader.layer.tkThemeborderColors = @[COLORWHITE, COLORWHITE];
    _ivHeader.layer.borderWidth = DWScale(2);
    [self addSubview:_ivHeader];
    [_ivHeader mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self).offset(DWScale(13));
        make.top.equalTo(self).offset(DWScale(44));
        make.size.mas_equalTo(CGSizeMake(DWScale(70), DWScale(70)));
    }];
    
    _ivUserRoleName = [UILabel new];
    _ivUserRoleName.text = @"";
    _ivUserRoleName.tkThemetextColors = @[COLORWHITE, COLORWHITE];
    _ivUserRoleName.font = FONTN(9);
    _ivUserRoleName.tkThemebackgroundColors = @[COLOR_EAB243, COLOR_EAB243_DARK];
    _ivUserRoleName.textAlignment = NSTextAlignmentCenter;
    [_ivUserRoleName rounded:DWScale(21)/2];
    _ivUserRoleName.hidden = YES;
    [self addSubview:_ivUserRoleName];
    [_ivUserRoleName mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(_ivHeader).offset(-DWScale(1));
        make.trailing.equalTo(_ivHeader).offset(DWScale(1));
        make.bottom.equalTo(_ivHeader);
        make.height.mas_equalTo(DWScale(21));
    }];
    
    UIButton *btnHeader = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnHeader addTarget:self action:@selector(btnHeaderClick) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:btnHeader];
    [btnHeader mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(_ivHeader);
    }];
    
    _lblNickname = [UILabel new];
    _lblNickname.tkThemetextColors = @[COLORWHITE, COLORWHITE];
    _lblNickname.font = FONTR(18);
    [self addSubview:_lblNickname];
    [_lblNickname mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(_ivHeader);
        make.top.equalTo(_ivHeader.mas_bottom).offset(DWScale(8));
        make.height.mas_equalTo(DWScale(22));
    }];
    
    _lblAccount = [UILabel new];
    _lblAccount.tkThemetextColors = @[COLORWHITE, COLORWHITE];
    _lblAccount.font = FONTR(14);
    [self addSubview:_lblAccount];
    [_lblAccount mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(_lblNickname);
        make.top.equalTo(_lblNickname.mas_bottom).offset(DWScale(4));
        make.height.mas_equalTo(DWScale(17));
    }];
    
    _btnCopy = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnCopy setImage:ImgNamed(@"mine_btn_copy_dark") forState:UIControlStateNormal];
    [_btnCopy addTarget:self action:@selector(btnCopyClick) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_btnCopy];
    [_btnCopy mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(_lblAccount);
        make.leading.equalTo(_lblAccount.mas_trailing).offset(DWScale(4));
        make.size.mas_equalTo(CGSizeMake(DWScale(14), DWScale(14)));
    }];
    
    _btnSet = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnSet setImage:ImgNamed(@"mine_btn_set") forState:UIControlStateNormal];
    [_btnSet addTarget:self action:@selector(btnSetClick) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_btnSet];
    [_btnSet mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self).offset(DWScale(52));
        make.trailing.equalTo(self).offset(-DWScale(12));
        make.size.mas_equalTo(CGSizeMake(DWScale(20), DWScale(20)));
    }];
    
    UIButton * signInButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [signInButton setImage:ImgNamed(@"mine_btn_next") forState:UIControlStateNormal];
    [signInButton addTarget:self action:@selector(nextAction) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:signInButton];
    [signInButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(self).offset(-DWScale(27));
        make.trailing.mas_equalTo(self).offset(DWScale(-33));
        make.size.mas_equalTo(CGSizeMake(DWScale(16), DWScale(16)));
    }];
    
    
}

//跳转下一步
-(void)nextAction{
    if (_delegate && [_delegate respondsToSelector:@selector(mineInfoAction:)]) {
        [_delegate mineInfoAction:202];
    }
}
#pragma mark - 界面赋值
- (void)setMineModel:(NoaUserModel *)mineModel {
    _mineModel = mineModel;
    [_ivHeader sd_setImageWithURL:[mineModel.avatar getImageFullUrl] placeholderImage:DefaultAvatar options:SDWebImageAllowInvalidSSLCertificates];
    _lblNickname.text = mineModel.nickname;
    _lblAccount.text = mineModel.userName;
    //角色名称
    NSString *roleName = [UserManager matchUserRoleConfigInfo:mineModel.roleId disableStatus:mineModel.disableStatus];
    if ([NSString isNil:roleName]) {
        _ivUserRoleName.hidden = YES;
    } else {
        _ivUserRoleName.hidden = NO;
        _ivUserRoleName.text = roleName;
    }
}
#pragma mark - 交互事件
- (void)btnHeaderClick {
    if (_delegate && [_delegate respondsToSelector:@selector(mineInfoAction:)]) {
        [_delegate mineInfoAction:200];
    }
}

- (void)btnCopyClick {
    if (![NSString isNil:_lblAccount.text]) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = _lblAccount.text;
        [HUD showMessage:LanguageToolMatch(@"复制成功")];
    }
}

- (void)btnSetClick {
    if (_delegate && [_delegate respondsToSelector:@selector(mineInfoAction:)]) {
        [_delegate mineInfoAction:201];
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
