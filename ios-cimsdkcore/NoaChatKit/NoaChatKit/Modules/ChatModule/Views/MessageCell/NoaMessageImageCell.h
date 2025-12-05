//
//  NoaMessageImageCell.h
//  NoaKit
//
//  Created by Mac on 2022/9/28.
//

#import "NoaMessageContentBaseCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface NoaMessageImageCell : NoaMessageContentBaseCell

/// UI仅控制：进入屏内时启动动图播放
- (void)startGifPlayback;

/// UI仅控制：离屏/复用时停止动图播放
- (void)stopGifPlayback;

@end

NS_ASSUME_NONNULL_END
