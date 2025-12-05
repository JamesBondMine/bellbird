//
//  NoaMassMessageUserModel.m
//  NoaKit
//
//  Created by mac on 2023/4/21.
//

#import "NoaMassMessageUserModel.h"

@implementation NoaMassMessageUserModel

+ (NSDictionary *)mj_replacedKeyFromPropertyName {
    //更换参数名称
    return @{
        @"taskId" : @"id"
    };
}

@end
