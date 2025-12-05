//
//  NoaRegisterTypeCell.m
//  NoaChatKit
//
//  Created by phl on 2025/11/12.
//

#import "NoaRegisterTypeCell.h"
#import "NoaRegisterTypeBaseBlurView.h"
#import "NoaRegisterTypeModel.h"

@interface NoaRegisterTypeCell ()

@property (nonatomic, strong) NoaRegisterTypeBaseBlurView *blurView;

/// 图标
@property (nonatomic, strong) UIImageView *iconImgView;

/// 标题
@property (nonatomic, strong) UILabel *titleLabel;

/// 子标题
@property (nonatomic, strong) UILabel *subTitleLabel;

@end

@implementation NoaRegisterTypeCell

#pragma mark - Lazy Loading
- (NoaRegisterTypeBaseBlurView *)blurView {
    if (!_blurView) {
        _blurView = [[NoaRegisterTypeBaseBlurView alloc] initWithFrame:CGRectZero];
    }
    return _blurView;
}

- (UIImageView *)iconImgView {
    if (!_iconImgView) {
        _iconImgView = [UIImageView new];
    }
    return _iconImgView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.tkThemetextColors = @[COLOR_11, COLOR_11_DARK];
        _titleLabel.font = FONTM(16);
    }
    return _titleLabel;
}

- (UILabel *)subTitleLabel {
    if (!_subTitleLabel) {
        _subTitleLabel = [UILabel new];
        _subTitleLabel.tkThemetextColors = @[COLOR_99, COLOR_99_DARK];
        _subTitleLabel.font = FONTR(12);
    }
    return _subTitleLabel;
}

- (void)setRegisterTypeModel:(NoaRegisterTypeModel *)registerTypeModel {
    if (!registerTypeModel) {
        self.iconImgView.image = nil;
        self.titleLabel.text = @"";
        self.subTitleLabel.text = @"";
        return;
    }
    _registerTypeModel = registerTypeModel;
    self.iconImgView.image = ImgNamed(_registerTypeModel.iconName);
    self.titleLabel.text = _registerTypeModel.title;
    self.subTitleLabel.text = _registerTypeModel.subTitle;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.tkThemebackgroundColors = @[
            UIColor.clearColor,
            UIColor.clearColor
        ];
        self.contentView.tkThemebackgroundColors = @[
            UIColor.clearColor,
            UIColor.clearColor
        ];
        [self setUpCell];
    }
    return self;
}

- (void)setUpCell {
    [self.contentView addSubview:self.blurView];
    [self.blurView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@8);
        make.leading.equalTo(@20);
        make.trailing.equalTo(self.contentView).offset(-20);
        make.bottom.equalTo(self.contentView).offset(-8);
    }];
    
    [self.blurView addSubview:self.iconImgView];
    [self.blurView addSubview:self.titleLabel];
    [self.blurView addSubview:self.subTitleLabel];
    
    [self.iconImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView);
        make.leading.equalTo(@20);
        make.width.height.equalTo(@40);
    }];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@30);
        make.leading.equalTo(self.iconImgView.mas_trailing).offset(12);
        make.trailing.equalTo(self.blurView).offset(-20);
        make.height.equalTo(@14);
    }];
    
    [self.subTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(12);
        make.leading.equalTo(self.titleLabel);
        make.trailing.equalTo(self.titleLabel);
        make.height.equalTo(@14);
    }];
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
