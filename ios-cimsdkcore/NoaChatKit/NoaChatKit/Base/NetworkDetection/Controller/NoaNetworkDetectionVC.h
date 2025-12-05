//
//  NoaNetworkDetectionVC.h
//  NoaChatKit
//
//  Created by phl on 2025/10/15.
//

#import "NoaBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface NoaNetworkDetectionVC : NoaBaseViewController

/// 当前企业号(未登录时可为空)
@property (nonatomic, copy, nullable) NSString *currentSsoNumber;

@end

NS_ASSUME_NONNULL_END
