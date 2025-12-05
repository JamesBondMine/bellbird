//
//  NoaAddFriendCell.m
//  NoaKit
//
//  Created by mac on 2022/9/9.
//

#import "NoaAddFriendCell.h"
#import "NoaBaseImageView.h"

#import "NoaToolManager.h"

#import "NoaKnownTipView.h"

#import "UIImage+YYImageHelper.h"
@interface NoaAddFriendCell ()
@property (nonatomic, strong) NoaBaseImageView *ivHeader;
@property (nonatomic, strong) UILabel *lblUserRoleName;//用户角色名称
@property (nonatomic, strong) UILabel *lblNickname;
@property (nonatomic, strong) UIButton *btnAdd;
@end

@implementation NoaAddFriendCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.contentView.backgroundColor = UIColor.clearColor;
        self.backgroundColor = UIColor.clearColor;
        self.selectionStyle = UITableViewCellSelectionStyleDefault;
        [self setupUI];
    }
    return self;
}
+ (CGFloat)defaultCellHeight {
    return DWScale(76);
}
#pragma mark - 界面布局
- (void)setupUI {
    _ivHeader = [[NoaBaseImageView alloc] initWithFrame:CGRectMake(DWScale(16), DWScale(16), DWScale(44), DWScale(44))];
    _ivHeader.layer.cornerRadius = DWScale(22);
    _ivHeader.layer.masksToBounds = YES;
    [self.contentView addSubview:_ivHeader];
    [_ivHeader mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.contentView.mas_leading).offset(DWScale(16));
        make.top.equalTo(self.contentView.mas_top).offset(DWScale(12));
        make.size.mas_equalTo(CGSizeMake(DWScale(44), DWScale(44)));
    }];
    
    _lblUserRoleName = [UILabel new];
    _lblUserRoleName.text = @"";
    _lblUserRoleName.tkThemetextColors = @[COLORWHITE, COLORWHITE];
    _lblUserRoleName.font = FONTN(7);
    _lblUserRoleName.tkThemebackgroundColors = @[COLOR_EAB243, COLOR_EAB243_DARK];
    _lblUserRoleName.textAlignment = NSTextAlignmentCenter;
    [_lblUserRoleName rounded:DWScale(15.4)/2];
    _lblUserRoleName.hidden = YES;
    [self.contentView addSubview:_lblUserRoleName];
    [_lblUserRoleName mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(_ivHeader).offset(-DWScale(1));
        make.trailing.equalTo(_ivHeader).offset(DWScale(1));
        make.bottom.equalTo(_ivHeader);
        make.height.mas_equalTo(DWScale(15.4));
    }];
    
    _lblNickname = [UILabel new];
    _lblNickname.text = @"";
    _lblNickname.tkThemetextColors = @[COLOR_11,COLOR_11_DARK];
    _lblNickname.font = FONTR(16);
    [self.contentView addSubview:_lblNickname];
    [_lblNickname mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(_ivHeader);
        make.leading.equalTo(_ivHeader.mas_trailing).offset(DWScale(10));
        make.width.mas_lessThanOrEqualTo(DWScale(200));
    }];
    
    _btnAdd = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnAdd setTitle:LanguageToolMatch(@"添加好友") forState:UIControlStateNormal];
    [_btnAdd setTkThemeTitleColor:@[COLORWHITE,COLORWHITE] forState:UIControlStateNormal];
    _btnAdd.titleLabel.font = FONTR(14);
    _btnAdd.layer.cornerRadius = DWScale(12);
    _btnAdd.layer.masksToBounds = YES;
    [_btnAdd setBackgroundColor:COLOR_5966F2];
    [_btnAdd setTkThemeBackgroundImage:@[[UIImage ImageForColor:COLOR_4069B9],[UIImage ImageForColor:COLOR_4069B9_DARK]] forState:UIControlStateHighlighted];
    [_btnAdd addTarget:self action:@selector(btnAddClick) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:_btnAdd];
    [_btnAdd mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(_ivHeader);
        make.trailing.equalTo(self.contentView).offset(-DWScale(16));
        make.height.mas_equalTo(DWScale(32));
        make.width.mas_equalTo(DWScale(80));
    }];
    
}
#pragma mark - 交互事件
- (void)btnAddClick {
    if (_userModel) {
        //判断是否是好友
        WeakSelf
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:_userModel.userUID forKey:@"friendUserUid"];
        [dict setValue:UserManager.userInfo.userUID forKey:@"userUid"];
        
        [IMSDKManager checkMyFriendWith:dict onSuccess:^(id _Nullable data, NSString * _Nullable traceId) {
            BOOL isMyFriend = [data boolValue];
            if (isMyFriend) {
                [HUD showMessage:LanguageToolMatch(@"该用户已是你的好友")];
            }else {
                [weakSelf goAddFriend];
            }
        } onFailure:^(NSInteger code, NSString * _Nullable msg, NSString * _Nullable traceId) {
            [HUD showMessageWithCode:code errorMsg:msg];
        }];
        
    }

}
- (void)goAddFriend {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:_userModel.userUID forKey:@"friendUserUid"];
    [dict setValue:UserManager.userInfo.userUID forKey:@"userUid"];
    [IMSDKManager addContactWith:dict onSuccess:^(id _Nullable data, NSString * _Nullable traceId) {
        [HUD showMessage:LanguageToolMatch(@"已发送")];
    } onFailure:^(NSInteger code, NSString * _Nullable msg, NSString * _Nullable traceId) {
        NoaKnownTipView *viewTip = [NoaKnownTipView new];
        viewTip.lblTip.text = LanguageToolMatch(msg);
        [viewTip knownTipViewSHow];
    }];
}

#pragma mark - 数据赋值
- (void)setUserModel:(NoaUserModel *)userModel {
    if (userModel) {
        _userModel = userModel;
        _lblNickname.text = userModel.nickname;
        [_ivHeader sd_setImageWithURL:[userModel.avatar getImageFullUrl] placeholderImage:DefaultAvatar options:SDWebImageAllowInvalidSSLCertificates];
        //角色名称
        NSString *roleName = [UserManager matchUserRoleConfigInfo:userModel.roleId disableStatus:userModel.disableStatus];
        if ([NSString isNil:roleName]) {
            _lblUserRoleName.hidden = YES;
        } else {
            _lblUserRoleName.hidden = NO;
            _lblUserRoleName.text = roleName;
        }
       
        LingIMFriendModel *friendModel = [IMSDKManager toolCheckMyFriendWith:userModel.userUID];
        if (friendModel) {
            //已是好友
            [_btnAdd setTitle:LanguageToolMatch(@"已添加") forState:UIControlStateNormal];
            [_btnAdd setTkThemebackgroundColors:@[COLOR_99,COLOR_99_DARK]];
            _btnAdd.userInteractionEnabled = NO;
        }else {
            //不是好友
            [_btnAdd setTitle:LanguageToolMatch(@"添加好友") forState:UIControlStateNormal];
            [_btnAdd setTkThemebackgroundColors:@[COLOR_5966F2,COLOR_5966F2]];
            [_btnAdd setTkThemeBackgroundImage:@[[UIImage ImageForColor:COLOR_4069B9],[UIImage ImageForColor:COLOR_4069B9_DARK]] forState:UIControlStateHighlighted];
            _btnAdd.userInteractionEnabled = YES;
        }
    }
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
