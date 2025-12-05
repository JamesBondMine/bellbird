//
//  NoaNewFriendListCell.m
//  NoaKit
//
//  Created by Mac on 2022/9/9.
//

#import "NoaNewFriendListCell.h"
#import "NoaToolManager.h"

@interface NoaNewFriendListCell()

@property (nonatomic, strong) UIView *bgView;
@property (nonatomic, strong) UIImageView *headImgView;
@property (nonatomic, strong) UILabel *userRoleName;//用户角色名称
@property (nonatomic, strong) UILabel *nickNameLabel;
@property (nonatomic, strong) UIButton *statusButton;
@end

@implementation NoaNewFriendListCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.contentView.tkThemebackgroundColors = @[COLORWHITE, COLOR_11];
        self.tkThemebackgroundColors = @[COLORWHITE, COLOR_11];
        self.contentView.userInteractionEnabled = YES;
        self.selectionStyle = UITableViewCellSelectionStyleDefault;
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    [self.contentView addSubview:self.bgView];
    [self.bgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView);
    }];
    
    //可视化交互
    UIButton *btnContentBg = [UIButton buttonWithType:UIButtonTypeCustom];
    btnContentBg.tkThemebackgroundColors =  @[COLOR_CLEAR, COLOR_CLEAR];
    [btnContentBg setTkThemeBackgroundImage:@[[UIImage ImageForColor:COLOR_EEEEEE],[UIImage ImageForColor:COLOR_EEEEEE_DARK]] forState:UIControlStateSelected];
    [btnContentBg setTkThemeBackgroundImage:@[[UIImage ImageForColor:COLOR_EEEEEE],[UIImage ImageForColor:COLOR_EEEEEE_DARK]] forState:UIControlStateHighlighted];
    [btnContentBg addTarget:self action:@selector(btnContentBgClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.bgView addSubview:btnContentBg];
    [btnContentBg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.bgView);
    }];
    
    [self.bgView addSubview:self.headImgView];
    [self.bgView addSubview:self.userRoleName];
    [self.bgView addSubview:self.nickNameLabel];
    [self.bgView addSubview:self.statusButton];
    
    
    [self.headImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(12);
        make.leading.equalTo(self.contentView).offset(15);
        make.width.height.mas_equalTo(DWScale(44));
    }];
    
    [self.userRoleName mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.headImgView).offset(-DWScale(1));
        make.trailing.equalTo(self.headImgView).offset(DWScale(1));
        make.bottom.equalTo(self.headImgView);
        make.height.mas_equalTo(DWScale(15.4));
    }];
    
    [self.statusButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(18);
        make.trailing.equalTo(self.contentView).offset(-15);
        make.width.mas_equalTo(DWScale(80));
        make.height.mas_equalTo(DWScale(32));
    }];
    
    [self.nickNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.headImgView.mas_trailing).offset(10);
        make.trailing.equalTo(self.statusButton.mas_leading).offset(-15);
        make.centerY.equalTo(self.contentView);
        make.height.mas_equalTo(DWScale(25));
    }];
    
}
#pragma mark - 界面赋值
- (void)setModel:(NoaFriendApplyModel *)model {
    if (model) {
        _model = model;
        NSString *imgUrl;
        if ([model.fromUserUid isEqualToString:UserManager.userInfo.userUID]) {
            //我发起的好友申请
            imgUrl = [NSString loadAvatarWithUserStatus:model.beDisableStatus avatarUri:model.beUserAvatar];
            [self.headImgView loadAvatarWithUserImgContent:imgUrl defaultImg:DefaultAvatar];
            self.nickNameLabel.text = [NSString loadNickNameWithUserStatus:model.beDisableStatus realNickName:model.beUserNickname];
            //角色名称
            NSString *roleName = [UserManager matchUserRoleConfigInfo:model.beRoleId disableStatus:model.beDisableStatus];
            if ([NSString isNil:roleName]) {
                self.userRoleName.hidden = YES;
            } else {
                self.userRoleName.hidden = NO;
                self.userRoleName.text = roleName;
            }
        }else {
            //对方发起的好友申请
            imgUrl = [NSString loadAvatarWithUserStatus:model.fromDisableStatus avatarUri:model.fromUserAvatar];
            [self.headImgView loadAvatarWithUserImgContent:imgUrl defaultImg:DefaultAvatar];
            self.nickNameLabel.text = [NSString loadNickNameWithUserStatus:model.fromDisableStatus realNickName:model.nickname];
            NSString *roleName = [UserManager matchUserRoleConfigInfo:model.fromRoleId disableStatus:model.fromDisableStatus];
            if ([NSString isNil:roleName]) {
                self.userRoleName.hidden = YES;
            } else {
                self.userRoleName.hidden = NO;
                self.userRoleName.text = roleName;
            }            
        }
        
        self.statusButton.userInteractionEnabled = NO;
        switch (model.beStatus) {
            case 0://申请中
            {
                if ([model.fromUserUid isEqualToString:UserManager.userInfo.userUID]) {
                    //我发起的好友申请，等待验证，等待好友通过
                    [self.statusButton setTitle:LanguageToolMatch(@"等待验证") forState:UIControlStateNormal];
                    self.statusButton.tkThemebackgroundColors = @[COLOR_CCCCCC, COLOR_EEEEEE_DARK];
                    [_statusButton setTkThemeTitleColor:@[COLORWHITE, COLOR_CCCCCC_DARK] forState:UIControlStateNormal];
                    [self.statusButton mas_remakeConstraints:^(MASConstraintMaker *make) {
                        make.top.equalTo(self.contentView).offset(18);
                        make.trailing.equalTo(self.contentView).offset(-15);
                        make.width.mas_equalTo(DWScale(80));
                        make.height.mas_equalTo(DWScale(32));
                    }];
                    
                }else {
                    //验证通过，同意对方的好友申请
                    [self.statusButton setTitle:LanguageToolMatch(@"通过验证") forState:UIControlStateNormal];
                    self.statusButton.tkThemebackgroundColors = @[COLOR_5966F2, COLOR_5966F2];
                    [self.statusButton setTkThemeTitleColor:@[COLORWHITE, COLORWHITE] forState:UIControlStateNormal];
                    [self.statusButton setTkThemeBackgroundImage:@[[UIImage ImageForColor:COLOR_4069B9],[UIImage ImageForColor:COLOR_4069B9_DARK]] forState:UIControlStateHighlighted];
                    [self.statusButton mas_remakeConstraints:^(MASConstraintMaker *make) {
                        make.top.equalTo(self.contentView).offset(18);
                        make.trailing.equalTo(self.contentView).offset(-15);
                        make.width.mas_equalTo(DWScale(80));
                        make.height.mas_equalTo(DWScale(32));
                    }];
                    self.statusButton.userInteractionEnabled = YES;
                }
                break;
            case 1://已通过
                {
                    [self.statusButton setTitle:LanguageToolMatch(@"已添加") forState:UIControlStateNormal];
                    self.statusButton.tkThemebackgroundColors = @[COLOR_CCCCCC, COLOR_EEEEEE_DARK];
                    [_statusButton setTkThemeTitleColor:@[COLORWHITE, COLOR_CCCCCC_DARK] forState:UIControlStateNormal];
                    [self.statusButton mas_remakeConstraints:^(MASConstraintMaker *make) {
                        make.top.equalTo(self.contentView).offset(18);
                        make.trailing.equalTo(self.contentView).offset(-15);
                        make.width.mas_equalTo(DWScale(65));
                        make.height.mas_equalTo(DWScale(32));
                    }];
                }
                break;
            case 2://已过期
                {
                    [self.statusButton setTitle:LanguageToolMatch(@"已过期") forState:UIControlStateNormal];
                    self.statusButton.tkThemebackgroundColors = @[COLOR_CCCCCC, COLOR_EEEEEE_DARK];
                    [_statusButton setTkThemeTitleColor:@[COLORWHITE, COLOR_CCCCCC_DARK] forState:UIControlStateNormal];
                    [self.statusButton mas_remakeConstraints:^(MASConstraintMaker *make) {
                        make.top.equalTo(self.contentView).offset(18);
                        make.trailing.equalTo(self.contentView).offset(-15);
                        make.width.mas_equalTo(DWScale(65));
                        make.height.mas_equalTo(DWScale(32));
                    }];
                }
                break;
                
            default:
                break;
            }
                
                
        }
    }
    
}


#pragma mark - Action
    
- (void)statusBtnAction {
    if (self.stateBtnClick) {
        self.stateBtnClick();
    }
}

- (void)btnContentBgClick:(UIButton *)sender {
//    sender.selected = YES;
    
    if (_cellDelegate && [_cellDelegate respondsToSelector:@selector(cellDidSelectRowAtIndexPath:)]) {
        [_cellDelegate cellDidSelectRowAtIndexPath:_cellIndexPath];
    }
    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        [ZTOOL doInMain:^{
//            sender.selected = NO;
//        }];
//    });
    
}

#pragma mark - Lazy

- (UIView *)bgView {
    if (!_bgView) {
        _bgView = [[UIView alloc] init];
        _bgView.tkThemebackgroundColors = @[COLORWHITE, COLOR_11];
    }
    return _bgView;
}

- (UIImageView *)headImgView {
    if (!_headImgView) {
        _headImgView = [[UIImageView alloc] init];
        [_headImgView rounded:DWScale(22)];
    }
    return _headImgView;
}

- (UILabel *)userRoleName {
    if (!_userRoleName) {
        _userRoleName = [UILabel new];
        _userRoleName.text = @"";
        _userRoleName.tkThemetextColors = @[COLORWHITE, COLORWHITE];
        _userRoleName.font = FONTN(7);
        _userRoleName.tkThemebackgroundColors = @[COLOR_EAB243, COLOR_EAB243_DARK];
        _userRoleName.textAlignment = NSTextAlignmentCenter;
        [_userRoleName rounded:DWScale(15.4)/2];
        _userRoleName.hidden = YES;
    }
    return _userRoleName;
}

- (UILabel *)nickNameLabel {
    if (!_nickNameLabel) {
        _nickNameLabel = [[UILabel alloc] init];
        _nickNameLabel.text = @"";
        _nickNameLabel.tkThemetextColors = @[COLOR_11, COLOR_11_DARK];
        _nickNameLabel.font = FONTN(16);
        _nickNameLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _nickNameLabel;
}

- (UIButton *)statusButton {
    if (!_statusButton) {
        _statusButton = [[UIButton alloc] init];
        [_statusButton setTitle:@"" forState:UIControlStateNormal];
        [_statusButton setTkThemeTitleColor:@[COLORWHITE, COLOR_F6F6F6_DARK] forState:UIControlStateNormal];
        _statusButton.titleLabel.font = FONTN(14);
        [_statusButton rounded:DWScale(12)];
        _statusButton.tkThemebackgroundColors = @[COLOR_CCCCCC, COLOR_EEEEEE_DARK];
        [_statusButton setTkThemeBackgroundImage:@[[UIImage ImageForColor:COLOR_EEEEEE],[UIImage ImageForColor:COLOR_EEEEEE_DARK]] forState:UIControlStateHighlighted];
        [_statusButton addTarget:self action:@selector(statusBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _statusButton;
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
