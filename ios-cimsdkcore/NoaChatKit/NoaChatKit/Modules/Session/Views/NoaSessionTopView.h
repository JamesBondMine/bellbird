//
//  NoaSessionTopView.h
//  NoaKit
//
//  Created by mac on 2022/9/23.
//

// 会话列表VC 顶部View

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^ZSessionTopAddBlock) (ZSessionMoreActionType actionType);
typedef void (^ZSessionTopSearchBlock) (void);
typedef void (^ZSessionTopAvatarTapBlock) (void);

@interface NoaSessionTopView : UIView
@property (nonatomic, copy) ZSessionTopSearchBlock searchBlock;
@property (nonatomic, copy) ZSessionTopAddBlock addBlock;
@property (nonatomic, copy) ZSessionTopAvatarTapBlock avatarTapBlock;
@property (nonatomic, assign) BOOL showLoading;

- (void)viewAppearUpdateUI;
@end

NS_ASSUME_NONNULL_END
