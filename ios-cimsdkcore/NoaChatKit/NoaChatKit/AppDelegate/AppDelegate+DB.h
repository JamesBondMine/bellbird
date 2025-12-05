//
//  AppDelegate+DB.h
//  NoaKit
//
//  Created by mac on 2022/10/26.
//

#import "AppDelegate.h"
#import "NoaTabBarController.h"

NS_ASSUME_NONNULL_BEGIN

@interface AppDelegate (DB)
<
NoaToolUserDelegate,
NoaToolConnectDelegate,
NoaToolMessageDelegate,
NoaToolSessionDelegate
>

//配置SDK
- (void)configDB;

@end

NS_ASSUME_NONNULL_END
