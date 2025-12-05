//
//  NoaComplainFromVC.h
//  NoaKit
//
//  Created by Mac on 2023/6/19.
//

#import "NoaBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface NoaComplainFromVC : NoaBaseViewController

@property (nonatomic, copy) NSString *complainID;//投诉ID
@property (nonatomic, assign) CIMChatType complainType;//投诉类型 群聊 好友
@property (nonatomic, assign) ZComplainType complainVCType;//投诉界面类型

//清空界面内容
- (void)clearUIContent;
@end

NS_ASSUME_NONNULL_END
