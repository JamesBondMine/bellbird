//
//  NoaMineVC.h
//  NoaKit
//
//  Created by Apple on 2022/9/2.
//

#import "NoaBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface NoaMineVC : NoaBaseViewController

/// 以抽屉样式从当前顶部导航 present 出 ZMineVC（带去重）
+ (void)presentMineDrawerFromTop;

@end

NS_ASSUME_NONNULL_END
