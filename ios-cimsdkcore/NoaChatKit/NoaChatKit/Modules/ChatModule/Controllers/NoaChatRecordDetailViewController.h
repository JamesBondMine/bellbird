//
//  NoaChatRecordDetailViewController.h
//  NoaKit
//
//  Created by Mac on 2023/4/25.
//

#import "NoaBaseViewController.h"
#import "NoaMessageModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface NoaChatRecordDetailViewController : NoaBaseViewController

@property (nonatomic, assign) NSInteger levelNum;
@property (nonatomic, strong) NoaMessageModel *model;

@end

NS_ASSUME_NONNULL_END
