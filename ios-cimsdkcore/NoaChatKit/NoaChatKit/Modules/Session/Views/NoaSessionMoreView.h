//
//  NoaSessionMoreView.h
//  NoaKit
//
//  Created by mac on 2022/9/23.
//

// 会话VC 更多功能弹出View

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ZSessionMoreViewDelegate <NSObject>
- (void)moreViewDelegateWithAction:(ZSessionMoreActionType)actionType;
@end

@interface NoaSessionMoreView : UIView
@property (nonatomic, strong) NSMutableArray *actionList;//功能列表
@property (nonatomic, weak) id <ZSessionMoreViewDelegate> delegate;
- (void)viewShow;
- (void)viewDismiss;
@end

NS_ASSUME_NONNULL_END
