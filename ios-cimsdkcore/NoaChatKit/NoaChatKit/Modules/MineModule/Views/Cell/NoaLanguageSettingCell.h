//
//  NoaLanguageSettingCell.h
//  NoaKit
//
//  Created by Mac on 2022/12/28.
//

#import "NoaBaseCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface NoaLanguageSettingCell : NoaBaseCell

@property (nonatomic, strong) UILabel *lblTitle;
@property (nonatomic, strong) UILabel *lbBelowlTitle;
@property (nonatomic, strong) UIImageView *ivSelected;

- (void)configCellRoundWithCellIndex:(NSInteger)index totalIndex:(NSInteger)totalIndex;

@end

NS_ASSUME_NONNULL_END
