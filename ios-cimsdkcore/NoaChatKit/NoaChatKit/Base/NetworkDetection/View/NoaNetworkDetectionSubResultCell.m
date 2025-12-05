//
//  NoaNetworkDetectionSubResultCell.m
//  NoaChatKit
//
//  Created by 庞海亮 on 2025/10/15.
//

#import "NoaNetworkDetectionSubResultCell.h"
#import "NoaNetworkDetectionMessageModel.h"

@interface NoaNetworkDetectionSubResultCell ()

/// 标题
@property (nonatomic, strong) UILabel *titleLabel;

@end

@implementation NoaNetworkDetectionSubResultCell

// MARK: set/get
- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.font = FONTR(12);
        _titleLabel.numberOfLines = 0;
        _titleLabel.lineBreakMode = NSLineBreakByCharWrapping;
    }
    return _titleLabel;
}

- (void)setModel:(NoaNetworkDetectionSubResultModel *)model {
    if (!model) {
        self.titleLabel.text = @"";
        return;
    }
    
    _model = model;
    self.titleLabel.text = model.resultTitleStr;
    
    if (_model.isPass) {
        self.titleLabel.tkThemetextColors = @[COLOR_00D971, COLOR_00D971_DARK];
    }else {
        self.titleLabel.tkThemetextColors = @[COLOR_F93A2F, COLOR_F93A2F_DARK];
    }
}

- (void)setIsLastCell:(BOOL)isLastCell {
    _isLastCell = isLastCell;
    if (_isLastCell) {
        // 是最后一个cell
        [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.contentView).offset(16);
            make.trailing.equalTo(self.contentView).offset(-16);
            make.top.equalTo(self.contentView).offset(4); // 上边距
            make.height.greaterThanOrEqualTo(@17);
            make.bottom.equalTo(self.contentView).offset(-10); // 下边距
        }];
    }else {
        // 不是最后一个cell
        [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.contentView).offset(16);
            make.trailing.equalTo(self.contentView).offset(-16);
            make.top.equalTo(self.contentView).offset(4); // 上边距
            make.height.greaterThanOrEqualTo(@17);
            make.bottom.equalTo(self.contentView).offset(-4); // 下边距
        }];
    }
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self setUpUI];
    }
    return self;
}

- (void)setUpUI {
    self.contentView.tkThemebackgroundColors = @[COLORWHITE, COLORWHITE_DARK];
    
    [self.contentView addSubview:self.titleLabel];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.contentView).offset(16);
        make.trailing.equalTo(self.contentView).offset(-16);
        make.top.equalTo(self.contentView).offset(4); // 上边距
        make.height.greaterThanOrEqualTo(@17);
        make.bottom.equalTo(self.contentView).offset(-4); // 下边距
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
