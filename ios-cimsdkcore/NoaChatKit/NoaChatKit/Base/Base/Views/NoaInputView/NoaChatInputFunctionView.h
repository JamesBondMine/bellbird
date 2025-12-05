//
//  NoaChatInputFunctionView.h
//  NoaKit
//
//  Created by mac on 2022/9/27.
//

// 聊天输入内容 功能 View 56

#import <UIKit/UIKit.h>
#import "NoaChatTextView.h"

NS_ASSUME_NONNULL_BEGIN

@protocol FunctionViewDelegate <NSObject>
//1更多 2表情 3录音 5发送 6键盘响应/隐藏表情 7键盘取消响应 8 @ 消息
- (void)functionViewActionWith:(NSInteger)actionTag
                     atUserList:(NSArray * _Nullable)atUsersDictList
                atSegmentsList:(NSArray * _Nullable)atSegmentsList;
- (void)functionViewHeightChanged:(CGFloat)height;
//底部功能按钮
- (void)functionViewBottomActionWith:(ZChatInputActionType)actionType;
@end

@interface NoaChatInputFunctionView : UIView

@property (nonatomic, copy) NSString * sessionID;//当前聊天ID
@property (nonatomic, assign) ZChatInputViewType viewType;//底部输入框类型

@property (nonatomic, weak) id <FunctionViewDelegate> delegate;
@property (nonatomic, copy) NSString *inputContentStr;

//功能按钮
@property (nonatomic, strong) UIButton *btnMore;//更多功能
@property (nonatomic, strong) UIButton *btnEmoji;//表情
@property (nonatomic, strong) UIButton *btnVoice;//语音/发送

//输入框
@property (nonatomic, strong) UIView *viewContent;
@property (nonatomic, strong) NoaChatTextView *tvContent;
@property (nonatomic, strong) NSMutableArray *_Nullable atUsersDictList;//@用户信息
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *_Nullable atSegments; // 记录“@用户名+空格”的片段范围与uid
@property (nonatomic, assign) BOOL isShowAtList;

//计算高度
- (void)calculateFunctionFrame;
//@某人，输入框输入 @ 选择人后使用方法
- (void)inputAtUserInfo:(NSDictionary *)atUserDict;

//赋值 @ 信息
- (void)configAtUserInfoList:(NSArray *)atUserDictList;

/// 将 @ 信息高亮
- (void)configAtSegmentsInfoList:(NSArray *)atSegmentsInfoList;

//删除时删除掉用此方法 text传@""  range传NSMakeRange(textView.text.length-1, 1)
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text;

//用户角色权限 uploadFile 发生变化
- (void)reloadSetupDataWithTranslateBtnStatus:(BOOL)translateStatus;

//配置翻译按钮状态
- (void)configTranslateBtnStatus:(NSInteger)status;


@end

NS_ASSUME_NONNULL_END
