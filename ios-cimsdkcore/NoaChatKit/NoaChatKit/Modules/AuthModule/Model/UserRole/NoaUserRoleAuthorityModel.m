//
//  NoaUserRoleAuthorityModel.m
//  NoaKit
//
//  Created by mac on 2023/11/9.
//

#import "NoaUserRoleAuthorityModel.h"

@implementation NoaUsereAuthModel

@end


@implementation NoaUserRoleAuthorityModel

+ (NSDictionary *)mj_replacedKeyFromPropertyName {
    return @{
        @"translationSwitch": @"translation_switch",
        @"groupMsgPinning": @"group_msg_pinning"
    };

}
// 映射完成后补齐默认值，避免使用处解包为 nil
- (void)mj_keyValuesDidFinishConvertingToObject {
    // helper: 生成默认的 ZUsereAuthModel，configValue 默认 "false"
    NoaUsereAuthModel* (^DefaultAuth)(void) = ^NoaUsereAuthModel*{
        NoaUsereAuthModel *m = [NoaUsereAuthModel new];
        m.configValue = @"false";
        m.configData = @"";
        m.authorityKey = @"";
        return m;
    };

    if (!self.allowAddFriend) { self.allowAddFriend = DefaultAuth(); }
    if (!self.createGroup) { self.createGroup = DefaultAuth(); }
    if (!self.deleteMessage) { self.deleteMessage = DefaultAuth(); }
    if (!self.remoteDeleteMessage) { self.remoteDeleteMessage = DefaultAuth(); }
    if (!self.groupHairAssistant) { self.groupHairAssistant = DefaultAuth(); }
    if (!self.groupSecurity) { self.groupSecurity = DefaultAuth(); }
    if (!self.showGroupPersonNum) { self.showGroupPersonNum = DefaultAuth(); }
    if (!self.showHeadLogo) { self.showHeadLogo = DefaultAuth(); }
    if (!self.showRoleName) { self.showRoleName = DefaultAuth(); }
    if (!self.upFile) { self.upFile = DefaultAuth(); }
    if (!self.showTeam) { self.showTeam = DefaultAuth(); }
    if (!self.upImageVideoFile) {
        NoaUsereAuthModel *m = [NoaUsereAuthModel new];
        m.configValue = @"true";
        m.configData = @"";
        m.authorityKey = @"";
        self.upImageVideoFile = m;
    }
    if (!self.showUserRead) { self.showUserRead = DefaultAuth(); }
    if (!self.isShowFileAssistant) { self.isShowFileAssistant = DefaultAuth(); }
    // 翻译总开关：默认开启
    if (!self.translationSwitch) {
        NoaUsereAuthModel *m = [NoaUsereAuthModel new];
        m.configValue = @"true";
        m.configData = @"";
        m.authorityKey = @"translation_switch";
        self.translationSwitch = m;
    } else if ([NSString isNil:self.translationSwitch.configValue]) {
        self.translationSwitch.configValue = @"true";
    }
    // 群消息置顶开关：默认关闭
    if (!self.groupMsgPinning) {
        self.groupMsgPinning = DefaultAuth();
    } else if ([NSString isNil:self.groupMsgPinning.configValue]) {
        self.groupMsgPinning.configValue = @"false";
    }

}

@end

