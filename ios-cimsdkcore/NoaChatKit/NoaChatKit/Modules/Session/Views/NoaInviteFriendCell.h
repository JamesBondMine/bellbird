//
//  NoaInviteFriendCell.h
//  NoaKit
//
//  Created by mac on 2022/9/23.
//

#import "NoaBaseCell.h"
#import "NoaBaseUserModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface NoaInviteFriendCell : NoaBaseCell

@property (nonatomic, assign) BOOL selectedUser;

- (void)cellConfigBaseUserWith:(NoaBaseUserModel *)model search:(NSString *)searchStr;

@end

NS_ASSUME_NONNULL_END
