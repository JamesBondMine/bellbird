//
//  NoaSsoHelpHeaderView.m
//  NoaKit
//
//  Created by Mac on 2022/9/2.
//

#import "NoaSsoHelpHeaderView.h"

@interface NoaSsoHelpHeaderView()

@property (nonatomic, strong)UILabel *contentLabel;

@end

@implementation NoaSsoHelpHeaderView

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.contentView.tkThemebackgroundColors = @[COLORWHITE, COLOR_11];
    
    self.contentLabel = [[UILabel alloc] init];
    self.contentLabel.text = @"";
    self.contentLabel.tkThemetextColors = @[COLOR_11, COLOR_11_DARK];
    self.contentLabel.font = FONTB(14);
    self.contentLabel.textAlignment = NSTextAlignmentLeft;
    [self.contentView addSubview:self.contentLabel];
    [self.contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.contentView).offset(15);
        make.trailing.equalTo(self.contentView).offset(-15);
        make.centerY.equalTo(self.contentView);
        make.height.mas_equalTo(20);
    }];
}

- (void)setContentStr:(NSString *)contentStr {
    _contentStr = contentStr;
    self.contentLabel.text = _contentStr;
}

@end
