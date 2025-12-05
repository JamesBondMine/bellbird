//
//  NoaRegisterTypeView.h
//  NoaChatKit
//
//  Created by phl on 2025/11/11.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class NoaRegisterTypeDataHandle;

@interface NoaRegisterTypeView : UIView

/// 初始化方法
/// - Parameters:
///   - frame: frame
///   - dataHandle: 数据处理
- (instancetype)initWithFrame:(CGRect)frame
                   DataHandle:(NoaRegisterTypeDataHandle *)dataHandle;

@end

NS_ASSUME_NONNULL_END
