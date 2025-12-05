//
//  NoaNewMassMessageVC.h
//  NoaKit
//
//  Created by Mac on 2023/4/17.
//

// 新建群发VC

#import "NoaBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface NoaNewMassMessageVC : NoaBaseViewController
@property (nonatomic, strong) LIMMassMessageModel *messageModel;//再发一次消息信息
@end

NS_ASSUME_NONNULL_END
