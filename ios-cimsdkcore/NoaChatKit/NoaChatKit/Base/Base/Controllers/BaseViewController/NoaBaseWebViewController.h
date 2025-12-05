//
//  NoaBaseWebViewController.h
//  NoaKit
//
//  Created by Mac on 2022/9/20.
//

#import "NoaBaseViewController.h"
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NoaBaseWebViewController : NoaBaseViewController

@property (nonatomic, copy) NSString* webViewTitle;
@property (nonatomic, copy) NSString* webViewUrl;
@property (nonatomic, strong) WKWebView* webView;
@property (nonatomic, copy) NSString *currentUrlStr;

@end

NS_ASSUME_NONNULL_END
