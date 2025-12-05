//
//  NoaGroupSetNotalkMemberVC.h
//  NoaKit
//
//  Created by mac on 2022/11/15.
//

#import "NoaBaseViewController.h"
#import "LingIMGroup.h"
NS_ASSUME_NONNULL_BEGIN

@interface NoaGroupSetNotalkMemberVC : NoaBaseViewController
@property (nonatomic,strong)LingIMGroup * groupInfoModel;
@property (nonatomic,strong)NSArray * notalkFriendIDArr;//已经禁言好友ID
@end

NS_ASSUME_NONNULL_END
