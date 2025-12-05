//
//  NoaCountryCodeViewController.h
//  NoaKit
//
//  Created by Mac on 2023/3/28.
//

#import "NoaBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface NoaCountryCodeViewController : NoaBaseViewController

//选中Countrycode的Block回调
@property (nonatomic, copy) void(^selecgCountryCodeBlock)(NSDictionary *dic);

@end

NS_ASSUME_NONNULL_END
