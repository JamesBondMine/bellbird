//
//  NoaTeamListCell.h
//  NoaKit
//
//  Created by phl on 2025/7/21.
//

#import <UIKit/UIKit.h>
#import "NoaTeamModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface NoaTeamListCell : UITableViewCell

@property (nonatomic, strong) NoaTeamModel *teamModel;

/// 点击了复制按钮
@property (nonatomic, strong) RACSubject *clickCopySubject;

@end

NS_ASSUME_NONNULL_END
