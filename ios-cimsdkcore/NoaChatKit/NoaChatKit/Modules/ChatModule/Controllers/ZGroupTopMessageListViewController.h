//
//  ZGroupTopMessageListViewController.h
//  NoaChatKit
//
//  Created by Auto on 2025/1/15.
//

#import "NoaBaseViewController.h"
#import "LingIMGroup.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZGroupTopMessageListViewController : NoaBaseViewController

/// 群组ID
@property (nonatomic, strong) NSString *groupId;
/// 群信息
@property (nonatomic, strong) LingIMGroup *groupInfo;

@end

NS_ASSUME_NONNULL_END

