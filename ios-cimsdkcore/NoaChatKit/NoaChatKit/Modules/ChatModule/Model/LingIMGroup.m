//
//  ZGroupInfoModel.m
//  NoaKit
//
//  Created by Mac on 2022/11/4.
//

#import "LingIMGroup.h"

@implementation LingIMGroup

+ (NSDictionary *)mj_objectClassInArray
{
    return @{@"groupMemberList":@"LingIMGroupMemberModel"};
}
@end
