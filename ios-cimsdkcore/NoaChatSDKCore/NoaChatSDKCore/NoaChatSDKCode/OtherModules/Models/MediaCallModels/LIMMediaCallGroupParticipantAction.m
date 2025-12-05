//
//  LIMMediaCallGroupParticipantAction.m
//  NoaChatSDKCore
//
//  Created by mac on 2023/2/9.
//

#import "LIMMediaCallGroupParticipantAction.h"

@implementation LIMMediaCallGroupParticipantAction
+ (NSDictionary *)mj_replacedKeyFromPropertyName {
    //更换参数名称
    return @{
        @"hashKey" : @"hash"
    };
}
@end
