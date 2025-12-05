//
//  NoaSystemFooterView.m
//  NoaKit
//
//  Created by Mac on 2023/4/17.
//

#import "NoaSystemFooterView.h"

@interface NoaSystemFooterView ()

@property (nonatomic, strong) UILabel *contentInfoLal;

@end

@implementation NoaSystemFooterView

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self) {
        self.contentView.tkThemebackgroundColors = @[COLOR_F5F6F9, COLOR_11];
        [self setupUI];
    }
    return self;
}

#pragma mark - 界面布局
- (void)setupUI {
    _contentInfoLal = [UILabel new];
    _contentInfoLal.font = FONTN(12);
    _contentInfoLal.numberOfLines = 0;
    _contentInfoLal.tkThemebackgroundColors = @[COLOR_F5F6F9, COLOR_11];
    _contentInfoLal.tkThemetextColors = @[COLOR_99, COLOR_99_DARK];
    [self.contentView addSubview:_contentInfoLal];
    [_contentInfoLal mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(DWScale(10));
        make.bottom.equalTo(self.contentView);
        make.leading.equalTo(self.contentView).offset(DWScale(16));
        make.trailing.equalTo(self.contentView).offset(-DWScale(16));
    }];
}

- (void)setContentStr:(NSString *)contentStr {
    _contentStr = contentStr;
    _contentInfoLal.text = _contentStr;
}

@end
