//
//  NoaChangeUserInfoViewController.h
//  NoaKit
//
//  Created by Mac on 2022/11/14.
//

#import "NoaBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, changeUserInfoType) {
    changeUserInfoTypeNick = 0,      //修改昵称
    changeUserInfoTypeAccount,       //修改账号
};

@interface NoaChangeUserInfoViewController : NoaBaseViewController

@property (nonatomic, assign)changeUserInfoType changeType;
@property (nonatomic, copy)NSString *originalContent;

@end

NS_ASSUME_NONNULL_END
