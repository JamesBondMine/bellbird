//
//  NoaComplainImageCell.m
//  NoaKit
//
//  Created by mac on 2023/6/19.
//

#import "NoaComplainImageCell.h"

@implementation NoaComplainImageCell
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}
#pragma mark - 界面布局
- (void)setupUI {
    
    self.contentView.tkThemebackgroundColors = @[COLORWHITE, COLORWHITE_DARK];
    
    _ivComplain = [[UIImageView alloc] initWithImage:ImgNamed(@"c_gray_add")];
    _ivComplain.layer.cornerRadius = DWScale(8);
    _ivComplain.layer.masksToBounds = YES;
    [self.contentView addSubview:_ivComplain];
    [_ivComplain mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView);
    }];
    
    _btnDelete = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnDelete setImage:ImgNamed(@"c_delete_blue_icon") forState:UIControlStateNormal];
    [_btnDelete addTarget:self action:@selector(btnDeleteClick) forControlEvents:UIControlEventTouchUpInside];
    _btnDelete.hidden = YES;
    [self.contentView addSubview:_btnDelete];
    [_btnDelete mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.trailing.equalTo(self.contentView);
        make.size.mas_equalTo(CGSizeMake(DWScale(20), DWScale(20)));
    }];
    
}
#pragma mark - 交互事件
- (void)btnDeleteClick {
    if (_cellIndex) {
        if (_delegate && [_delegate respondsToSelector:@selector(cellDeleteImageWith:)]) {
            [_delegate cellDeleteImageWith:_cellIndex];
        }
    }
}
@end
