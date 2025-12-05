//
//  UITabBar+Badge.m
//  NoaIMChatService
//
//  Created by mac on 2022/7/8.
//

#import "UITabBar+Badge.h"
#import "MBadgeView.h"

#define TabbarItemNums 3.0    //tabbar的数量

@class UITabBarButton;
@implementation UITabBar (Badge)

-(MBadgeView *)badgeViewAtIndex:(NSInteger)index{
    // 如果之前添加过，直接设置hidden为NO
    UIView * tabBarButton = [self __iconViewWithIndex:index];
      for (UIView *subView in tabBarButton.subviews) {
          if (subView.tag == 888 + index) {
              return (MBadgeView *)subView;
          }
    }
    //新建小红点
    MBadgeView *badgeView = [[MBadgeView alloc]init];
    badgeView.tag = 888 + index;
    badgeView.backgroundColor = HEXCOLOR(@"F93A2F");//颜色：红色
    badgeView.textLb.textColor = [UIColor whiteColor];
    badgeView.textLb.font = [UIFont systemFontOfSize:12.f];
    WeakSelf
    if(index == 1){
        badgeView.clearBlock = nil;
    }else{
        badgeView.clearBlock = ^{
            [weakSelf MessageReadAllMessage];
        };
    }
    UIImageView * icon = [tabBarButton valueForKey:@"_imageView"];
    [tabBarButton addSubview:badgeView];
    [tabBarButton bringSubviewToFront:badgeView];
    badgeView.layer.zPosition = 1;
    [badgeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(icon.mas_top);
        make.centerX.mas_equalTo(icon.mas_trailing);
    }];
    return badgeView;
    
}

#pragma mark - 显示红点
- (void)showBadgeAtItemIndex:(NSInteger)index textStr:(NSString *)textStr size:(CGSize)badgeSize tapBlock:(nonnull void (^)(void))tapBlock{
    
    MBadgeView * badgeView = [self badgeViewAtIndex:index];
    [badgeView setBadgeText:textStr];
    [badgeView setTapBlock:^{
        tapBlock();
    }];
   
}

// 获取图标所在View
- (UIView *)__iconViewWithIndex:(NSInteger)index {
    UITabBarItem *item = self.items[index];
    UIView *tabBarButton = [item valueForKey:@"_view"];
    return tabBarButton;
}

#pragma mark - 隐藏红点
- (void)hideBadgeAtItemIndex:(NSInteger)index{
    //移除小红点
    [self removeBadgeOnItemIndex:index];
}

//移除小红点
- (void)removeBadgeOnItemIndex:(NSInteger)index{
    MBadgeView * badgeView = [self badgeViewAtIndex:index];
    badgeView.hidden = YES;
}

//全部已读接口
- (void)MessageReadAllMessage {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObjectSafe:UserManager.userInfo.userUID forKey:@"userUid"];
    [IMSDKManager MessageReadAllMessageWith:dict onSuccess:^(id _Nullable data, NSString * _Nullable traceId) {
        NSString *lastSMsgId = (NSString *)data;
        [ZTOOL doInMain:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"sessionListAllRead" object:lastSMsgId];
        }];
    } onFailure:^(NSInteger code, NSString * _Nullable msg, NSString * _Nullable traceId) {
        
    }];
}

@end
