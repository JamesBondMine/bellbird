//
//  NoaChatMultiSelectViewController.h
//  NoaKit
//
//  Created by Mac on 2023/4/11.
//

#import "NoaBaseViewController.h"
#import "NoaMessageModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface NoaChatMultiSelectViewController : NoaBaseViewController

//转发类型
@property (nonatomic, assign)ZMultiSelectType multiSelectType;
@property (nonatomic, copy)NSString *fromSessionId;

//转发(单条转发、逐条转发)
@property (nonatomic, strong)NSArray *forwardMsgList;
@property (nonatomic, copy) void(^forwardMsgSendSuccess)(NSArray<NoaIMChatMessageModel *> *sendForwardMsgList);
@property (nonatomic, copy) void(^forwardMsgSendFail)(void);

//转发(合并转发-选择转发对象)
@property (nonatomic, assign) NSInteger mergeMsgCount;
@property (nonatomic, copy) void(^messageRecordReceverListBlock)(NSArray *selectedReceverInfoArr);

//推荐名片给朋友
@property (nonatomic, strong)NoaUserModel *cardFriendInfo;

//分享二维码
@property (nonatomic, strong)UIImage *qrCodeImg;
@property (nonatomic, copy) void(^shareQrCodeMsgSendSuccess)(NoaIMChatMessageModel *sendQrCodeMsg);


@end

NS_ASSUME_NONNULL_END
