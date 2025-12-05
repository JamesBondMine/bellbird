//
//  NoaNetworkDetectionSubResultCell.h
//  NoaChatKit
//
//  Created by 庞海亮 on 2025/10/15.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class NoaNetworkDetectionSubResultModel;

@interface NoaNetworkDetectionSubResultCell : UITableViewCell

@property (nonatomic, strong) NoaNetworkDetectionSubResultModel *model;

/// 如果当前cell为每一个区间最后一个cell，返回YES
@property (nonatomic, assign) BOOL isLastCell;

@end

NS_ASSUME_NONNULL_END
