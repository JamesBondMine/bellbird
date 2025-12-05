//
//  NoaTeamInviteDetailVC.h
//  NoaKit
//
//  Created by phl on 2025/7/24.
//

#import "NoaBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class NoaTeamModel;

typedef void(^ReloadDataBlock)(void);
@interface NoaTeamInviteDetailVC : NoaBaseViewController

/// 从上个页面传入的团队信息
@property (nonatomic, strong, readwrite) NoaTeamModel *currentTeamModel;

/// 从上个页面传入的团队信息
@property (nonatomic, copy) ReloadDataBlock reloadDataBlock;

@end

NS_ASSUME_NONNULL_END
