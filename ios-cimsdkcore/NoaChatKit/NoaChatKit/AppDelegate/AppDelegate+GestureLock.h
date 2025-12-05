//
//  AppDelegate+GestureLock.h
//  NoaKit
//
//  Created by mac on 2023/4/24.
//

#import "AppDelegate.h"
#import "NoaGestureLockCheckVC.h"

NS_ASSUME_NONNULL_BEGIN

@interface AppDelegate (GestureLock)
<
ZGestureLockCheckVCDelegate
>

- (void)checkUserGestureLock;
@end

NS_ASSUME_NONNULL_END
