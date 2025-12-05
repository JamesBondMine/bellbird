//
//  NoaGlobalSearchCell.h
//  NoaKit
//
//  Created by mac on 2022/9/14.
//

// 通讯录 搜索 Cell

#import "NoaBaseCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface NoaGlobalSearchCell : NoaBaseCell
- (void)globalSearchConfigWith:(NSIndexPath *)cellIndex model:(id)model search:(NSString *)searchStr;
@end

NS_ASSUME_NONNULL_END
