//
//  NoaBaseVideoPlayerVC.h
//  NoaKit
//
//  Created by mac on 2022/9/24.
//

#import "NoaBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface NoaBaseVideoPlayerVC : NoaBaseViewController
//视频封面地址
@property (nonatomic, copy) NSString *videoCoverUrl;
//视频地址
@property (nonatomic, copy) NSString *videoUrl;
@end

NS_ASSUME_NONNULL_END
