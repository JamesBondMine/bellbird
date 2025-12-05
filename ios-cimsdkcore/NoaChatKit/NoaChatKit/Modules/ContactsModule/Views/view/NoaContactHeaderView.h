//
//  NoaContactHeaderView.h
//  NoaKit
//
//  Created by mac on 2022/9/23.
//

// 通讯录 tableViewHeader

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@protocol ZContactHeaderViewDelegate <NSObject>
//0:新朋友  1:文件助手  2:群助手
- (void)contactHeaderAction:(NSInteger)actionTag;

@end

@interface NoaContactHeaderView : UIView

@property (nonatomic, weak) id <ZContactHeaderViewDelegate> delegate;
@property (nonatomic, assign) NSInteger newFriendApplyNum;

- (void)updateUI;

@end

NS_ASSUME_NONNULL_END
