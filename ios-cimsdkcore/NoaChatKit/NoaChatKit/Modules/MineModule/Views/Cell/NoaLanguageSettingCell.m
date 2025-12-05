//
//  NoaLanguageSettingCell.m
//  NoaKit
//
//  Created by Mac on 2022/12/28.
//

#import "NoaLanguageSettingCell.h"

@interface NoaLanguageSettingCell()

@property (nonatomic, strong) UIButton *backView;
@property (nonatomic, strong) UIView *viewLine;

@end

@implementation NoaLanguageSettingCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.contentView.backgroundColor = UIColor.clearColor;
        self.backgroundColor = UIColor.clearColor;
        [self setupUI];
    }
    return self;
}

#pragma mark - 界面布局
- (void)setupUI {
    _backView = [[UIButton alloc] initWithFrame:CGRectMake(DWScale(16), 0, DScreenWidth - DWScale(16)*2, DWScale(54))];
    _backView.tkThemebackgroundColors = @[COLORWHITE, COLOR_F5F6F9_DARK];
    [_backView setTkThemeBackgroundImage:@[[UIImage ImageForColor:COLOR_EEEEEE],[UIImage ImageForColor:COLOR_EEEEEE_DARK]] forState:UIControlStateSelected];
    [_backView setTkThemeBackgroundImage:@[[UIImage ImageForColor:COLOR_EEEEEE],[UIImage ImageForColor:COLOR_EEEEEE_DARK]] forState:UIControlStateHighlighted];
    [_backView addTarget:self action:@selector(cellTouchAction) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:_backView];
    
    _lblTitle = [UILabel new];
    _lblTitle.tkThemetextColors = @[COLOR_11, COLOR_11_DARK];
    _lblTitle.font = FONTN(16);
    [_backView addSubview:_lblTitle];
    [_lblTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_backView.mas_top).offset(DWScale(8));
        make.leading.equalTo(_backView).offset(16);
    }];
    _lbBelowlTitle = [UILabel new];
    _lbBelowlTitle.tkThemetextColors = @[COLOR_99, COLOR_99_DARK];
    _lbBelowlTitle.font = FONTN(12);
    [_backView addSubview:_lbBelowlTitle];
    [_lbBelowlTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(_backView.mas_bottom).offset(DWScale(-8));
        make.leading.equalTo(_backView).offset(16);
    }];
    
    _ivSelected = [[UIImageView alloc] initWithImage:ImgNamed(@"icon_selected_blue")];
    _ivSelected.hidden = YES;
    [_backView addSubview:_ivSelected];
    [_ivSelected mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(_backView);
        make.trailing.equalTo(_backView).offset(-16);
        make.size.mas_equalTo(CGSizeMake(DWScale(23), DWScale(23)));
    }];
    
    _viewLine = [UIView new];
    _viewLine.tkThemebackgroundColors = @[COLOR_EEEEEE, [UIColor colorWithRed:85.0/255.0 green:85.0/255.0 blue:85.0/255.0 alpha:1]];
    [_backView addSubview:_viewLine];
    [_viewLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.bottom.equalTo(_backView);
        make.height.mas_equalTo(0.5);
    }];
}

- (void)configCellRoundWithCellIndex:(NSInteger)index totalIndex:(NSInteger)totalIndex {
    if (index == 0 && totalIndex == 1) {
        [self.backView round:12 RectCorners:UIRectCornerAllCorners];
        self.viewLine.hidden = YES;
    } else {
        if (index == 0) {
            [self.backView round:12 RectCorners:UIRectCornerTopLeft | UIRectCornerTopRight];
            self.viewLine.hidden = NO;
        } else if (index == totalIndex - 1) {
            [self.backView round:12 RectCorners:UIRectCornerBottomLeft | UIRectCornerBottomRight];
            self.viewLine.hidden = YES;
        } else {
            [self.backView round:0 RectCorners:UIRectCornerAllCorners];
            self.viewLine.hidden = NO;
        }
    }
}

#pragma mark - Action
- (void)cellTouchAction {
    if ([self.baseDelegate respondsToSelector:@selector(cellClickAction:)]) {
        [self.baseDelegate cellClickAction:self.baseCellIndexPath];
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
