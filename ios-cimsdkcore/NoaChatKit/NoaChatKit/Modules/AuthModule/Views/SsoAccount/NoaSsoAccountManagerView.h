//
//  NoaSsoAccountManagerView.h
//  NoaChatKit
//
//  Created by phl on 2025/11/5.
//

#import "NoaLoginBaseBlurView.h"

NS_ASSUME_NONNULL_BEGIN

/// 点击登录事件回调
/// @param ssoType - 企业号类型
/// @Param ssoText - 企业号/ip拼接域名
typedef void(^ClickLoginBtnAction)(ZSsoTypeMenu ssoType, NSString *ssoText);

/// 点击扫码事件回调
typedef void(^ClickScanBtnAction)(void);

/// 点击帮助事件回调
typedef void(^ClickHelpBtnAction)(void);

/// 点击网络检测事件回调
typedef void(^ClickNetworkDetectionBtnAction)(NSString *ssoText);

@interface NoaSsoAccountManagerView : NoaLoginBaseBlurView

/// 点击登录事件回调
@property (nonatomic, copy) ClickLoginBtnAction clickLoginBtnAction;

/// 点击扫码事件回调
@property (nonatomic, copy) ClickScanBtnAction clickScanBtnAction;

/// 点击帮助事件回调
@property (nonatomic, copy) ClickHelpBtnAction clickHelpBtnAction;

/// 点击网络检测事件回调
@property (nonatomic, copy) ClickNetworkDetectionBtnAction clickNetworkDetectionBtnAction;

/// 扫码后，修改企业号
- (void)scanQrcodeChangeSsoType:(ZSsoTypeMenu)ssoType SsoInfo:(NSString *)ssoInfo;

@end

NS_ASSUME_NONNULL_END
