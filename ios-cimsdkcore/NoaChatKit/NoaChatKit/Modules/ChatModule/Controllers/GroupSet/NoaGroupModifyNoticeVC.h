//
//  NoaGroupModifyNoticeVC.h
//  NoaKit
//
//  Created by mac on 2022/11/11.
//

#import "NoaBaseViewController.h"
#import "LingIMGroup.h"
NS_ASSUME_NONNULL_BEGIN

typedef void(^SendGroupNoticeSuccessBlock)(void);
@interface NoaGroupModifyNoticeVC : NoaBaseViewController

@property (nonatomic,strong)LingIMGroup * groupInfoModel;

@property (nonatomic, copy) SendGroupNoticeSuccessBlock groupNoticeSuccessBlock;

@end

NS_ASSUME_NONNULL_END
