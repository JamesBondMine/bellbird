//
//  NoaIMHttpResponse.m
//  NoaChatSDKCore
//
//  Created by mac on 2022/12/19.
//

#import "NoaIMHttpResponse.h"

@interface NoaIMHttpResponse ()
{
    id _responseData;
}
@end

@implementation NoaIMHttpResponse

- (BOOL)isHttpSuccess {
    return _code == LingIMHttpResponseCodeSuccess;
}

- (id)responseData {
    return _responseData;
}

- (void)setResponseData:(id)data {
    _responseData = data;
}

@end
