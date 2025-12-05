//
//  NoaInviteFriendVC.m
//  NoaKit
//
//  Created by mac on 2022/9/22.
//

#import "NoaInviteFriendVC.h"
#import "NoaSearchView.h"
#import "NoaInviteFriendHeaderView.h"
#import "NoaInviteFriendCell.h"
#import "NoaMessageTools.h"
#import "NoaKnownTipView.h"
#import "NoaBaseUserModel.h"
#import "LingIMGroup.h"
#import "NoaNoDataView.h"
#import "NoaChatViewController.h"
#import "NoaExcursionSelectCell.h"
#import "NoaMassMessageSelectModel.h"
#import "NoaMassMessageGroupSelectedTopView.h"

@interface NoaInviteFriendVC () <ZSearchViewDelegate,UITableViewDataSource,UITableViewDelegate,ZBaseCellDelegate>

@property (nonatomic, strong) NoaSearchView *viewSearch;
@property (nonatomic, strong) NSMutableArray<NoaBaseUserModel *> *searchList;//搜索结果
@property (nonatomic, strong) NSMutableArray<NoaMassMessageSelectModel *> *selectModelList;//分组及子级
@property (nonatomic, strong) NSMutableArray<NoaBaseUserModel *> *selectedList;//选中的
@property (nonatomic, copy) NSString *searchStr;
@property (nonatomic, strong) NoaNoDataView *viewNoData;//无数据提示
@property (nonatomic, strong) NoaMassMessageGroupSelectedTopView *groupSelectedTopView;//已选择的

@end

@implementation NoaInviteFriendVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupNavUI];
    [self setupUI];
    [self setupLocalData];
    
    //顶部已选中有delete操作时，触发此通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(groupSelectedDeleteAction:) name:@"ZMassMessageSelectedGroupDeleteActionNotification" object:nil];
}
#pragma mark - 界面布局
- (void)setupNavUI {
    self.navTitleStr = LanguageToolMatch(@"创建群聊");
    self.navBtnRight.hidden = NO;
    [self.navBtnRight setTitle:LanguageToolMatch(@"完成") forState:UIControlStateNormal];
    [self.navBtnRight setTitleColor:COLORWHITE forState:UIControlStateNormal];
    self.navBtnRight.tkThemebackgroundColors = @[COLOR_CCCCCC, COLOR_CCCCCC_DARK];
    self.navBtnRight.layer.cornerRadius = DWScale(12);
    self.navBtnRight.layer.masksToBounds = YES;
    self.navBtnRight.titleLabel.numberOfLines = 2;
    self.navBtnRight.enabled = NO;
    [self.navBtnRight mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.navTitleLabel);
        make.trailing.equalTo(self.navView).offset(-DWScale(16));
        make.height.mas_equalTo(DWScale(32));
        CGSize textSize = [self.navBtnRight.titleLabel.text sizeWithFont:FONTR(14) constrainedToSize:CGSizeMake(10000, DWScale(32))];
        make.width.mas_equalTo(MIN(textSize.width+DWScale(28), 60));
    }];
    
}
- (void)setupUI {
    _viewSearch = [[NoaSearchView alloc] initWithPlaceholder:LanguageToolMatch(@"搜索")];
    _viewSearch.currentViewSearch = YES;
    _viewSearch.showClearBtn = YES;
    _viewSearch.returnKeyType = UIReturnKeyDefault;
    _viewSearch.delegate = self;
    [self.view addSubview:_viewSearch];
    [_viewSearch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.mas_equalTo(self.view);
        make.height.mas_equalTo(DWScale(38));
        make.top.mas_equalTo(self.view).offset(DNavStatusBarH + DWScale(6));
    }];
    

    _groupSelectedTopView = [[NoaMassMessageGroupSelectedTopView alloc] init];
    _groupSelectedTopView.selectedTopUserList = self.selectedList;
    [self.view addSubview:_groupSelectedTopView];
    [_groupSelectedTopView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.mas_equalTo(self.view);
        make.height.mas_equalTo(self.selectedList.count > 0 ? DWScale(95) : 0);
        make.top.mas_equalTo(_viewSearch.mas_bottom).offset(DWScale(16));
    }];
    
    [self.view addSubview:self.viewNoData];
    [self.viewNoData mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.mas_equalTo(self.view);
        make.top.mas_equalTo(self.groupSelectedTopView.mas_bottom).offset(DWScale(10));
        make.height.mas_equalTo(DWScale(60));
    }];
    
    [self.view addSubview:self.baseTableView];
    self.baseTableView.delegate = self;
    self.baseTableView.dataSource = self;
    self.baseTableView.delaysContentTouches = NO;
    [self.baseTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(-DHomeBarH);
        make.top.equalTo(self.groupSelectedTopView.mas_bottom).offset(DWScale(10));
    }];
    
    [self.baseTableView registerClass:[NoaInviteFriendCell class] forCellReuseIdentifier:[NoaInviteFriendCell cellIdentifier]];
    [self.baseTableView registerClass:[NoaExcursionSelectCell class] forCellReuseIdentifier:[NoaExcursionSelectCell cellIdentifier]];
    [self.baseTableView registerClass:[NoaInviteFriendHeaderView class] forHeaderFooterViewReuseIdentifier:NSStringFromClass([NoaInviteFriendHeaderView class])];
}

#pragma mark - 获取搜索数据
- (void)requestSearchList {
    //搜索
    if (![NSString isNil:self.searchStr]) {
        NSArray *showFriendList = [[IMSDKManager toolSearchMyFriendWith:_searchStr] mutableCopy];
        for (LingIMFriendModel *tempFriend in showFriendList) {
            if ((![NSString isNil:_friendUid] && [tempFriend.friendUserUID isEqualToString:self.friendUid]) || tempFriend.userType == 1) {
                //此处过滤处理
            } else {
                NoaBaseUserModel *baseUserModel = [[NoaBaseUserModel alloc] init];
                baseUserModel.userId = tempFriend.friendUserUID;
                baseUserModel.name = tempFriend.showName;
                baseUserModel.avatar = tempFriend.avatar;
                baseUserModel.roleId = tempFriend.roleId;
                baseUserModel.disableStatus = tempFriend.disableStatus;
                [self.searchList addObject:baseUserModel];
            }
        }
    }
    [self reloadInviteUI];
    [self.baseTableView reloadData];
}

#pragma mark - 初始化数据
- (void)setupLocalData {
    //最近联系人
    NSMutableArray *recentContactList = [NSMutableArray array];
    NSArray *localSessionArr = [IMSDKManager toolGetMySessionListFromSignlChatWithOffServer];
    for (LingIMSessionModel *obj in localSessionArr) {
        if (![NSString isNil:_friendUid] && [obj.sessionID isEqualToString:self.friendUid]) {
            //此处过滤处理
        } else {
            LingIMFriendModel *friendModel = [IMSDKManager toolCheckMyFriendWith:obj.sessionID];
            if (!friendModel) {
                continue;
            }
            
            if (friendModel.userType < 0 || friendModel.disableStatus < 0) {
                continue;
            }
            
            if (friendModel.userType != 1 && friendModel.disableStatus != 4) {//过滤系统级用户和已注销的用户
                NoaBaseUserModel *baseUserModel = [[NoaBaseUserModel alloc] init];
                baseUserModel.userId = obj.sessionID;
                baseUserModel.name = ![NSString isNil:friendModel.showName] ? friendModel.showName : (![NSString isNil:friendModel.nickname] ? friendModel.nickname : obj.sessionName);
                baseUserModel.avatar = obj.sessionAvatar;
                baseUserModel.roleId = friendModel.roleId;
                baseUserModel.showRole = YES;
                baseUserModel.disableStatus = friendModel.disableStatus;
                [recentContactList addObject:baseUserModel];
            }
        }
        if (recentContactList.count >= 50) {
            break;
        }
    }
    NSString *recentTitle = [NSString stringWithFormat:@"%@(%ld)",LanguageToolMatch(@"最新联系人"), recentContactList.count];
    NoaMassMessageSelectModel *model = [NoaMassMessageSelectModel new];
    model.title = recentTitle;
    model.list = recentContactList;
    model.isOpen = YES;
    model.isAllSelect = NO;
    [self.selectModelList addObject:model];
    
    //分组
    NSArray *localFriendGroupAr = [IMSDKManager toolGetMyFriendGroupList];
    for (LingIMFriendGroupModel *friendGroupModel in localFriendGroupAr) {
        //获取某个 好友分组 下的 好友列表(所有的，不包含已注销账号)
        NSString *friendGroupID = friendGroupModel.ugUuid;
        //找到该好友分组下的好友列表
        NSMutableArray *friendListForGroup = [NSMutableArray array];
        if (friendGroupModel.ugType == -1) {
            //默认分组
            NSArray *friendListTempY = [IMSDKManager toolGetMyFriendGroupFriendsWith:friendGroupID];
            NSArray *friendListTempN = [IMSDKManager toolGetMyFriendGroupFriendsWith:@""];
            [friendListForGroup addObjectsFromArray:friendListTempY];
            [friendListForGroup addObjectsFromArray:friendListTempN];
        }else {
            //用户自定义分组
            NSArray *friendListTemp = [IMSDKManager toolGetMyFriendGroupFriendsWith:friendGroupID];
            [friendListForGroup addObjectsFromArray:friendListTemp];
        }
        
        NSMutableArray *friendInGroupArr = [NSMutableArray array];
        for (LingIMFriendModel *tempFriend in friendListForGroup) {
            if ((![NSString isNil:_friendUid] && [tempFriend.friendUserUID isEqualToString:self.friendUid]) || tempFriend.userType == 1 || tempFriend.disableStatus == 4) {
                //此处过滤处理
            } else {
                NoaBaseUserModel *baseUserModel = [[NoaBaseUserModel alloc] init];
                baseUserModel.userId = tempFriend.friendUserUID;
                baseUserModel.name = ![NSString isNil:tempFriend.showName] ? tempFriend.showName : tempFriend.nickname;
                baseUserModel.avatar = tempFriend.avatar;
                baseUserModel.roleId = tempFriend.roleId;
                baseUserModel.showRole = YES;
                baseUserModel.disableStatus = tempFriend.disableStatus;
                
                [friendInGroupArr addObject:baseUserModel];
            }
        }
        NSString *groupFriendName = friendGroupModel.ugType == -1 ?(![NSString isNil:friendGroupModel.ugName] ? friendGroupModel.ugName : LanguageToolMatch(@"默认分组")) : friendGroupModel.ugName;
        NSString *groupFriendTitle = [NSString stringWithFormat:LanguageToolMatch(@"%@(%ld)"), groupFriendName, friendInGroupArr.count];
        NoaMassMessageSelectModel *model = [NoaMassMessageSelectModel new];
        model.title = groupFriendTitle;
        model.list = friendInGroupArr;
        model.isOpen = NO;
        model.isAllSelect = NO;
        [self.selectModelList addObject:model];
    }
    [self.baseTableView reloadData];

}

#pragma mark - Super
- (void)navBtnRightClicked {
    [HUD showActivityMessage:LanguageToolMatch(@"创建群聊中...")];

    WeakSelf
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObjectSafe:UserManager.userInfo.userUID forKey:@"ownerUid"];
    [dict setObjectSafe:UserManager.userInfo.nickname forKey:@"ownerNickname"];
    [dict setObjectSafe:UserManager.userInfo.userUID forKey:@"userUid"];
    __block NSMutableArray *groupMemberList = [NSMutableArray array];

    if (![NSString isNil:_friendUid]) {
        NSDictionary *dict = @{@"userUid" : _friendUid,@"nickName":_friendNickname};
        [groupMemberList addObjectIfNotNil:dict];
    }
    [self.selectedList enumerateObjectsUsingBlock:^(NoaBaseUserModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:obj.userId forKey:@"userUid"];
        [dict setValue:obj.name forKey:@"nickName"];
        [groupMemberList addObjectIfNotNil:dict];
    }];
    [dict setObjectSafe:groupMemberList forKey:@"groupMemberParams"];
    //创建群聊
    [IMSDKManager createGroupWith:dict onSuccess:^(id _Nullable data, NSString * _Nullable traceId) {
        LingIMGroup *groupInfoModel = [LingIMGroup mj_objectWithKeyValues:data];
        groupInfoModel.isMessageInform = 1;
        groupInfoModel.userGroupRole = 2;
        groupInfoModel.isActiveEnabled = 1;
        LingIMGroupModel *imGroupModel = [NoaMessageTools netWorkGroupModelToDBGroupModel:groupInfoModel];
        if (imGroupModel) {
            [IMSDKManager toolInsertOrUpdateGroupModelWith:imGroupModel];
        }
        [weakSelf createGroupSuccessWith:groupInfoModel];
    } onFailure:^(NSInteger code, NSString * _Nullable msg, NSString * _Nullable traceId) {
        [HUD showMessageWithCode:code errorMsg:msg];
    }];
}
- (void)createGroupSuccessWith:(LingIMGroup *)groupInfoModel {
    //延迟一下
//    WeakSelf
//
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//
//        dispatch_async(dispatch_get_main_queue(), ^{
            [HUD hideHUD];
            LingIMGroupModel *imGroupModel = [NoaMessageTools netWorkGroupModelToDBGroupModel:groupInfoModel];
            if (imGroupModel) {
                [IMSDKManager toolInsertOrUpdateGroupModelWith:imGroupModel];
            }
            
            //群聊创建成功后进入群聊
            NoaChatViewController *vc = [NoaChatViewController new];
            vc.groupInfo = groupInfoModel;
            vc.chatType = CIMChatType_GroupChat;
            vc.chatName = groupInfoModel.groupName;
            vc.sessionID = groupInfoModel.groupId;

            [self.navigationController pushViewController:vc animated:YES];
            //修改导航栏的栈
            self.navigationController.viewControllers = @[self.navigationController.viewControllers.firstObject,vc];
//        });
//    });
}

- (void)reloadInviteUI {
    if (![NSString isNil:_searchStr]) {
        self.baseTableView.hidden = !(self.searchList.count > 0);
        self.viewNoData.lblNoDataTip.text = self.searchList.count > 0 ? @"" : LanguageToolMatch(@"无搜索结果");
    }else {
        self.baseTableView.hidden = NO;
        self.viewNoData.lblNoDataTip.text = @"";
    }
}

#pragma mark - ZSearchViewDelegate
- (void)searchViewTextValueChanged:(NSString *)searchStr {
    _searchStr = [searchStr trimString];
    [self.searchList removeAllObjects];
    [self requestSearchList];
}


#pragma mark - event
- (void)cellClickAction:(NSIndexPath *)indexPath {
    if ([NSString isNil:self.searchStr]) {
        NoaBaseUserModel *model = self.selectModelList[indexPath.section].list[indexPath.row];
        if ([self.selectedList containsObject:model]) {
            [self.selectedList removeObject:model];
        } else {
            if (self.selectedList.count >= _maxNum) {
                NoaKnownTipView *viewTip = [NoaKnownTipView new];
                viewTip.lblTip.text = [NSString stringWithFormat:LanguageToolMatch(@"最多只能选择%ld人"),_maxNum];
                [viewTip knownTipViewSHow];
                return;
            }
            [self.selectedList addObject:model];
        }
        
    } else {
        NoaBaseUserModel *model = self.searchList[indexPath.row];
        if ([self.selectedList containsObject:model]) {
            [self.selectedList removeObject:model];
        } else {
            if (self.selectedList.count >= _maxNum) {
                NoaKnownTipView *viewTip = [NoaKnownTipView new];
                viewTip.lblTip.text = [NSString stringWithFormat:LanguageToolMatch(@"最多只能选择%ld人"),_maxNum];
                [viewTip knownTipViewSHow];
                return;
            }
            [self.selectedList addObject:model];
        }
    }
    [self checkSelectModelIsAllSelected];
    [self.baseTableView reloadData];
    [self navBtnRightRefresh];
    [self groupSelectedTopViewRefresh];
}

- (void)checkSelectModelIsAllSelected {
    for (NoaMassMessageSelectModel * selectModel in self.selectModelList) {
        selectModel.isAllSelect = YES;
        for (NoaBaseUserModel * userModel in selectModel.list) {
            if(![self.selectedList containsObject:userModel]){
                selectModel.isAllSelect = NO;
                break;
            }
        }
    }
}

- (void)groupSelectedDeleteAction:(NSNotification *)sender{
    //更新list
    NSNumber *deleteNum = sender.object;
    [self.selectedList removeObjectAtIndex:[deleteNum integerValue]];
    [self checkSelectModelIsAllSelected];
    [self.baseTableView reloadData];
    [self navBtnRightRefresh];
    [self groupSelectedTopViewRefresh];
}

- (void)groupSelectedTopViewRefresh {
    [_groupSelectedTopView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.mas_equalTo(self.view);
        make.height.mas_equalTo(self.selectedList.count > 0 ? DWScale(95) : 0);
        make.top.mas_equalTo(_viewSearch.mas_bottom).offset(DWScale(16));
    }];
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    _groupSelectedTopView.selectedTopUserList = self.selectedList;
}

- (void)navBtnRightRefresh {
    self.navBtnRight.tkThemebackgroundColors = @[COLOR_CCCCCC, COLOR_CCCCCC_DARK];
    self.navBtnRight.enabled = NO;
    if (self.selectedList.count > 0) {
        [self.navBtnRight setTitle:[NSString stringWithFormat:LanguageToolMatch(@"完成(%ld)"),self.selectedList.count] forState:UIControlStateNormal];
        if (self.selectedList.count >= _minNum) {
            self.navBtnRight.enabled = YES;
            self.navBtnRight.tkThemebackgroundColors = @[COLOR_5966F2, COLOR_5966F2_DARK];
        }
    }else {
        [self.navBtnRight setTitle:LanguageToolMatch(@"完成") forState:UIControlStateNormal];
        self.navBtnRight.enabled = NO;
    }

    [self.navBtnRight mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.navTitleLabel);
        make.trailing.equalTo(self.navView).offset(-DWScale(20));
        make.height.mas_equalTo(DWScale(32));
        CGSize textSize = [self.navBtnRight.titleLabel.text sizeWithFont:FONTR(14) constrainedToSize:CGSizeMake(10000, DWScale(32))];
        make.width.mas_equalTo(MIN(textSize.width+DWScale(28), 60));
    }];
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([NSString isNil:self.searchStr]) {
        return self.selectModelList.count;
    }
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([NSString isNil:self.searchStr]) {
        return self.selectModelList[section].isOpen ? self.selectModelList[section].list.count : 0;
    }
    return self.searchList.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([NSString isNil:self.searchStr]) {
        NoaExcursionSelectCell *cell = [tableView dequeueReusableCellWithIdentifier:[NoaExcursionSelectCell cellIdentifier] forIndexPath:indexPath];
        NoaBaseUserModel *model = self.selectModelList[indexPath.section].list[indexPath.row];
        [cell cellConfigBaseUserWith:model search:_searchStr];
        cell.selectedUser = [self.selectedList containsObject:model];
        return cell;
    } else {
        NoaInviteFriendCell *cell = [tableView dequeueReusableCellWithIdentifier:[NoaInviteFriendCell cellIdentifier] forIndexPath:indexPath];
        NoaBaseUserModel *model = self.searchList[indexPath.row];
        [cell cellConfigBaseUserWith:model search:_searchStr];
        cell.selectedUser = [self.selectedList containsObject:model];
        return cell;
    }
    
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([NSString isNil:self.searchStr]) {
        return [NoaExcursionSelectCell defaultCellHeight];
    }
    return [NoaInviteFriendCell defaultCellHeight];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    if ([NSString isNil:self.searchStr]) {
        NoaInviteFriendHeaderView *viewHeader = [tableView dequeueReusableHeaderFooterViewWithIdentifier:NSStringFromClass([NoaInviteFriendHeaderView class])];
        viewHeader.contentStr = self.selectModelList[section].title;
        viewHeader.isOpen = self.selectModelList[section].isOpen;
        viewHeader.isSelected = self.selectModelList[section].isAllSelect;
        WeakSelf
        [viewHeader setOpenCallback:^(bool isOpen) {
            weakSelf.selectModelList[section].isOpen = isOpen;
            [weakSelf.baseTableView reloadData];
        }];
        [viewHeader setSelectAllCallback:^(bool isAll) {
            if (isAll) {
                for (NoaBaseUserModel *obj in weakSelf.selectModelList[section].list) {
                    if (![weakSelf.selectedList containsObject:obj]) {
                        if (weakSelf.selectedList.count >= weakSelf.maxNum) {
                            NoaKnownTipView *viewTip = [NoaKnownTipView new];
                            viewTip.lblTip.text = [NSString stringWithFormat:LanguageToolMatch(@"最多只能选择%ld人"),weakSelf.maxNum];
                            [viewTip knownTipViewSHow];
                            weakSelf.selectModelList[section].isAllSelect = NO;
                            [weakSelf.baseTableView reloadData];
                            [weakSelf navBtnRightRefresh];
                            [weakSelf groupSelectedTopViewRefresh];
                            return;
                        }
                        [weakSelf.selectedList addObject:obj];
                    }
                }
                [weakSelf checkSelectModelIsAllSelected];
                weakSelf.selectModelList[section].isAllSelect = YES;
                [weakSelf.baseTableView reloadData];
                [weakSelf navBtnRightRefresh];
                [weakSelf groupSelectedTopViewRefresh];
            } else {
                weakSelf.selectModelList[section].isAllSelect = NO;
                for (NoaBaseUserModel *obj in weakSelf.selectModelList[section].list)  {
                    if ([weakSelf.selectedList containsObject:obj]) {
                        [weakSelf.selectedList removeObject:obj];
                    }
                }
                [weakSelf checkSelectModelIsAllSelected];
                [weakSelf.baseTableView reloadData];
                [weakSelf navBtnRightRefresh];
                [weakSelf groupSelectedTopViewRefresh];
            }
        }];
        
        return viewHeader;
    } else {
        return [UIView new];
    }
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if ([NSString isNil:self.searchStr]) {
        return DWScale(46);
    }
    return DWScale(0.01);
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self cellClickAction:indexPath];
}

#pragma mark - 懒加载
- (NoaNoDataView *)viewNoData {
    if (!_viewNoData) {
        _viewNoData = [[NoaNoDataView alloc] init];
        _viewNoData.tkThemebackgroundColors = @[COLORWHITE, COLOR_11];
    }
    return _viewNoData;
}

- (NSMutableArray<NoaBaseUserModel *> *)searchList {
    if (_searchList == nil) {
        _searchList = [NSMutableArray array];
    }
    return _searchList;
}

- (NSMutableArray<NoaMassMessageSelectModel *> *)selectModelList {
    if (_selectModelList == nil) {
        _selectModelList = [[NSMutableArray alloc] init];
    }
    return _selectModelList;
}

- (NSMutableArray<NoaBaseUserModel *> *)selectedList {
    if (_selectedList == nil) {
        _selectedList = [NSMutableArray array];
    }
    return _selectedList;
}

#pragma mark - life cycle
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
