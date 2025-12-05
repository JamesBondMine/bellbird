//
//  NoaImageTitleContentArrowCell.h
//  NoaKit
//
//  Created by mac on 2022/9/23.
//

#import "NoaBaseCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface NoaImageTitleContentArrowCell : NoaBaseCell
@property (nonatomic, strong) UIImageView *ivLogo;
@property (nonatomic, strong) UILabel *lblTitle;
@property (nonatomic, strong) UILabel *lblContent;
@property (nonatomic, strong) UIImageView *ivArrow;
@end

NS_ASSUME_NONNULL_END
