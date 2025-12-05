//
//  NoaTeamDetailVC.h
//  NoaKit
//
//  Created by mac on 2023/7/20.
//

#import "NoaBaseViewController.h"
#import "NoaTeamModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ZTeamDetailVCDelegate <NSObject>

- (void)updateTeamName:(NSString *)name index:(NSInteger)index;

@end

@interface NoaTeamDetailVC : NoaBaseViewController

@property (nonatomic, strong) NoaTeamModel *teamModel;
@property (nonatomic, assign) NSInteger listIndex;
@property (nonatomic, weak) id <ZTeamDetailVCDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
