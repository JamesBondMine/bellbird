//
//  NoaChatMessageMoreView.h
//  NoaKit
//
//  Created by mac on 2022/9/28.
//

// 消息长按 更多功能 View

#import <UIKit/UIKit.h>
#import "NoaChatMessageMoreItemView.h"

NS_ASSUME_NONNULL_BEGIN

@interface NoaChatMessageMoreView : UIView

@property (nonatomic, copy)void(^menuClick)(MessageMenuItemActionType actionType);

- (instancetype)initWithMenu:(NSArray *)menuArr targetRect:(CGRect)targetRect isFromMy:(BOOL)isFromMy isBottom:(BOOL)isBottom msgContentSize:(CGSize)msgContentSize;
/// 动态更新菜单项
- (void)updateMenuItems:(NSArray *)menuArr;

@end

NS_ASSUME_NONNULL_END
