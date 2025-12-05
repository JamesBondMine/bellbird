//
//  NoaGroupQRCodeVC.h
//  NoaKit
//
//  Created by mac on 2022/11/7.
//

#import "NoaBaseViewController.h"
#import "LingIMGroup.h"
NS_ASSUME_NONNULL_BEGIN

@interface NoaGroupQRCodeVC : NoaBaseViewController

@property (nonatomic, strong)LingIMGroup * groupInfoModel;
@property (nonatomic, copy)NSString *qrcoceContent;
@property (nonatomic, assign) NSInteger expireTime; //过期时间
@end

NS_ASSUME_NONNULL_END
