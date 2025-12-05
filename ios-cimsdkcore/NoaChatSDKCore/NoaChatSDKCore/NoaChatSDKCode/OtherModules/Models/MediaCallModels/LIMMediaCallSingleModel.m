//
//  LIMMediaCallSingleModel.m
//  NoaChatSDKCore
//
//  Created by mac on 2023/1/3.
//

#import "LIMMediaCallSingleModel.h"

@implementation LIMMediaCallSingleModel

+ (NSDictionary *)mj_replacedKeyFromPropertyName {
    //更换参数名称
    return @{
        @"hashKey" : @"hash"
    };
}

@end

