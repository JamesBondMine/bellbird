//
//  NoaSafeCodeAuthViewController.h
//  NoaKit
//
//  Created by mac on 2024/12/30.
//

#import "NoaBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface NoaSafeCodeAuthViewController : NoaBaseViewController

@property (nonatomic, copy)NSString *loginInfo;
@property (nonatomic, assign)int loginType;
@property (nonatomic, copy)NSString *scKey;

@end

NS_ASSUME_NONNULL_END
