//
//  NoaPrivacySettingTableViewCell.h
//  NoaKit
//
//  Created by mac on 2024/2/16.
//

#import "NoaBaseCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface NoaPrivacySettingTableViewCell : NoaBaseCell
@property (nonatomic, strong) UIButton *btnSwitch;
- (void)updateCellUIWith:(NSInteger)currentRow totalRow:(NSInteger)totalRow;
@end

NS_ASSUME_NONNULL_END
