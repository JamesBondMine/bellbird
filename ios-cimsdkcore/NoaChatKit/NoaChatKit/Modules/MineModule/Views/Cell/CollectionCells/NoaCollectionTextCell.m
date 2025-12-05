//
//  NoaCollectionTextCell.m
//  NoaKit
//
//  Created by Mac on 2023/4/19.
//

#import "NoaCollectionTextCell.h"
#import "NoaCollectionMenuView.h"

@interface NoaCollectionTextCell()

@property (nonatomic, strong)UIView *backView;
@property (nonatomic, strong)UILabel *contentLbl;
@property (nonatomic, strong)UILabel *nickNameLbl;
@property (nonatomic, strong)UILabel *timeLbl;

@end

@implementation NoaCollectionTextCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.contentView.tkThemebackgroundColors = @[COLOR_F5F6F9, COLOR_11];
        [self setupUI];
    }
    return self;
}

#pragma mark - UI
- (void)setupUI {
    [self.contentView addSubview:self.backView];
    [self.backView addSubview:self.contentLbl];
    [self.backView addSubview:self.nickNameLbl];
    [self.backView addSubview:self.timeLbl];
    
    [self.backView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(DWScale(16));
        make.leading.equalTo(self.contentView).offset(DWScale(16));
        make.trailing.equalTo(self.contentView).offset(-DWScale(16));
        make.height.mas_equalTo(DWScale(82));
    }];
    
    [self.contentLbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.backView).offset(DWScale(16));
        make.leading.equalTo(self.backView).offset(DWScale(16));
        make.trailing.equalTo(self.backView).offset(-DWScale(16));
        make.height.mas_equalTo(DWScale(22));
    }];
    
    [self.nickNameLbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentLbl.mas_bottom).mas_offset(DWScale(10));
        make.leading.equalTo(self.backView).offset(DWScale(16));
        make.width.mas_equalTo((DScreenWidth - DWScale(16)*4)/2 - DWScale(10));
        make.height.mas_equalTo(DWScale(18));
    }];
    
    [self.timeLbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.nickNameLbl);
        make.trailing.equalTo(self.backView).offset(-DWScale(16));
        make.width.mas_equalTo((DScreenWidth - DWScale(16)*4)/2 - DWScale(10));
        make.height.mas_equalTo(DWScale(18));
    }];
}

#pragma mark - Model
- (void)setModel:(NoaMyCollectionModel *)model {
    _model = model;
    
    self.contentLbl.attributedText = _model.attStr;
    self.nickNameLbl.text = _model.itemModel.nick;
    self.timeLbl.text = _model.itemModel.createTime;
    
    [self.backView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(DWScale(16));
        make.leading.equalTo(self.contentView).offset(DWScale(16));
        make.trailing.equalTo(self.contentView).offset(-DWScale(16));
        make.bottom.equalTo(self.contentView);
    }];
    
    [self.contentLbl mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.backView).offset(DWScale(16));
        make.leading.equalTo(self.backView).offset(DWScale(16));
        make.trailing.equalTo(self.backView).offset(-DWScale(16));
        make.height.mas_equalTo(_model.itemHeight);
    }];
    
    // 添加长按手势识别器
    UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [self.contentView addGestureRecognizer:longPressRecognizer];
}

#pragma mark - TapClick
- (void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        [self.contentLbl becomeFirstResponder];

        CGRect textRect = [self.contentLbl.text boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)
                                             options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin
                                          attributes:@{NSFontAttributeName: FONTN(16)}
                                             context:nil];
        
        CGRect targetRect = [self convertRect:textRect toView:CurrentVC.view];
        NoaCollectionMenuView *menuView = [[NoaCollectionMenuView alloc] initWithMenuTitle:LanguageToolMatch(@"复制") rect:targetRect];
        [menuView show];
        [menuView setMenuClickBlock:^{
            [UIPasteboard generalPasteboard].string = self.contentLbl.text;
            [HUD showMessage:LanguageToolMatch(@"复制成功")];
        }];
    }
}

#pragma mark - Lazy
- (UIView *)backView {
    if (!_backView) {
        _backView = [[UIView alloc] init];
        _backView.tkThemebackgroundColors = @[COLORWHITE, COLOR_F5F6F9_DARK];
        [_backView rounded:12];
    }
    return _backView;
}

- (UILabel *)contentLbl {
    if (!_contentLbl) {
        _contentLbl = [[UILabel alloc] init];
        _contentLbl.text = @"";
        _contentLbl.tkThemetextColors = @[COLOR_11, COLOR_11_DARK];
        _contentLbl.font = FONTN(16);
        _contentLbl.numberOfLines = 0;
    }
    return _contentLbl;
}

- (UILabel *)nickNameLbl {
    if (!_nickNameLbl) {
        _nickNameLbl = [[UILabel alloc] init];
        _nickNameLbl.text = @"";
        _nickNameLbl.tkThemetextColors = @[COLOR_99, COLOR_99_DARK];
        _nickNameLbl.font = FONTN(12);
        _nickNameLbl.textAlignment = NSTextAlignmentLeft;
    }
    return _nickNameLbl;
}

- (UILabel *)timeLbl {
    if (!_timeLbl) {
        _timeLbl = [[UILabel alloc] init];
        _timeLbl.text = @"";
        _timeLbl.tkThemetextColors = @[COLOR_99, COLOR_99_DARK];
        _timeLbl.font = FONTN(12);
        _timeLbl.textAlignment = NSTextAlignmentRight;
    }
    return _timeLbl;
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
