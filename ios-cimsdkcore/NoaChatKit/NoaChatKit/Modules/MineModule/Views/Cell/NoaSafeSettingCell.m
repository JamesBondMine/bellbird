//
//  NoaSafeSettingCell.m
//  NoaKit
//
//  Created by Mac on 2022/11/13.
//

#import "NoaSafeSettingCell.h"

@interface NoaSafeSettingCell ()

@property (nonatomic, strong)UIButton *backView;
@property (nonatomic, strong)UILabel *titleLbl;
@property (nonatomic, strong) UILabel *lblContent;
@property (nonatomic, strong)UIImageView *arrowImgView;

@end

@implementation NoaSafeSettingCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.contentView.backgroundColor = UIColor.clearColor;
        self.backgroundColor = UIColor.clearColor;
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    [self.contentView addSubview:self.backView];
    [self.backView addSubview:self.titleLbl];
    [self.backView addSubview:self.lblContent];
    [self.backView addSubview:self.arrowImgView];
    
    [self.arrowImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.backView);
        make.trailing.equalTo(self.backView).offset(-16);
        make.width.mas_equalTo(DWScale(8));
        make.height.mas_equalTo(DWScale(16));
    }];
    
    [self.lblContent mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.backView);
        make.trailing.equalTo(self.arrowImgView.mas_leading).offset(-DWScale(10));
        make.width.mas_equalTo(DWScale(80));
        make.height.mas_equalTo(DWScale(22));
    }];
    
    [self.titleLbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.backView);
        make.leading.equalTo(self.backView).offset(16);
        make.trailing.equalTo(self.lblContent.mas_leading).offset(-10);
        make.height.mas_equalTo(DWScale(22));
    }];
}

#pragma mark - Data
- (void)setTitleStr:(NSString *)titleStr {
    _titleStr = titleStr;
    self.titleLbl.text = _titleStr;
}

- (void)setContentStr:(NSString *)contentStr {
    _contentStr = contentStr;
    self.lblContent.text = contentStr;
}

#pragma mark - Action
- (void)cellTouchAction {
    if ([self.baseDelegate respondsToSelector:@selector(cellClickAction:)]) {
        [self.baseDelegate cellClickAction:self.baseCellIndexPath];
    }
}

#pragma mark - Lazy
- (UIButton *)backView {
    if (!_backView) {
        _backView = [[UIButton alloc] init];
        _backView.frame = CGRectMake(16, DWScale(16), DScreenWidth - 16*2, DWScale(54));
        _backView.tkThemebackgroundColors = @[COLORWHITE, COLOR_F5F6F9_DARK];
        [_backView rounded:12];
        [_backView setTkThemeBackgroundImage:@[[UIImage ImageForColor:COLOR_EEEEEE],[UIImage ImageForColor:COLOR_EEEEEE_DARK]] forState:UIControlStateSelected];
        [_backView setTkThemeBackgroundImage:@[[UIImage ImageForColor:COLOR_EEEEEE],[UIImage ImageForColor:COLOR_EEEEEE_DARK]] forState:UIControlStateHighlighted];
        [_backView addTarget:self action:@selector(cellTouchAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backView;
}

- (UILabel *)titleLbl {
    if (!_titleLbl) {
        _titleLbl = [[UILabel alloc] init];
        _titleLbl.text = @"";
        _titleLbl.tkThemetextColors = @[COLOR_11, COLOR_11_DARK];
        _titleLbl.font = FONTN(16);
    }
    return _titleLbl;
}

- (UILabel *)lblContent {
    if (!_lblContent) {
        _lblContent = [UILabel new];
        _lblContent.tkThemetextColors = @[COLOR_99, COLOR_99_DARK];
        _lblContent.font = FONTR(14);
        _lblContent.textAlignment = NSTextAlignmentRight;
    }
    return _lblContent;
}

- (UIImageView *)arrowImgView {
    if (!_arrowImgView) {
        _arrowImgView = [[UIImageView alloc] init];
        _arrowImgView.image = ImgNamed(@"c_arrow_right_gray");
    }
    return _arrowImgView;
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
