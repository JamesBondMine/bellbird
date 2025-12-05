//
//  NoaInputOldPasswordViewController.h
//  NoaKit
//
//  Created by Mac on 2022/11/13.
//

#import "NoaBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface NoaInputOldPasswordViewController : NoaBaseViewController

@property (nonatomic, assign) BOOL isForcedReset; // 是否强制重置，控制返回按钮与手势

@end

NS_ASSUME_NONNULL_END
