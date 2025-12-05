//
//  NoaGroupListCell.h
//  NoaKit
//
//  Created by mac on 2022/9/14.
//

// 群聊列表 Cell

#import "NoaBaseCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface NoaGroupListCell : NoaBaseCell
@property (nonatomic, strong) LingIMGroupModel *groupModel;
@end

NS_ASSUME_NONNULL_END
