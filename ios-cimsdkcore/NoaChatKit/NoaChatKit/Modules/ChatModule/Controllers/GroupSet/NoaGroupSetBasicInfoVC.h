//
//  NoaGropuSetBasicInfoVC.h
//  NoaKit
//
//  Created by mac on 2022/11/7.
//

#import "NoaBaseViewController.h"
#import "LingIMGroup.h"
NS_ASSUME_NONNULL_BEGIN

@interface NoaGroupSetBasicInfoVC : NoaBaseViewController

@property (nonatomic,strong)LingIMGroup * groupInfoModel;

- (void)reloadCurData;

@end

NS_ASSUME_NONNULL_END
