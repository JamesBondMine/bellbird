//
//  NoaTeamCreateView.h
//  NoaKit
//
//  Created by phl on 2025/7/21.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class NoaTeamCreateDataHandle;
@interface NoaTeamCreateView : UIView

/// 初始化ZTeamInviteDetailView
/// - Parameters:
///   - frame: frame
///   - dataHandle: 数据处理类
- (instancetype)initWithFrame:(CGRect)frame
         TeamCreateDataHandle:(NoaTeamCreateDataHandle *)dataHandle;

@end

NS_ASSUME_NONNULL_END
