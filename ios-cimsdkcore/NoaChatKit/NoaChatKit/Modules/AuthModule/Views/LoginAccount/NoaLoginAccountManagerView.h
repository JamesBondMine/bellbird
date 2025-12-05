//
//  NoaLoginAccountManagerView.h
//  NoaChatKit
//
//  Created by phl on 2025/11/6.
//

#import "NoaLoginBaseBlurView.h"

NS_ASSUME_NONNULL_BEGIN

@class NoaLoginAccountDataHandle;

@interface NoaLoginAccountManagerView : NoaLoginBaseBlurView

- (instancetype)initWithFrame:(CGRect)frame
                   DataHandle:(NoaLoginAccountDataHandle *)manager;

/// 变更显示的areaCode
- (void)refreshShowAreaCode;

/// 刷新支持的登录方式
- (void)reloadSupportLoginType;

@end

NS_ASSUME_NONNULL_END
