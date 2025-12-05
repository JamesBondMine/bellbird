//
//  NoaContactHeaderView.m
//  NoaKit
//
//  Created by mac on 2022/9/23.
//

#import "NoaContactHeaderView.h"
#import "UIImage+YYImageHelper.h"
@interface NoaContactHeaderView ()

@property (nonatomic, strong) UILabel *lblRedNum;
@property (nonatomic, strong) UIButton *btnNew;
@property (nonatomic, strong) UIButton *btnFile;
@property (nonatomic, strong) UIButton *btnGroupHelper;
@property (nonatomic, strong) UIView *backView;
@end

@implementation NoaContactHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.tkThemebackgroundColors = @[COLOR_F8F9FB,COLOR_F8F9FB_DARK];
        [self setupUI];
    }
    return self;
}
#pragma mark - 界面布局
- (void)setupUI {
    
    self.backView.tkThemebackgroundColors = @[COLORWHITE, COLOR_11];
    self.backView.layer.masksToBounds = YES;
    self.backView.layer.cornerRadius = DWScale(20);
    [self addSubview:self.backView];
    [self.backView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(DWScale(10));
        make.trailing.mas_equalTo(-DWScale(10));
        make.top.bottom.mas_equalTo(self);
    }];
    
    //新朋友
    _btnNew = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnNew setTkThemeBackgroundImage:@[[UIImage ImageForColor:COLORWHITE],[UIImage ImageForColor:COLORWHITE_DARK]] forState:UIControlStateHighlighted];
    [_btnNew addTarget:self action:@selector(btnNewClick) forControlEvents:UIControlEventTouchUpInside];
    [self.backView addSubview:_btnNew];
    [_btnNew mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.backView);
        make.height.mas_equalTo(DWScale(50));
    }];
    
    UIImageView *ivNew = [[UIImageView alloc] initWithImage:ImgNamed(@"cim_contact_newfriend")];
    [_btnNew addSubview:ivNew];
    [ivNew mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(DWScale(16));
        make.centerY.equalTo(_btnNew);
        make.size.mas_equalTo(CGSizeMake(DWScale(25), DWScale(25)));
    }];
    
    UILabel *lblNewFriend = [UILabel new];
    lblNewFriend.tkThemetextColors = @[COLOR_5966F2, COLOR_5966F2_DARK];
    lblNewFriend.font = FONTR(16);
    lblNewFriend.text = LanguageToolMatch(@"新朋友");
    [_btnNew addSubview:lblNewFriend];
    [lblNewFriend mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(ivNew.mas_trailing).offset(DWScale(16));
        make.top.equalTo(_btnNew);
        make.height.mas_equalTo(DWScale(50));
    }];
    UIView *newFriendLine = [UIView new];
    newFriendLine.tkThemebackgroundColors = @[COLOR_EEF1FA, COLOR_EEF1FA_DARK];
    [_btnNew addSubview:newFriendLine];
    [newFriendLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.bottom.mas_equalTo(_btnNew);
        make.height.mas_equalTo(DWScale(0.5));
        make.leading.mas_equalTo(lblNewFriend);
    }];
    
    _lblRedNum = [UILabel new];
    _lblRedNum.textColor = COLORWHITE;
    _lblRedNum.font = FONTR(12);
    _lblRedNum.text = @" 0 ";
    _lblRedNum.backgroundColor = COLOR_F93A2F;
    _lblRedNum.layer.cornerRadius = DWScale(9);
    _lblRedNum.layer.masksToBounds = YES;
    _lblRedNum.hidden = YES;
    _lblRedNum.textAlignment = NSTextAlignmentCenter;
    [_btnNew addSubview:_lblRedNum];
    [_lblRedNum mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(lblNewFriend);
        make.trailing.equalTo(_btnNew).offset(-10);
        make.height.mas_equalTo(18);
        make.width.mas_greaterThanOrEqualTo(18);
    }];
    
    //文件助手
    _btnFile = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnFile setTkThemeBackgroundImage:@[[UIImage ImageForColor:COLORWHITE],[UIImage ImageForColor:COLORWHITE_DARK]] forState:UIControlStateHighlighted];
    [_btnFile addTarget:self action:@selector(btnFileClick) forControlEvents:UIControlEventTouchUpInside];
    [self.backView addSubview:_btnFile];
    
    UIImageView *ivFile = [[UIImageView alloc] initWithImage:ImgNamed(@"cim_contact_filehelper")];
    [_btnFile addSubview:ivFile];
    [ivFile mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(_btnFile);
        make.leading.equalTo(_btnFile).offset(DWScale(16));
        make.size.mas_equalTo(CGSizeMake(DWScale(25), DWScale(25)));
    }];
    
    UILabel *lblFile = [UILabel new];
    lblFile.tkThemetextColors = @[COLOR_5966F2, COLOR_5966F2_DARK];
    lblFile.font = FONTR(16);
    lblFile.text = LanguageToolMatch(@"文件助手");
    [_btnFile addSubview:lblFile];
    [lblFile mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(ivFile.mas_trailing).offset(DWScale(16));
        make.top.equalTo(_btnFile);
        make.height.mas_equalTo(DWScale(50));
    }];
    
    UIView *fileLine = [UIView new];
    fileLine.tkThemebackgroundColors = @[COLOR_EEF1FA, COLOR_EEF1FA_DARK];
    [_btnNew addSubview:fileLine];
    [fileLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.bottom.mas_equalTo(_btnFile);
        make.height.mas_equalTo(DWScale(0.5));
        make.leading.mas_equalTo(lblFile);
    }];
    
    if ([UserManager.userRoleAuthInfo.isShowFileAssistant.configValue isEqualToString:@"true"]) {
        _btnFile.hidden = NO;
        [_btnFile mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.trailing.equalTo(self.backView);
            make.height.mas_equalTo(DWScale(50));
            make.top.equalTo(_btnNew.mas_bottom);
        }];
    } else {
        _btnFile.hidden = YES;
        [_btnFile mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.trailing.equalTo(self.backView);
            make.height.mas_equalTo(0);
            make.top.equalTo(_btnNew.mas_bottom);
        }];
    }
    
    //群助手
    _btnGroupHelper = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnGroupHelper setTkThemeBackgroundImage:@[[UIImage ImageForColor:COLORWHITE],[UIImage ImageForColor:COLORWHITE_DARK]] forState:UIControlStateHighlighted];
    [_btnGroupHelper addTarget:self action:@selector(btnHelperClick) forControlEvents:UIControlEventTouchUpInside];
    [self.backView addSubview:_btnGroupHelper];
    [_btnGroupHelper mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.backView);
        make.height.mas_equalTo(DWScale(50));
        make.top.equalTo(_btnFile.mas_bottom);
    }];
    
    UIImageView *ivGroupHelper = [[UIImageView alloc] initWithImage:ImgNamed(@"cim_contact_grouphelper")];
    [_btnGroupHelper addSubview:ivGroupHelper];
    [ivGroupHelper mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(_btnGroupHelper);
        make.leading.equalTo(_btnGroupHelper).offset(DWScale(16));
        make.size.mas_equalTo(CGSizeMake(DWScale(25), DWScale(25)));
    }];
    
    UILabel *lblGroupHelper = [UILabel new];
    lblGroupHelper.tkThemetextColors = @[COLOR_5966F2, COLOR_5966F2_DARK];
    lblGroupHelper.font = FONTR(16);
    lblGroupHelper.text = LanguageToolMatch(@"群助手");
    [_btnGroupHelper addSubview:lblGroupHelper];
    [lblGroupHelper mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(ivGroupHelper.mas_trailing).offset(DWScale(16));
        make.top.equalTo(_btnGroupHelper);
        make.height.mas_equalTo(DWScale(50));
    }];
    
    UIView *groupLine = [UIView new];
    groupLine.tkThemebackgroundColors = @[COLOR_EEF1FA, COLOR_EEF1FA_DARK];
    [_btnNew addSubview:groupLine];
    [groupLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.bottom.mas_equalTo(_btnGroupHelper);
        make.height.mas_equalTo(DWScale(0.5));
        make.leading.mas_equalTo(lblGroupHelper);
    }];
    
}

- (void)updateUI {
    if ([UserManager.userRoleAuthInfo.isShowFileAssistant.configValue isEqualToString:@"true"]) {
        _btnFile.hidden = NO;
        [_btnFile mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.trailing.equalTo(self.backView);
            make.height.mas_equalTo(DWScale(50));
            make.top.equalTo(_btnNew.mas_bottom);
        }];
    } else {
        _btnFile.hidden = YES;
        [_btnFile mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.trailing.equalTo(self.backView);
            make.height.mas_equalTo(0);
            make.top.equalTo(_btnNew.mas_bottom);
        }];
    }
}

#pragma mark - 数据赋值
- (void)setNewFriendApplyNum:(NSInteger)newFriendApplyNum {
    _newFriendApplyNum = newFriendApplyNum;
    if (newFriendApplyNum > 0) {
        _lblRedNum.hidden = NO;
        if (newFriendApplyNum > 99) {
            _lblRedNum.text = @" 99+ ";
        }else {
            _lblRedNum.text = [NSString stringWithFormat:@"%ld",newFriendApplyNum];
        }
    }else {
        _lblRedNum.hidden = YES;
    }
}

#pragma mark - 交互事件
- (void)btnNewClick {
    if (_delegate && [_delegate respondsToSelector:@selector(contactHeaderAction:)]) {
        [_delegate contactHeaderAction:0];
    }
}
- (void)btnFileClick {
    if (_delegate && [_delegate respondsToSelector:@selector(contactHeaderAction:)]) {
        [_delegate contactHeaderAction:1];
    }
}
- (void)btnHelperClick {
    if (_delegate && [_delegate respondsToSelector:@selector(contactHeaderAction:)]) {
        [_delegate contactHeaderAction:2];
    }
}

- (UIView *)backView {
    if (_backView == nil) {
        _backView = [[UIView alloc] init];
    }
    return _backView;
}
@end
