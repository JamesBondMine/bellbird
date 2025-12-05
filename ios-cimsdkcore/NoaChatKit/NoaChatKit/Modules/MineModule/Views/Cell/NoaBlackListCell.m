//
//  NoaBlackListCell.m
//  NoaKit
//
//  Created by Mac on 2022/11/17.
//

#import "NoaBlackListCell.h"

@interface NoaBlackListCell()

@property (nonatomic, strong)UIImageView *headImgView;
@property (nonatomic, strong) UILabel *userRoleName;//用户角色名称
@property (nonatomic, strong)UILabel *nickNameLabel;

@end

@implementation NoaBlackListCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.contentView.backgroundColor = UIColor.clearColor;
        self.backgroundColor = UIColor.clearColor;
        [self setupUI];
    }
    return self;
}

- (void)setupUI
{
    self.headImgView = [[UIImageView alloc] init];
    [self.headImgView rounded:DWScale(22)];
    [self.contentView addSubview:self.headImgView];
    [self.headImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.contentView).offset(DWScale(15));
        make.top.equalTo(self.contentView).offset(12);
        make.size.mas_equalTo(CGSizeMake(44, 44));
    }];
    
    self.userRoleName = [UILabel new];
    self.userRoleName.text = @"";
    self.userRoleName.tkThemetextColors = @[COLORWHITE, COLORWHITE];
    self.userRoleName.font = FONTN(7);
    self.userRoleName.tkThemebackgroundColors = @[COLOR_EAB243, COLOR_EAB243_DARK];
    self.userRoleName.textAlignment = NSTextAlignmentCenter;
    [self.userRoleName rounded:DWScale(15.4)/2];
    self.userRoleName.hidden = YES;
    [self.contentView addSubview:self.userRoleName];
    [self.userRoleName mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.headImgView).offset(-DWScale(1));
        make.trailing.equalTo(self.headImgView).offset(DWScale(1));
        make.bottom.equalTo(self.headImgView);
        make.height.mas_equalTo(DWScale(15.4));
    }];
    
    self.nickNameLabel = [[UILabel alloc] init];
    self.nickNameLabel.text = @"";
    self.nickNameLabel.tkThemetextColors = @[COLOR_11, COLOR_11_DARK];
    self.nickNameLabel.font = FONTN(16);
    self.nickNameLabel.textAlignment = NSTextAlignmentLeft;
    [self.contentView addSubview:self.nickNameLabel];
    [self.nickNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.headImgView.mas_trailing).offset(DWScale(10));
        make.top.equalTo(self.contentView).offset(DWScale(68)/2 - DWScale(25)/2);
        make.size.mas_equalTo(CGSizeMake(DScreenWidth - (15+DWScale(44)+10) - 30, DWScale(25)));
    }];
}

#pragma mark - 数据赋值
- (void)setBlackModel:(LingIMFriendModel *)blackModel {
    if (blackModel) {
        _blackModel = blackModel;
        //头像
        NSString *headUrl = [NSString loadAvatarWithUserStatus:_blackModel.disableStatus avatarUri:_blackModel.avatar];
        [self.headImgView loadAvatarWithUserImgContent:headUrl defaultImg:DefaultAvatar];
        //昵称
        self.nickNameLabel.text = [NSString loadNickNameWithUserStatus:_blackModel.disableStatus realNickName:_blackModel.showName];
        //角色名称
        NSString *roleName = [UserManager matchUserRoleConfigInfo:_blackModel.roleId disableStatus:_blackModel.disableStatus];
        if ([NSString isNil:roleName]) {
            self.userRoleName.hidden = YES;
        } else {
            self.userRoleName.hidden = NO;
            self.userRoleName.text = roleName;
        }
    }
}

#pragma mark - Other
- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
