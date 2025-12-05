//
//  NoaGroupNoticeDetailVC.h
//  NoaKit
//
//  Created by mac on 2025/8/11.
//

#import <Foundation/Foundation.h>
#import "NoaBaseViewController.h"
#import "LingIMGroup.h"
NS_ASSUME_NONNULL_BEGIN

@interface NoaGroupNoticeDetailVC : NoaBaseViewController

@property (nonatomic,strong) LingIMGroup * groupInfoModel;

@property (nonatomic, strong) NoaGroupNoteModel *groupNoticeModel;

@property (nonatomic, copy) void(^deleteNoticyCallback)(void);

@end

NS_ASSUME_NONNULL_END
