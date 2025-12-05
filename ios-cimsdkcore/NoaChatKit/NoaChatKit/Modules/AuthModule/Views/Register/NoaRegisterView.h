//
//  NoaRegisterView.h
//  NoaChatKit
//
//  Created by phl on 2025/11/12.
//

#import "NoaLoginBaseBlurView.h"

NS_ASSUME_NONNULL_BEGIN

@class NoaRegisterDataHandle;

@interface NoaRegisterView : NoaLoginBaseBlurView

/// view初始化方法
/// - Parameters:
///   - frame: frame
///   - dataHandle: 注册数据处理
- (instancetype)initWithFrame:(CGRect)frame
                   DataHandle:(NoaRegisterDataHandle *)dataHandle;

/// 变更显示的areaCode
- (void)refreshShowAreaCode;

@end

NS_ASSUME_NONNULL_END
