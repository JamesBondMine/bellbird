//
//  NoaSessionVC.h
//  NoaKit
//
//  Created by Apple on 2022/9/2.
//

#import "NoaBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface NoaSessionVC : NoaBaseViewController

- (void)sessionListAllRead:(NSString *)lastServerMsgId;

@end

NS_ASSUME_NONNULL_END
