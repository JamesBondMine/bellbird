//
//  NoaGroupInviteFriendVC.h
//  NoaKit
//
//  Created by mac on 2022/11/9.
//

#import "NoaBaseViewController.h"
#import "LingIMGroup.h"
NS_ASSUME_NONNULL_BEGIN

@interface NoaGroupInviteFriendVC : NoaBaseViewController

@property (nonatomic,strong)NSArray<LingIMGroupMemberModel *> *groupMemberList;
@property (nonatomic,strong)LingIMGroup *groupInfoModel;

@end

NS_ASSUME_NONNULL_END
