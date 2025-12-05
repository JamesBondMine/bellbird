//
//  NoaChatMessageMoreItemView.h
//  NoaKit
//
//  Created by mac on 2022/9/29.
//

// 27 + 12 + 行 * 56
 
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@protocol ZChatMessageMoreItemViewDelegate <NSObject>

- (void)menuItemViewSelectedAction:(MessageMenuItemActionType)actionType;

@end

@interface NoaChatMessageMoreItemView : UIView

@property (nonatomic, strong) NSArray *menuArr;
@property (nonatomic, weak) id <ZChatMessageMoreItemViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
