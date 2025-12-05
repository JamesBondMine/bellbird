//
//  NoaNewFriendListVC.m
//  NoaKit
//
//  Created by Mac on 2022/9/9.
//

#import "NoaNewFriendListVC.h"
#import "NoaSearchView.h"
#import "NoaNewFriendListCell.h"
#import "NoaNoDataView.h"

#import "NoaFriendApplyModel.h"
#import "NoaFriendReqModel.h"
#import "NoaFriendApplyPassVC.h"//好友申请验证通过
#import "NoaUserHomePageVC.h"//好友主页
#import <DZNEmptyDataSet/UIScrollView+EmptyDataSet.h>

@interface NoaNewFriendListVC () <UITableViewDataSource, UITableViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MGSwipeTableCellDelegate, NoaToolUserDelegate, ZNewFriendListCellDelegate>
@property (nonatomic, assign) NSInteger pageNum;
@property (nonatomic, strong) NoaNoDataView *viewNoMore;
@property (nonatomic, strong) NSMutableArray *hiddenApply;//隐藏好友申请，本地操作
@property (nonatomic, strong) NSMutableArray *readApply;//已读好友申请，本地操作
@property (nonatomic, strong) NSMutableArray *requestList;//好友申请列表
@end

@implementation NoaNewFriendListVC
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.baseTableView reloadData];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    _pageNum = 1;
    _requestList = [NSMutableArray array];
    
    [self getHiddenApplyData];
    [self getReadApplyData];
    
    [self initNavBar];
    [self initTableView];

    
    //增加收到好友请求的代理
    [IMSDKManager addUserDelegate:self];
    
}
- (void)cimToolUserFriendInvite:(FriendInviteMessage *)message{
    [self requestFriendApplyList];
}

//初始化导航
-(void)initNavBar{
    self.navLineView.hidden = YES;
    self.navTitleLabel.text = LanguageToolMatch(@"新朋友");
}

//初始化TableView
-(void)initTableView{
    [self defaultTableViewUI];
    self.baseTableView.dataSource = self;
    self.baseTableView.delegate = self;
    self.baseTableView.backgroundColor = UIColor.clearColor;
    self.baseTableView.delaysContentTouches = NO;
    self.baseTableView.emptyDataSetSource = self;
    self.baseTableView.emptyDataSetDelegate = self;
    self.baseTableView.mj_header = self.refreshHeader;
    self.baseTableView.mj_footer = self.refreshFooter;
    
    [self requestFriendApplyList];
    [HUD showActivityMessage:@""];
}

//刷新数据
- (void)headerRefreshData {
    _pageNum = 1;
    [self requestFriendApplyList];
}
- (void)footerRefreshData {
    _pageNum++;
    [self requestFriendApplyList];
}

#pragma mark - 数据请求
- (void)requestFriendApplyList {
    WeakSelf
    NSMutableDictionary *param = [NSMutableDictionary dictionary];
    [param setValue:@((_pageNum - 1) * 20) forKey:@"pageStart"];
    [param setValue:@(20) forKey:@"pageSize"];
    [param setValue:@(_pageNum) forKey:@"pageNumber"];
    [param setValue:UserManager.userInfo.userUID forKey:@"userUid"];
    
    [IMSDKManager getFriendApplyListFromServerWith:param onSuccess:^(id _Nullable data, NSString * _Nullable traceId) {
        [weakSelf.baseTableView.mj_footer endRefreshing];
        [weakSelf.baseTableView.mj_header endRefreshing];
        [HUD hideHUD];
        if (weakSelf.pageNum  == 1) {
            [weakSelf.requestList removeAllObjects];
        }
        
        if ([data isKindOfClass:[NSDictionary class]]) {
            
            NSDictionary *reqDict = (NSDictionary *)data;
            NSArray *reqArr = [reqDict objectForKeySafe:@"rows"];
            [reqArr enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NoaFriendApplyModel *model = [NoaFriendApplyModel mj_objectWithKeyValues:obj];
                if (![weakSelf.hiddenApply containsObject:[NSString stringWithFormat:@"%@-%@",model.hashKey,model.sendTime]]) {
                    //本地没有隐藏该申请，好友没有被删除
                    [weakSelf.requestList addObjectIfNotNil:model];
                }
            }];
            
            if (reqArr.count < 20) {
                weakSelf.baseTableView.mj_footer = nil;
            } else {
                if (!weakSelf.baseTableView.mj_footer) {
                    weakSelf.baseTableView.mj_footer = weakSelf.refreshFooter;
                }
            }
            
            [weakSelf.baseTableView reloadData];
            
            [weakSelf handleNewFriendNum];
        }
    } onFailure:^(NSInteger code, NSString * _Nullable msg, NSString * _Nullable traceId) {
        [HUD showMessageWithCode:code errorMsg:msg];
    }];
}

//获得已删除隐藏好友申请
- (void)getHiddenApplyData {
    NSString *hashKeyStr = [[MMKV defaultMMKV] getStringForKey:@"HiddenFriendApply"];
    NSArray *hiddenArr = [hashKeyStr componentsSeparatedByString:@","];
    _hiddenApply = [NSMutableArray arrayWithArray:hiddenArr];
}
//获得已读好友申请
- (void)getReadApplyData {
    NSString *hashKeyStr = [[MMKV defaultMMKV] getStringForKey:@"ReadFriendApply"];
    NSArray *readArr = [hashKeyStr componentsSeparatedByString:@","];
    _readApply = [NSMutableArray arrayWithArray:readArr];
}
//好友申请已读
- (void)makeApplyRead {
    WeakSelf
    [self.requestList enumerateObjectsUsingBlock:^(NoaFriendApplyModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (obj.beStatus == 0 && ![obj.fromUserUid isEqualToString:UserManager.userInfo.userUID] && ![weakSelf.readApply containsObject:[NSString stringWithFormat:@"%@-%@",obj.hashKey, obj.sendTime]]){
            [weakSelf.readApply addObjectIfNotNil:[NSString stringWithFormat:@"%@-%@",obj.hashKey, obj.sendTime]];
        }
    }];
    NSString *hiddenStr = [_readApply componentsJoinedByString:@","];
    [[MMKV defaultMMKV] setString:hiddenStr forKey:@"ReadFriendApply"];
    
}
#pragma mark - MGSwipeTableCellDelegate
- (BOOL)swipeTableCell:(MGSwipeTableCell *)cell canSwipe:(MGSwipeDirection)direction fromPoint:(CGPoint)point {
    return YES;
}
- (NSArray<UIView *> *)swipeTableCell:(MGSwipeTableCell *)cell swipeButtonsForDirection:(MGSwipeDirection)direction swipeSettings:(MGSwipeSettings *)swipeSettings expansionSettings:(MGSwipeExpansionSettings *)expansionSettings {
    
    swipeSettings.transition = MGSwipeTransitionBorder;//动画效果
    swipeSettings.enableSwipeBounces = NO;
    expansionSettings.buttonIndex = -1;//可展开按钮索引，即滑动自动触发按钮下标
    expansionSettings.fillOnTrigger = NO;//是否填充
    expansionSettings.threshold = 1.0;//触发阈值
    
    NSIndexPath *cellIndex = [self.baseTableView indexPathForCell:cell];
//    LingIMSessionModel *model = [_sessionList objectAtIndexSafe:cellIndex.row];
    WeakSelf
    if (direction == MGSwipeDirectionRightToLeft) {
        MGSwipeButton *btnDelete = [MGSwipeButton buttonWithTitle:LanguageToolMatch(@"删除") icon:ImgNamed(@"s_session_delete") backgroundColor:HEXCOLOR(@"FF504E") callback:^BOOL(MGSwipeTableCell * _Nonnull cell) {
            [weakSelf deleteDataAction:cellIndex];
            return NO;
        }];
        btnDelete.titleLabel.font = FONTR(12);
        btnDelete.buttonWidth = DWScale(86);
        [btnDelete setBtnImageAlignmentType:ButtonImageAlignmentTypeTop imageSpace:DWScale(6)];
        
        return @[btnDelete];

        
    }else {
        return @[];
    }
    
}
- (void)swipeTableCell:(MGSwipeTableCell *)cell didChangeSwipeState:(MGSwipeState)state gestureIsActive:(BOOL)gestureIsActive {
    NSString * str;
    switch (state) {
        case MGSwipeStateNone: str = @"None"; break;
        case MGSwipeStateSwippingLeftToRight: str = @"右滑"; break;
        case MGSwipeStateSwippingRightToLeft: str = @"左滑"; break;
        case MGSwipeStateExpandingLeftToRight: str = @"右滑展开"; break;
        case MGSwipeStateExpandingRightToLeft: str = @"左滑展开"; break;
    }
    DLog(@"手势状态:%@------%@",str, gestureIsActive ? @"开始" : @"结束");
}

#pragma mark - Tableview delegate dataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _requestList.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return DWScale(68);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NoaNewFriendListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NoaNewFriendListCell"];
    if (cell == nil){
        cell = [[NoaNewFriendListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NoaNewFriendListCell"];
        cell.delegate = self;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    NoaFriendApplyModel *model = [self.requestList objectAtIndexSafe:indexPath.row];
    cell.model = model;
    WeakSelf
    cell.stateBtnClick = ^{
        [weakSelf dealFriendApply:model];
    };
    
    cell.cellDelegate = self;
    cell.cellIndexPath = indexPath;
    
    return cell;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self handleNewFriendNum];
}

- (void)handleNewFriendNum {
    NSMutableArray *list = [[MMKV defaultMMKV] getObjectOfClass:[NSMutableArray class] forKey:[NSString stringWithFormat:@"%@_%@",FriendSyncReqList, UserManager.userInfo.userUID]];
    NSArray *indexPathArr = [self.baseTableView indexPathsForVisibleRows];
    if (indexPathArr.count > 0 && self.requestList.count > 0) {
        NSIndexPath *firstIndexPath = [indexPathArr firstObject];
        if ((firstIndexPath.row + indexPathArr.count - 1) > (self.requestList.count - 1)) {
            return;
        }
    
        NSRange range = NSMakeRange(firstIndexPath.row, indexPathArr.count);
        if(NSMaxRange(range) <= self.requestList.count){
            NSArray *indexMessageArr = [self.requestList subarrayWithRange:range];
            for (int i = 0; i < indexMessageArr.count; i++) {
                for (int j = 0; j < list.count; j++) {
                    NoaFriendApplyModel *model = [indexMessageArr objectAtIndexSafe:i];
                    NoaFriendReqModel *reqModel = [list objectAtIndexSafe:j];
                    if ([model.hashKey isEqualToString:reqModel.hashKey]) {
                        [list removeObjectAtIndexSafe:j];
                    }
                }
            }
            [[MMKV defaultMMKV] setObject:list forKey:[NSString stringWithFormat:@"%@_%@",FriendSyncReqList, UserManager.userInfo.userUID]];
            
            //好友申请红点，看过就消失
            [IMSDKManager toolUpdateFriendApplyCount:list.count];
            //好友申请红点变化
            [[NSNotificationCenter defaultCenter] postNotificationName:@"FriendApplyCountChange" object:nil];
        }
    }
}

#pragma mark - ZNewFriendListCellDelegate
- (void)cellDidSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NoaFriendApplyModel *model = [self.requestList objectAtIndexSafe:indexPath.row];
    [self headerFriend:model];
}

//头像点击事件
- (void)headerFriend:(NoaFriendApplyModel *)model {
    NSString *userID;
    if ([model.fromUserUid isEqualToString:UserManager.userInfo.userUID]) {
        //我发起的好友申请
        userID = model.beUserUid;
    }else {
        //对方发起的好友申请
        userID = model.fromUserUid;
    }
    LingIMFriendModel *friendModel = [IMSDKManager toolCheckMyFriendWith:userID];
    if (friendModel) {
        //已是好友
        NoaUserHomePageVC *vc = [NoaUserHomePageVC new];
        vc.userUID = userID;
        vc.groupID = @"";
        [self.navigationController pushViewController:vc animated:YES];
    }else {
        //不是好友
        NoaFriendApplyPassVC *vc = [NoaFriendApplyPassVC new];
        vc.applyModel = model;
        [self.navigationController pushViewController:vc animated:YES];
    }
    
}
//好友申请处理
- (void)dealFriendApply:(NoaFriendApplyModel *)model {
    if (model.beStatus == 0) {
        //申请中
        if (![model.fromUserUid isEqualToString:UserManager.userInfo.userUID]) {
            //对方发起的好友申请，通过验证
            WeakSelf
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:model.fromUserUid forKey:@"friendUserUid"];
            [dict setValue:UserManager.userInfo.userUID forKey:@"userUid"];
            [IMSDKManager confirmFriendApplyWith:dict onSuccess:^(id _Nullable data, NSString * _Nullable traceId) {
                [HUD showMessage:LanguageToolMatch(@"添加成功")];
                model.beStatus = 1;
                [weakSelf.baseTableView reloadData];
                [weakSelf postNotificationWith:model];
            } onFailure:^(NSInteger code, NSString * _Nullable msg, NSString * _Nullable traceId) {
                [HUD showMessageWithCode:code errorMsg:msg];
            }];
        }
    }
}

//删除好友申请
- (void)deleteDataAction:(NSIndexPath *)indexPath {
    
    //好友申请列表界面隐藏采用hashKey字段
    NoaFriendApplyModel *model = [self.requestList objectAtIndexSafe:indexPath.row];
    [_hiddenApply addObjectIfNotNil:[NSString stringWithFormat:@"%@-%@",model.hashKey,model.sendTime]];
    NSString *hiddenStr = [_hiddenApply componentsJoinedByString:@","];
    [[MMKV defaultMMKV] setString:hiddenStr forKey:@"HiddenFriendApply"];
    
    
    [self.requestList removeObjectAtIndexSafe:indexPath.row];
    [self.baseTableView reloadData];
    
    //从已读列表里删除
    if ([_readApply containsObject:[NSString stringWithFormat:@"%@-%@",model.hashKey,model.sendTime]]) {
        [_readApply removeObject:[NSString stringWithFormat:@"%@-%@",model.hashKey,model.sendTime]];
        NSString *hiddenStr = [_readApply componentsJoinedByString:@","];
        [[MMKV defaultMMKV] setString:hiddenStr forKey:@"ReadFriendApply"];
        
    }
    
}

//发送好友添加成功的通知
- (void)postNotificationWith:(NoaFriendApplyModel *)model {
    LingIMFriendModel *friendModel = [LingIMFriendModel new];
    friendModel.nickname = model.nickname;
    friendModel.friendUserUID = model.fromUserUid;
    friendModel.avatar = model.fromUserAvatar;
    friendModel.showName = model.nickname;
    [IMSDKManager toolAddMyFriendWith:friendModel];
    
    //从已读列表里删除
    if ([_readApply containsObject:[NSString stringWithFormat:@"%@-%@",model.hashKey,model.sendTime]]) {
        [_readApply removeObject:[NSString stringWithFormat:@"%@-%@",model.hashKey,model.sendTime]];
        NSString *hiddenStr = [_readApply componentsJoinedByString:@","];
        [[MMKV defaultMMKV] setString:hiddenStr forKey:@"ReadFriendApply"];
        
    }
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

#pragma mark - DZNEmptyDataSetSource
- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    NSString *string = LanguageToolMatch(@"暂无好友申请");
    __block NSMutableAttributedString *accessAttributeString;
    self.view.tkThemeChangeBlock = ^(id  _Nullable itself, NSUInteger themeIndex) {
        switch (themeIndex) {
            case 1:
            {
                //暗黑
                accessAttributeString  = [[NSMutableAttributedString alloc] initWithString:string attributes:@{NSFontAttributeName:FONTR(14),NSForegroundColorAttributeName:COLOR_99}];
            }
                break;
                
            default:
            {
                accessAttributeString  = [[NSMutableAttributedString alloc] initWithString:string attributes:@{NSFontAttributeName:FONTR(14),NSForegroundColorAttributeName:COLOR_00}];
            }
                break;
        }
    };
    
    return accessAttributeString;
}
//图片距离中心偏移量
- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView {
    return -DWScale(100);
}
//空态图片
- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView {
    return ImgNamed(@"c_no_friend_add");
}

#pragma mark - DZNEmptyDataSetDelegate
//允许滑动
- (BOOL)emptyDataSetShouldAllowScroll:(UIScrollView *)scrollView {
    return NO;
}

#pragma mark - 懒加载
- (NoaNoDataView *)viewNoMore {
    if (!_viewNoMore) {
        _viewNoMore = [[NoaNoDataView alloc] initWithFrame:CGRectMake(0, 0, DScreenWidth, DWScale(30))];
        _viewNoMore.lblNoDataTip.text = LanguageToolMatch(@"我是有底线的");
        _viewNoMore.tkThemebackgroundColors = @[COLORWHITE, COLOR_11];
    }
    return _viewNoMore;
}
@end
