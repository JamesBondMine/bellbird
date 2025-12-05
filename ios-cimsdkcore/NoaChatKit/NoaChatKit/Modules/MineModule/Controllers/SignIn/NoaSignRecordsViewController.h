//
//  NoaSignRecordsViewController.h
//  NoaKit
//
//  Created by Apple on 2023/8/9.
//

#import "NoaBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface NoaSignRecordsViewController : NoaBaseViewController
@property(nonatomic,strong) NSArray * signInRecords;
@property(nonatomic,copy) NSString * totalLoyalty;
@end

NS_ASSUME_NONNULL_END
