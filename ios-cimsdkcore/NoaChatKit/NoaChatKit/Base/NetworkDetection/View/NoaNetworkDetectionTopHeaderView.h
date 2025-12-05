//
//  NoaNetworkDetectionTopHeaderView.h
//  NoaChatKit
//
//  Created by phl on 2025/10/15.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class NoaNetworkDetectionHandle;
@interface NoaNetworkDetectionTopHeaderView : UIView

/// init方法
/// - Parameters:
///   - frame: frame
///   - dataHandle: ZNetworkDetectionHandle类
- (instancetype)initWithFrame:(CGRect)frame
                   dataHandle:(NoaNetworkDetectionHandle *)dataHandle;

@end

NS_ASSUME_NONNULL_END
