//
//  NoaMsgAtListViewController.h
//  NoaKit
//
//  Created by Mac on 2022/12/5.
//

#import "NoaBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface NoaMsgAtListViewController : NoaBaseViewController

@property (nonatomic, assign)CIMChatType chatType;
@property (nonatomic, copy)NSString *sessionId;
@property (nonatomic, copy)void(^AtUserSelectClick)(id _Nullable atModel);

@end

NS_ASSUME_NONNULL_END
