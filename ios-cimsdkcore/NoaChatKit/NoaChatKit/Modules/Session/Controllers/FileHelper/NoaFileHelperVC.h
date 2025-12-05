//
//  NoaFileHelperVC.h
//  NoaKit
//
//  Created by mac on 2023/6/6.
//

// 文件助手VC

#import "NoaBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface NoaFileHelperVC : NoaBaseViewController
@property (nonatomic, copy) NSString *sessionID;

//通过点击全局搜索结果进入聊天界面
- (void)clickSearchResultInChatRoomWithMessage:(NoaIMChatMessageModel *)messageModel;
@end

NS_ASSUME_NONNULL_END
