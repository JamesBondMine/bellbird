//
//  NoaBlackListHeaderView.m
//  NoaKit
//
//  Created by Mac on 2022/11/17.
//

#import "NoaBlackListHeaderView.h"

@implementation NoaBlackListHeaderView

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self) {
        self.contentView.tkThemebackgroundColors = @[COLORWHITE, COLOR_11];
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.contentView.userInteractionEnabled = YES;
    
    self.contentLabel = [[UILabel alloc] init];
    self.contentLabel.tkThemetextColors = @[COLOR_99, COLOR_99];
    self.contentLabel.font = FONTN(12);
    self.contentLabel.tkThemebackgroundColors = @[COLORWHITE, COLOR_11];
    [self.contentView addSubview:self.contentLabel];
    [self.contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.contentView).offset(16);
        make.trailing.equalTo(self.contentView).offset(-16);
        make.centerY.equalTo(self.contentView);
    }];
}

@end
