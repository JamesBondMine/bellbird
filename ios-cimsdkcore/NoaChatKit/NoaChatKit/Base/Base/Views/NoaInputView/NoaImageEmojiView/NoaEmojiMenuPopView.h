//
//  NoaEmojiMenuPopView.h
//  NoaKit
//
//  Created by Mac on 2023/8/15.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NoaEmojiMenuPopView : UIView

@property (nonatomic, copy) void(^menuClickBlock)(void);

- (instancetype)initWithMenuTitle:(NSString *)menuTitle targetRect:(CGRect)targetRect;

- (void)ZEmojiMenuShow;
- (void)ZEmojiMenuDismiss;


@end

NS_ASSUME_NONNULL_END
