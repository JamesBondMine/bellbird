//
//  NoaEmojiPackageDetailViewController.h
//  NoaKit
//
//  Created by mac on 2023/10/25.
//

#import "NoaBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface NoaEmojiPackageDetailViewController : NoaBaseViewController

@property (nonatomic, assign) NSInteger supIndex;
@property (nonatomic, copy) NSString *stickersId;
@property (nonatomic, copy) NSString *stickersSetId;//表情包Id
@property (nonatomic, copy) void(^packageAddClick)(NSInteger index);

@end

NS_ASSUME_NONNULL_END
