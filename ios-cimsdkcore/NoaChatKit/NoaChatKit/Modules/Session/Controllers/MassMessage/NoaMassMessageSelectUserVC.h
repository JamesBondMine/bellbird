//
//  NoaMassMessageSelectUserVC.h
//  NoaKit
//
//  Created by mac on 2023/4/19.
//

#import "NoaBaseViewController.h"
#import "NoaBaseUserModel.h"
NS_ASSUME_NONNULL_BEGIN

@protocol ZMassMessageSelectUserDelegate <NSObject>
- (void)massMessageSelectedUserList:(NSArray<NoaBaseUserModel *> *)selectedUserList;
@end

@interface NoaMassMessageSelectUserVC : NoaBaseViewController
@property (nonatomic, weak) id <ZMassMessageSelectUserDelegate> delegate;

@property (nonatomic, strong) NSMutableArray<NoaBaseUserModel *> *selectedList;//选中的
@end

NS_ASSUME_NONNULL_END
