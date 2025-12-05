//
//  NoaGroupMyNicknameVC.h
//  NoaKit
//
//  Created by mac on 2022/11/11.
//

// 我的群昵称VC

#import "NoaBaseViewController.h"
#import "LingIMGroup.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^myGroupNicknameChangeBlock)(void);

@interface NoaGroupMyNicknameVC : NoaBaseViewController

//我在本群的昵称发生修改
@property (nonatomic, copy) myGroupNicknameChangeBlock myGroupNicknameChange;
@property (nonatomic, strong) LingIMGroup *groupInfoModel;

@end

NS_ASSUME_NONNULL_END
