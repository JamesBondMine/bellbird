//
//  NoaFriendManageVC.h
//  NoaKit
//
//  Created by mac on 2022/10/22.
//

// 好友管理VC

#import "NoaBaseViewController.h"
#import "NoaUserModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface NoaFriendManageVC : NoaBaseViewController
@property (nonatomic, strong) NoaUserModel *userModel;
@property (nonatomic, copy) NSString *friendUID;
@end

NS_ASSUME_NONNULL_END
