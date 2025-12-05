//
//  NoaCharacterBindViewController.h
//  NoaKit
//
//  Created by mac on 2023/9/15.
//

#import "NoaBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface NoaCharacterBindViewController : NoaBaseViewController

//绑定结果
@property (nonatomic, copy) void(^chartManageBindResult)(BOOL result);
//yuuee账号
@property (nonatomic, copy) NSString *account;

@property (nonatomic, assign) BOOL isBinded;

@end

NS_ASSUME_NONNULL_END
