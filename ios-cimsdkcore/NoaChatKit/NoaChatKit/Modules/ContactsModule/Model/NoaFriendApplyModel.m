//
//  NoaFriendApplyModel.m
//  NoaKit
//
//  Created by mac on 2022/10/20.
//

#import "NoaFriendApplyModel.h"

@implementation NoaFriendApplyModel
+ (NSDictionary *)mj_replacedKeyFromPropertyName {
    //更换参数名称
    return @{
        @"ID" : @"id"
    };
}
@end
