//
//  NoaSsoHelpCell.m
//  NoaKit
//
//  Created by Mac on 2022/9/2.
//

#import "NoaSsoHelpCell.h"

@interface NoaSsoHelpCell()

@property (nonatomic, strong)UILabel *contentLabel;

@end   

@implementation NoaSsoHelpCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.contentView.tkThemebackgroundColors = @[COLORWHITE, COLOR_11];
        [self setupUI];
    }
    return self;
}

- (void)setupUI
{
    self.contentLabel = [[UILabel alloc] init];
    self.contentLabel.text = @"";
    self.contentLabel.tkThemetextColors = @[COLOR_99, COLOR_99_DARK];
    self.contentLabel.font = FONTN(12);
    self.contentLabel.textAlignment = NSTextAlignmentLeft;
    self.contentLabel.numberOfLines = 0;
    [self.contentLabel sizeToFit];
    [self.contentView addSubview:self.contentLabel];
    [self.contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.contentView).offset(15);
        make.trailing.equalTo(self.contentView).offset(-15);
        make.top.equalTo(self.contentView).offset(12);
        make.bottom.equalTo(self.contentView);
    }];
}

- (void)setContentStr:(NSString *)contentStr {
    _contentStr = contentStr;
    self.contentLabel.text = _contentStr;
    //设置行间距
    [self.contentLabel changeLineSpace:7];
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
