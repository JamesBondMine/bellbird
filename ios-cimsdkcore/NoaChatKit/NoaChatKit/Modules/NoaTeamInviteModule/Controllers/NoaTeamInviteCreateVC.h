//
//  NoaTeamInviteCreateVC.h
//  NoaKit
//
//  Created by phl on 2025/7/22.
//

#import "NoaBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN
typedef void(^CreateGroupSuccessHandle)(void);
@interface NoaTeamInviteCreateVC : NoaBaseViewController

/// 创建团队成功，返回刷新页面
@property (nonatomic, copy) CreateGroupSuccessHandle createGroupSuccessHandle;

@end

NS_ASSUME_NONNULL_END
