//
//  NoaMineCenterCell.m
//  NoaKit
//
//  Created by Mac on 2022/11/12.
//

#import "NoaMineCenterCell.h"

@interface NoaMineCenterCell ()

@property (nonatomic, strong) UIButton *backView;
@property (nonatomic, strong) UIImageView *iconImgView;
@property (nonatomic, strong) UILabel *contentLbl;
// 右侧箭头
@property (nonatomic, strong) UIImageView *arrowImgView;
// 分割线
@property (nonatomic, strong) UIView *lineView;
@property (nonatomic, strong) UILabel *lblTip;

@end

@implementation NoaMineCenterCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        //        self.contentView.tkThemebackgroundColors = @[COLORWHITE, HEXCOLOR(@"22252D")];
        //        self.tkThemebackgroundColors = @[UIColor.clearColor, UIColor.clearColor];
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    [self.contentView addSubview:self.backView];
    [self.backView addSubview:self.iconImgView];
    [self.backView addSubview:self.contentLbl];
    [self.backView addSubview:self.arrowImgView];
    [self.backView addSubview:self.lineView];
    
    [self.backView addSubview:self.lblTip];
    
    [self.backView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.contentView);
    }];
    
    [self.iconImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.backView);
        make.leading.equalTo(self.backView).offset(16);
        make.width.height.mas_equalTo(22);
    }];
    
    [self.arrowImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.backView);
        make.trailing.equalTo(self.backView).offset(-16);
        make.width.mas_equalTo(12);
        make.height.mas_equalTo(12);
    }];
    
    [self.contentLbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.backView);
        make.leading.equalTo(self.iconImgView.mas_trailing).offset(20);
        make.trailing.equalTo(self.arrowImgView.mas_leading).offset(-10);
        make.height.mas_equalTo(19);
    }];
    
    [self.lineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.backView).offset(-1);
        make.leading.mas_equalTo(self.iconImgView);
        make.trailing.mas_equalTo(self.arrowImgView);
        make.height.mas_equalTo(1);
    }];
    
    
    [self.lblTip mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.backView);
        make.trailing.equalTo(self.arrowImgView.mas_leading).offset(-12);
    }];
}

#pragma mark - Data
- (void)setDataDic:(NSDictionary *)dataDic {
    _dataDic = dataDic;
    
    self.iconImgView.image = ImgNamed((NSString *)[_dataDic objectForKey:@"imageName"]);
    self.contentLbl.text = (NSString *)[_dataDic objectForKey:@"titleName"];
}

- (void)configCellCornerWith:(NSIndexPath *)cellIndexPath totalIndex:(NSInteger)totalIndex {
    //圆角配置
    if (cellIndexPath.row == 0) {
        if (totalIndex == 1) {
            //说明只有一行
            self.lineView.hidden = YES;
        }else {
            //开头
            self.lineView.hidden = YES;
        }
    }else if (cellIndexPath.row == totalIndex - 1) {
        //结尾
        self.lineView.hidden = NO;
    }else {
        //中间
        self.lineView.hidden = YES;
    }
}

- (void)configCellTipWith:(NSIndexPath *)cellIndexPath {
    
    if (cellIndexPath.section == 1 && cellIndexPath.row == 2) {
        //多语言
        self.lblTip.hidden = NO;
        self.lblTip.text = [NoaLanguageManager shareManager].currentLanguage.languageName;
    }else {
        self.lblTip.hidden = YES;
    }
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
        _backView.tkThemebackgroundColors =  @[COLORWHITE, HEXCOLOR(@"22252D")];
        [_backView setTkThemeBackgroundImage:@[[UIImage ImageForColor:COLOR_EEEEEE],[UIImage ImageForColor:COLOR_EEEEEE_DARK]] forState:UIControlStateSelected];
        [_backView setTkThemeBackgroundImage:@[[UIImage ImageForColor:COLOR_EEEEEE],[UIImage ImageForColor:COLOR_EEEEEE_DARK]] forState:UIControlStateHighlighted];
        [_backView addTarget:self action:@selector(cellTouchAction) forControlEvents:UIControlEventTouchUpInside];
        
    }
    return _backView;
}

- (UIImageView *)iconImgView {
    if (!_iconImgView) {
        _iconImgView = [[UIImageView alloc] init];
        _iconImgView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _iconImgView;
}

- (UILabel *)contentLbl {
    if (!_contentLbl) {
        _contentLbl = [[UILabel alloc] init];
        _contentLbl.text = @"";
        _contentLbl.tkThemetextColors = @[COLOR_11, COLOR_11_DARK];
        _contentLbl.font = FONTSB(16);
    }
    return _contentLbl;
}

- (UIImageView *)arrowImgView {
    if (!_arrowImgView) {
        _arrowImgView = [[UIImageView alloc] init];
        _arrowImgView.image = ImgNamed(@"c_arrow_right_gray");
    }
    return _arrowImgView;
}

- (UILabel *)lblTip {
    if (!_lblTip) {
        _lblTip = [UILabel new];
        _lblTip.tkThemetextColors = @[COLOR_99, COLOR_99_DARK];
        _lblTip.font = FONTR(14);
    }
    return _lblTip;
}

- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [[UIView alloc] init];
        _lineView.tkThemebackgroundColors = @[COLOR_EEF1FA, HEXCOLOR(@"27292E")];
    }
    return _lineView;
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
