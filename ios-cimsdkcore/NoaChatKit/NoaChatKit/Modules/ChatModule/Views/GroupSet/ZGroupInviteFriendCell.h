//
//  ZGroupInviteAndRemoveFriendCell.h
//  CIMKit
//
//  Created by mac on 2022/11/9.
//

#import "NoaBaseCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface NoaGroupInviteAndRemoveFriendCell : NoaBaseCell
@property (nonatomic, assign) BOOL selectedUser;
- (void)cellConfigWith:(CIMFriendModel *)model search:(NSString *)searchStr;
@end

NS_ASSUME_NONNULL_END
