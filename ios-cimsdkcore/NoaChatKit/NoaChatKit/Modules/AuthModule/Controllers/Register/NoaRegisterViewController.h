//
//  NoaRegisterViewController.h
//  NoaChatKit
//
//  Created by phl on 2025/11/12.
//

#import "NoaRegisterAccountAndForgetPasswordBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface NoaRegisterViewController : NoaRegisterAccountAndForgetPasswordBaseViewController

/// 手机注册 - 区号
@property (nonatomic, copy, readwrite) NSString *areaCode;

/// 支持的注册方式
@property (nonatomic, assign, readwrite) ZLoginAndRegisterTypeMenu currentRegisterWay;

/// 登录页面传入的未注册的账号
@property (nonatomic, copy, readwrite) NSString *unusedAccount;

@end

NS_ASSUME_NONNULL_END
