//
//  NoaNewFriendListCell.h
//  NoaKit
//
//  Created by Mac on 2022/9/9.
//

#import <UIKit/UIKit.h>
#import "MGSwipeTableCell.h"
#import "NoaFriendApplyModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ZNewFriendListCellDelegate <NSObject>
//点击
- (void)cellDidSelectRowAtIndexPath:(NSIndexPath *)indexPath;
@end

@interface NoaNewFriendListCell : MGSwipeTableCell
@property (nonatomic, strong) NoaFriendApplyModel *model;
@property (nonatomic, copy) void(^stateBtnClick)(void);//按钮交互事件

@property (nonatomic, strong) NSIndexPath *cellIndexPath;
@property (nonatomic, weak) id <ZNewFriendListCellDelegate> cellDelegate;

@end

NS_ASSUME_NONNULL_END
