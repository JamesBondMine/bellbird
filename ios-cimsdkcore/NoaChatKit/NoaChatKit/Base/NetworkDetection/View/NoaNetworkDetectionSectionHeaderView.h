//
//  NoaNetworkDetectionSectionHeaderView.h
//  NoaChatKit
//
//  Created by 庞海亮 on 2025/10/15.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class NoaNetworkDetectionMessageModel;

typedef void(^ChangeSectionFolderStatusBlock)(void);
@interface NoaNetworkDetectionSectionHeaderView : UITableViewHeaderFooterView

@property (nonatomic, strong) NoaNetworkDetectionMessageModel *model;

/// 开始状态图标旋转动画
- (void)startStatusImgViewRotateAnimation;
/// 停止状态图标旋转动画并恢复角度
- (void)stopStatusImgViewRotateAnimation;

@property (nonatomic, copy) ChangeSectionFolderStatusBlock changeSectionFolderStatusBlock;

@end

NS_ASSUME_NONNULL_END
