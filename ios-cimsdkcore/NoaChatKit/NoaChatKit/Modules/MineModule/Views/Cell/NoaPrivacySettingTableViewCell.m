//
//  NoaPrivacySettingTableViewCell.m
//  NoaKit
//
//  Created by mac on 2024/2/16.
//

#import "NoaPrivacySettingTableViewCell.h"

@interface NoaPrivacySettingTableViewCell()
@property (nonatomic, strong) UIButton *viewContent;
@property (nonatomic, strong) UILabel *lblTitle;
@property (nonatomic, strong) UILabel *lblContent;


@end

@implementation NoaPrivacySettingTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.contentView.tkThemebackgroundColors = @[COLOR_F5F6F9, COLOR_11];
    _viewContent = [[UIButton alloc] init];
    _viewContent.frame = CGRectMake(DWScale(16), 0, DScreenWidth - DWScale(32), DWScale(74));
    _viewContent.tkThemebackgroundColors =  @[COLORWHITE, COLOR_F5F6F9_DARK];
    [_viewContent setTkThemeBackgroundImage:@[[UIImage ImageForColor:COLOR_EEEEEE],[UIImage ImageForColor:COLOR_EEEEEE]] forState:UIControlStateSelected];
    [_viewContent setTkThemeBackgroundImage:@[[UIImage ImageForColor:COLOR_EEEEEE],[UIImage ImageForColor:COLOR_EEEEEE]] forState:UIControlStateHighlighted];
    [_viewContent addTarget:self action:@selector(cellTouchAction) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:_viewContent];
    
    _lblTitle = [UILabel new];
    _lblTitle.font = FONTR(16);
    _lblTitle.tkThemetextColors = @[COLOR_11, COLOR_11_DARK];
    [self.contentView addSubview:_lblTitle];
    [_lblTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_viewContent).offset(DWScale(16));
        make.leading.equalTo(_viewContent).offset(DWScale(16));
        make.height.mas_equalTo(DWScale(22));
    }];
    
    _btnSwitch = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnSwitch.userInteractionEnabled = NO;
    [_btnSwitch setImage:ImgNamed(@"c_switch_off") forState:UIControlStateNormal];
    [_btnSwitch setImage:ImgNamed(@"c_switch_on") forState:UIControlStateSelected];
    [self.contentView addSubview:_btnSwitch];
    [_btnSwitch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(_lblTitle);
        make.trailing.equalTo(_viewContent).offset(-DWScale(16));
        make.size.mas_equalTo(CGSizeMake(DWScale(44), DWScale(44)));
    }];
    
    _lblContent = [UILabel new];
    _lblContent.numberOfLines = 2;
    _lblContent.preferredMaxLayoutWidth = DWScale(200);
    _lblContent.font = FONTR(12);
    _lblContent.tkThemetextColors = @[COLOR_66, COLOR_66_DARK];
    [self.contentView addSubview:_lblContent];
    [_lblContent mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(_lblTitle);
        make.top.equalTo(_lblTitle.mas_bottom).offset(DWScale(4));
        make.trailing.equalTo(_btnSwitch.mas_leading).offset(-DWScale(5));
        //make.width.mas_equalTo(DWScale(200));
    }];
}

- (void)updateCellUIWith:(NSInteger)currentRow totalRow:(NSInteger)totalRow {
    
    if (currentRow == 0) {
        _lblTitle.text = LanguageToolMatch(@"离线时长");
        _lblContent.text = LanguageToolMatch(@"关闭后，不展示离线时长");
        _viewContent.height = DWScale(74);
    }
    
    //单个cell
    [_viewContent round:DWScale(12) RectCorners:UIRectCornerAllCorners];
    
    
}


#pragma mark - 交互事件
- (void)cellTouchAction {
    if ([self.baseDelegate respondsToSelector:@selector(cellClickAction:)]) {
        [self.baseDelegate cellClickAction:self.baseCellIndexPath];
    }
}

@end
