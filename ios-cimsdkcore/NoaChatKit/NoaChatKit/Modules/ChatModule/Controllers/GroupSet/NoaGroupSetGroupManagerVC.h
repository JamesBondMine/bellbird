//
//  NoaGroupSetGroupManagerVC.h
//  NoaKit
//
//  Created by mac on 2022/11/16.
//

#import "NoaBaseViewController.h"
#import "LingIMGroup.h"
NS_ASSUME_NONNULL_BEGIN

@interface NoaGroupSetGroupManagerVC : NoaBaseViewController

@property (nonatomic,strong)LingIMGroup * groupInfoModel;
@property (nonatomic,strong)NSArray * mangerIdArr;

@end

NS_ASSUME_NONNULL_END
