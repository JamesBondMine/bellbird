//
//  NoaRegisterTypeViewController.h
//  NoaKit
//
//  Created by Mac on 2023/3/27.
//

#import "NoaRegisterAccountAndForgetPasswordBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface NoaRegisterTypeViewController : NoaRegisterAccountAndForgetPasswordBaseViewController

/// 手机号注册区域码
@property (nonatomic, copy) NSString *areaCode;

/// 未使用过的账号-通过点击登录-checkUser接口返回未注册后才有值
@property (nonatomic, copy) NSString *unusedAccountStr;

/// 未使用过得账号对应的注册方式
@property (nonatomic, assign) ZLoginAndRegisterTypeMenu unusedAccountTypeMenu;

/// 当前支持的注册方式
@property (nonatomic, strong) NSArray *registerWayArr;

@end

NS_ASSUME_NONNULL_END
