//
//  NoaChatMultiSelectViewController.m
//  NoaKit
//
//  Created by Mac on 2023/4/11.
//

#import "NoaChatMultiSelectViewController.h"
#import "NoaSearchView.h"
#import "NoaChatMultiSelectedView.h"
#import "NoaChatMultiSelectHeaderView.h"
#import "NoaChatMultiSelectCell.h"
#import "NoaNoDataView.h"
#import "NoaMessageTools.h"
#import "NoaMessageForwardTipView.h"
#import "NoaKnownTipView.h"
#import "SyncMutableArray.h"
#import "NoaChatMultiSelectTipsView.h"
#import "NoaChatMultiSelectSendHander.h"
#import "NoaMessageAlertView.h"
#import "NoaMessageForwardFailVC.h"
#import "NoaForwardMsgPrecheckModel.h"
#import "NoaMassMessageSelectModel.h"
#import "NoaExcursionSelectCell.h"
#import "NoaMassMessageGroupSelectedTopView.h"
#import "NoaInviteFriendHeaderView.h"
#import "NoaInviteFriendCell.h"

#define Max_Selected_Num            50   //最大选取数量
#define List_Show_Type_Default      1   //默认：只显示 最近会话
#define List_Show_Type_Search       2   //搜索结果：只显示 联系人和群聊

@interface NoaChatMultiSelectViewController () <ZSearchViewDelegate,UITableViewDataSource,UITableViewDelegate,ZBaseCellDelegate>

@property (nonatomic, strong) NoaNoDataView *viewNoData;

@property (nonatomic, strong) NoaSearchView *viewSearch;
@property (nonatomic, copy) NSString *searchStr;

@property (nonatomic, strong) NoaChatMultiSelectSendHander *multiSendHander;

@property (nonatomic, strong) NSMutableArray<NoaMassMessageSelectModel *> *selectModelList;//分组及子级
@property (nonatomic, strong) NoaMassMessageGroupSelectedTopView *groupSelectedTopView;//已选择的
@property (nonatomic, strong) NSMutableArray<NoaBaseUserModel *> *searchList;//搜索结果
@property (nonatomic, strong) NSMutableArray<NoaBaseUserModel *> *selectedList; //已选取的会话
@property (nonatomic, strong) NSMutableArray<NoaBaseUserModel *> *disableList;//不符合时间间隔的列表
@end

@implementation NoaChatMultiSelectViewController

- (void)viewWillAppear:(BOOL)animated{
    //隐藏导系统的航栏，使用自定义的navbar
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupNavUI];
    [self setupUI];
    [self setupLocalData];
    self.view.tkThemebackgroundColors = @[COLORWHITE, COLOR_11];
    
    //顶部已选中有delete操作时，触发此通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(groupSelectedDeleteAction:) name:@"ZMassMessageSelectedGroupDeleteActionNotification" object:nil];
}

- (void)setupNavUI {
    self.navTitleStr = LanguageToolMatch(@"选择一个聊天");
    self.navBtnRight.hidden = NO;
    [self.navBtnRight setTitle:LanguageToolMatch(@"完成") forState:UIControlStateNormal];
    [self.navBtnRight setTitleColor:COLORWHITE forState:UIControlStateNormal];
    self.navBtnRight.tkThemebackgroundColors = @[COLOR_CCCCCC, COLOR_CCCCCC_DARK];
    self.navBtnRight.layer.cornerRadius = DWScale(12);
    self.navBtnRight.layer.masksToBounds = YES;
    [self.navBtnRight mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.navTitleLabel);
        make.trailing.equalTo(self.navView).offset(-DWScale(20));
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
        make.top.mas_equalTo(_groupSelectedTopView.mas_bottom).offset(DWScale(10));
        make.height.mas_equalTo(DWScale(60));
    }];
    
    [self.view addSubview:self.baseTableView];
    self.baseTableView.delegate = self;
    self.baseTableView.dataSource = self;
    self.baseTableView.delaysContentTouches = NO;
    [self.baseTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(-DHomeBarH);
        make.top.equalTo(_groupSelectedTopView.mas_bottom).offset(DWScale(10));
    }];
    
    [self.baseTableView registerClass:[NoaInviteFriendCell class] forCellReuseIdentifier:[NoaInviteFriendCell cellIdentifier]];
    [self.baseTableView registerClass:[NoaExcursionSelectCell class] forCellReuseIdentifier:[NoaExcursionSelectCell cellIdentifier]];
    [self.baseTableView registerClass:[NoaInviteFriendHeaderView class] forHeaderFooterViewReuseIdentifier:NSStringFromClass([NoaInviteFriendHeaderView class])];
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

#pragma mark - 初始化数据
- (void)setupLocalData {
    //最近联系人
    NSMutableArray *recentContactList = [NSMutableArray array];
    NSArray *localSessionArr = [IMSDKManager toolGetMySessionListWithOffServer];
    for (LingIMSessionModel *obj in localSessionArr) {
        if (obj.sessionType == CIMSessionTypeSingle) {
            LingIMFriendModel *friendModel = [IMSDKManager toolCheckMyFriendWith:obj.sessionID];
            if (friendModel.userType == 1) {
                //此处过滤处理
            } else {
                if (friendModel && friendModel.disableStatus != 4) {
                    NoaBaseUserModel *baseUserModel = [[NoaBaseUserModel alloc] init];
                    baseUserModel.userId = obj.sessionID;
                    baseUserModel.name = obj.sessionName;
                    baseUserModel.avatar = obj.sessionAvatar;
                    baseUserModel.roleId = friendModel.roleId;
                    baseUserModel.showRole = YES;
                    baseUserModel.isGroup = obj.sessionType == CIMSessionTypeGroup;
                    [recentContactList addObject:baseUserModel];
                }
            }
        }
        if (obj.sessionType == CIMSessionTypeGroup) {
            NoaBaseUserModel *baseUserModel = [[NoaBaseUserModel alloc] init];
            baseUserModel.userId = obj.sessionID;
            baseUserModel.name = obj.sessionName;
            baseUserModel.avatar = obj.sessionAvatar;
            baseUserModel.roleId = obj.roleId;
            baseUserModel.isGroup = obj.sessionType == CIMSessionTypeGroup;
            baseUserModel.lastSendMsgTime = obj.lastSendMsgTime;
            baseUserModel.isOwerOrManager = [self currentGroupIsOwnerOrManager:obj.sessionID];
            [recentContactList addObject:baseUserModel];
        }
        
        if (recentContactList.count >= 50) {
            break;
        }
    }
    NSString *recentTitle = [NSString stringWithFormat:@"%@(%ld)",LanguageToolMatch(@"最近会话"), recentContactList.count];
    NoaMassMessageSelectModel *model = [NoaMassMessageSelectModel new];
    model.title = recentTitle;
    model.list = recentContactList;
    model.isOpen = YES;
    model.isAllSelect = NO;
    [self.selectModelList addObject:model];
    
    //群组
    //我的所有群聊
    NSMutableArray *groupList = [NSMutableArray array];
    NSArray *groupArr = [[IMSDKManager toolGetMyGroupList] mutableCopy];
    [groupArr enumerateObjectsUsingBlock:^(LingIMGroupModel *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NoaBaseUserModel *baseUserModel = [[NoaBaseUserModel alloc] init];
        baseUserModel.userId = obj.groupId;
        baseUserModel.name = obj.groupName;
        baseUserModel.avatar = obj.groupAvatar;
        baseUserModel.roleId = 0;
        baseUserModel.disableStatus = obj.groupStatus;
        baseUserModel.isGroup = YES;
        baseUserModel.lastSendMsgTime = [self currentGroupLastMsgTime:obj.groupId];
        baseUserModel.isOwerOrManager = [self currentGroupIsOwnerOrManager:obj.groupId];
        [groupList addObject:baseUserModel];
    }];
    NSString *groupTitle = [NSString stringWithFormat:@"%@(%ld)",LanguageToolMatch(@"群聊"), groupList.count];
    NoaMassMessageSelectModel *groupModel = [NoaMassMessageSelectModel new];
    groupModel.title = groupTitle;
    groupModel.list = groupList;
    groupModel.isOpen = NO;
    groupModel.isAllSelect = NO;
    [self.selectModelList addObject:groupModel];
    
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
            if (tempFriend.userType != 1 && tempFriend.disableStatus != 4) {
                NoaBaseUserModel *baseUserModel = [[NoaBaseUserModel alloc] init];
                baseUserModel.userId = tempFriend.friendUserUID;
                baseUserModel.name = tempFriend.showName;
                baseUserModel.avatar = tempFriend.avatar;
                baseUserModel.roleId = tempFriend.roleId;
                baseUserModel.showRole = YES;
                baseUserModel.disableStatus = tempFriend.disableStatus;
                baseUserModel.isGroup = NO;
                [friendInGroupArr addObject:baseUserModel];
            }
        }
        NSString *groupFriendName = friendGroupModel.ugType == -1 ? (![NSString isNil:friendGroupModel.ugName] ? friendGroupModel.ugName : LanguageToolMatch(@"默认分组")) : friendGroupModel.ugName;
        NSString *groupFriendTitle = [NSString stringWithFormat:LanguageToolMatch(@"%@(%ld)"), groupFriendName, friendInGroupArr.count];
        NoaMassMessageSelectModel *model = [NoaMassMessageSelectModel new];
        model.title = groupFriendTitle;
        model.list = friendInGroupArr;
        model.isOpen = NO;
        model.isAllSelect = NO;
        [self.selectModelList addObject:model];
    }
    [self checkSelectModelIsAllSelected];
    [self.baseTableView reloadData];
    [self navBtnRightRefresh];
    [self groupSelectedTopViewRefresh];
}

#pragma mark - Action
- (void)cellClickAction:(NSIndexPath *)indexPath {
    if ([NSString isNil:self.searchStr]) {
        NoaBaseUserModel *model = self.selectModelList[indexPath.section].list[indexPath.row];
        if ([self.selectedList containsObject:model]) {
            [self.selectedList removeObject:model];
        } else {
            [self.selectedList addObject:model];
        }
        
    } else {
        NoaBaseUserModel *model = self.searchList[indexPath.row];
        if ([self.selectedList containsObject:model]) {
            [self.selectedList removeObject:model];
        } else {
            [self.selectedList addObject:model];
        }
    }
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self checkSelectModelIsAllSelected];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.baseTableView reloadData];
            [self navBtnRightRefresh];
            [self groupSelectedTopViewRefresh];
        });
    });
    
}
- (void)checkSelectModelIsAllSelected {
    for (int i = 0; i < self.selectModelList.count; i++) {
        NoaMassMessageSelectModel *selectModel = self.selectModelList[i];
        selectModel.isAllSelect = YES;
        for (int j = 0; j < selectModel.list.count; j++) {
            NoaBaseUserModel *userModel = selectModel.list[j];
            if (![self.selectedList containsObject:userModel]) {
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
    if (self.selectedList.count > 0) {
        [self.navBtnRight setTitle:[NSString stringWithFormat:LanguageToolMatch(@"完成(%ld)"),self.selectedList.count] forState:UIControlStateNormal];
        self.navBtnRight.tkThemebackgroundColors = @[COLOR_5966F2, COLOR_5966F2_DARK];
        self.navBtnRight.enabled = YES;
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

- (BOOL)currentGroupIsOwnerOrManager:(NSString *)sessionID {
    __block BOOL isOwnerOrManager = NO;
    NSArray *groupOwnerMangerArr = [IMSDKManager imSdkGetGroupOwnerAndManagerWith:sessionID];
    [groupOwnerMangerArr enumerateObjectsUsingBlock:^(LingIMGroupMemberModel *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.userUid isEqualToString:UserManager.userInfo.userUID]) {
            isOwnerOrManager = YES;
            *stop = YES;
        }
    }];
    return isOwnerOrManager;
}

- (long long)currentGroupLastMsgTime:(NSString *)sessionID {
    LingIMSessionModel *sessionModel = [IMSDKManager toolCheckMySessionWith:sessionID];
    if (sessionModel) {
        return sessionModel.lastSendMsgTime;
    } else {
        return 0;
    }
}

- (void)navBtnRightClicked {
    [self.disableList removeAllObjects];
    NSMutableArray *selectedReceverInfoList = [NSMutableArray array];
    __block NSMutableArray *newSelectedList = [NSMutableArray array];
    __weak typeof(self) weakSelf = self;
    [self.selectedList enumerateObjectsUsingBlock:^(NoaBaseUserModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.isGroup) {
            if (obj.isOwerOrManager) {
                [newSelectedList addObject:obj];
            } else {
                if ([NSDate currentTimeIntervalWithMillisecond] - obj.lastSendMsgTime >=
                    (ZHostTool.appSysSetModel.groupMessageInterval == 0 ? (2 * 1000) : ZHostTool.appSysSetModel.groupMessageInterval)) {
                    [newSelectedList addObject:obj];
                } else {
                    [weakSelf.disableList addObject:obj];
                }
            }
        } else {
            [newSelectedList addObject:obj];
        }
        
    }];
    if (newSelectedList.count <= 0) {
        NSMutableArray<NoaForwardMsgPrecheckModel *> *newErrorInfoList = [NSMutableArray array];
        [self.disableList enumerateObjectsUsingBlock:^(NoaBaseUserModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NoaForwardDialogModel *dialogModel = [[NoaForwardDialogModel alloc] init];
            dialogModel.avatar = obj.avatar;
            dialogModel.nickname = obj.name;
            dialogModel.dialogType = (obj.isGroup ? CIMChatType_GroupChat : CIMChatType_SingleChat);
            dialogModel.dialogId = [obj.userId integerValue];
            
            NoaForwardExceptionModel *exceptionModel = [NoaForwardExceptionModel new];
            exceptionModel.code = NetWork_Error_Group_Interval;

            NoaForwardMsgPrecheckModel *precheckModel = [NoaForwardMsgPrecheckModel new];
            precheckModel.dialogInfo = dialogModel;
            precheckModel.exceptionInfo = exceptionModel;
            
            [newErrorInfoList addObject:precheckModel];
        }];
        
        NoaMessageAlertView *forwardFailAlert = [[NoaMessageAlertView alloc] initWithMsgAlertType:ZMessageAlertTypeTitle supView:self.view];
        forwardFailAlert.showClose = YES;
        forwardFailAlert.lblTitle.text = LanguageToolMatch(@"提示");
        forwardFailAlert.lblContent.text = LanguageToolMatch(@"所选会话存在异常，继续发送将排除异常会话");
        [forwardFailAlert.btnSure setTitle:LanguageToolMatch(@"继续发送") forState:UIControlStateNormal];
        [forwardFailAlert.btnSure setTkThemeTitleColor:@[COLORWHITE, COLORWHITE] forState:UIControlStateNormal];
        forwardFailAlert.btnSure.tkThemebackgroundColors = @[[COLOR_5966F2 colorWithAlphaComponent:0.3], [COLOR_5966F2 colorWithAlphaComponent:0.3]];
        forwardFailAlert.btnSure.enabled = NO;
        [forwardFailAlert.btnCancel setTitle:LanguageToolMatch(@"异常详情") forState:UIControlStateNormal];
        [forwardFailAlert.btnCancel setTkThemeTitleColor:@[COLOR_11, COLOR_11_DARK] forState:UIControlStateNormal];
        forwardFailAlert.btnCancel.tkThemebackgroundColors = @[COLOR_F6F6F6, COLOR_F6F6F6_DARK];
        [forwardFailAlert alertShow];
        forwardFailAlert.sureBtnBlock = ^(BOOL isCheckBox) {
        };
        forwardFailAlert.cancelBtnBlock = ^{
            //跳转异常详情
            NoaMessageForwardFailVC *failVC = [[NoaMessageForwardFailVC alloc] init];
            failVC.forwardErroInfoList = newErrorInfoList;
            [weakSelf.navigationController pushViewController:failVC animated:YES];
        };
        return;
    }
    
    for (int i = 0; i < self.selectedList.count; i++) {
        NoaBaseUserModel *model = [self.selectedList objectAtIndex:i];
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        [dic setObjectSafe:[NSNumber numberWithInteger:model.isGroup ? CIMChatType_GroupChat : CIMChatType_SingleChat] forKey:@"dialogType"];
        [dic setObjectSafe:model.userId forKey:@"dialogId"];
        [dic setObjectSafe:model.avatar forKey:@"avatar"];
        [dic setObjectSafe:model.name forKey:@"nickname"];
        [selectedReceverInfoList addObject:dic];
    }
    //弹窗
    if (self.multiSelectType == ZMultiSelectTypeSingleForward || self.multiSelectType == ZMultiSelectTypeMergeForward) {
        //转发消息
        NoaMessageForwardTipView *viewTip = [[NoaMessageForwardTipView alloc] initWithForwardMsg:self.forwardMsgList toAvatarList:selectedReceverInfoList mergeMsgCount:self.mergeMsgCount fromSessionId:self.fromSessionId multiSelectType:self.multiSelectType];
        [viewTip viewShow];
        viewTip.sureClick = ^{
            //单条转发、逐条转发、合并转发
            [weakSelf checkSelectedRecevierComplianceWithRecevierIdArr:[selectedReceverInfoList copy]];
        };
    }
    if (self.multiSelectType == ZMultiSelectTypeRecommentCard) {
        //推荐名片
        NSString *tipsContent = [NSString stringWithFormat:@"%@%@", LanguageToolMatch(@"[个人名片]"), weakSelf.cardFriendInfo.nickname];
        NoaChatMultiSelectTipsView *viewTip = [[NoaChatMultiSelectTipsView alloc] initWithContent:tipsContent toAvatarList:selectedReceverInfoList];
        [viewTip viewShow];
        viewTip.sureClick = ^{
            [weakSelf checkSelectedRecevierComplianceWithRecevierIdArr:[selectedReceverInfoList copy]];
        };
    }
    if (self.multiSelectType == ZMultiSelectTypeShareQRImg) {
        //分享二维码
        NSString *tipsContent = [NSString stringWithFormat:@"%@%@", LanguageToolMatch(@"[图片]"), LanguageToolMatch(@"二维码")];
        NoaChatMultiSelectTipsView *viewTip = [[NoaChatMultiSelectTipsView alloc] initWithContent:tipsContent toAvatarList:selectedReceverInfoList];
        [viewTip viewShow];
        viewTip.sureClick = ^{
            [weakSelf checkSelectedRecevierComplianceWithRecevierIdArr:[selectedReceverInfoList copy]];
        };
    }
}

#pragma mark - NetWork
//检测所选的接受者(会话、群聊、单聊)是否可进行消息转发
- (void)checkSelectedRecevierComplianceWithRecevierIdArr:(NSArray *)recevierInfoArr {
    if (recevierInfoArr.count > 0) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setObjectSafe:UserManager.userInfo.userUID forKey:@"userUid"];
        [dict setObjectSafe:recevierInfoArr forKey:@"dialogs"];
        if (self.multiSelectType == ZMultiSelectTypeSingleForward) {
            [dict setObjectSafe:@(self.forwardMsgList.count) forKey:@"forwardCount"];
        } else {
            [dict setObjectSafe:@(1) forKey:@"forwardCount"];
        }
        WeakSelf
        [HUD showActivityMessage:@""];
        [IMSDKManager transpondComplianceMessage:dict onSuccess:^(id _Nullable data, NSString * _Nullable traceId) {
            [HUD hideHUD];
            if ([data isKindOfClass:[NSArray class]]) {
                NSArray *dataList = (NSArray *)data;
                NSArray *errorInfoList = [NoaForwardMsgPrecheckModel mj_objectArrayWithKeyValuesArray:dataList];
                [weakSelf showPreCheckReceiverErrorWithData:errorInfoList recevierInfoArr:recevierInfoArr];
            }
        } onFailure:^(NSInteger code, NSString * _Nullable msg, NSString * _Nullable traceId) {
            [HUD showMessageWithCode:code errorMsg:msg];
        }];
    }
}

//展示合规检查错误提示
- (void)showPreCheckReceiverErrorWithData:(NSArray *)errorInfoList recevierInfoArr:(NSArray *)recevierInfoArr {
    if (errorInfoList.count > 0 || self.disableList.count > 0) {
        //转发失败，弹窗提示
        WeakSelf
        __block NSMutableArray<NoaForwardMsgPrecheckModel *> *newErrorInfoList = [NSMutableArray array];
        [self.disableList enumerateObjectsUsingBlock:^(NoaBaseUserModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NoaForwardDialogModel *dialogModel = [[NoaForwardDialogModel alloc] init];
            dialogModel.avatar = obj.avatar;
            dialogModel.nickname = obj.name;
            dialogModel.dialogType = (obj.isGroup ? CIMChatType_GroupChat : CIMChatType_SingleChat);
            dialogModel.dialogId = [obj.userId integerValue];
            
            NoaForwardExceptionModel *exceptionModel = [NoaForwardExceptionModel new];
            exceptionModel.code = NetWork_Error_Group_Interval;
            
            NoaForwardMsgPrecheckModel *precheckModel = [NoaForwardMsgPrecheckModel new];
            precheckModel.dialogInfo = dialogModel;
            precheckModel.exceptionInfo = exceptionModel;
            
            [newErrorInfoList addObject:precheckModel];
        }];
        
        [newErrorInfoList addObjectsFromArray:errorInfoList];
        
        [self.disableList removeAllObjects];
        
        NoaMessageAlertView *forwardFailAlert = [[NoaMessageAlertView alloc] initWithMsgAlertType:ZMessageAlertTypeTitle supView:self.view];
        forwardFailAlert.showClose = YES;
        forwardFailAlert.lblTitle.text = LanguageToolMatch(@"提示");
        forwardFailAlert.lblContent.text = LanguageToolMatch(@"所选会话存在异常，继续发送将排除异常会话");
        [forwardFailAlert.btnSure setTitle:LanguageToolMatch(@"继续发送") forState:UIControlStateNormal];
        [forwardFailAlert.btnSure setTkThemeTitleColor:@[COLORWHITE, COLORWHITE] forState:UIControlStateNormal];
        if (newErrorInfoList.count == self.selectedList.count) {
            forwardFailAlert.btnSure.tkThemebackgroundColors = @[[COLOR_5966F2 colorWithAlphaComponent:0.3], [COLOR_5966F2 colorWithAlphaComponent:0.3]];
            forwardFailAlert.btnSure.enabled = NO;
        } else {
            forwardFailAlert.btnSure.enabled = YES;
            forwardFailAlert.btnSure.tkThemebackgroundColors = @[COLOR_5966F2, COLOR_5966F2];
        }
        [forwardFailAlert.btnCancel setTitle:LanguageToolMatch(@"异常详情") forState:UIControlStateNormal];
        [forwardFailAlert.btnCancel setTkThemeTitleColor:@[COLOR_11, COLOR_11_DARK] forState:UIControlStateNormal];
        forwardFailAlert.btnCancel.tkThemebackgroundColors = @[COLOR_F6F6F6, COLOR_F6F6F6_DARK];
        [forwardFailAlert alertShow];
        forwardFailAlert.sureBtnBlock = ^(BOOL isCheckBox) {
            //继续发送：先剔除不合规接受者，再转发消息
            [weakSelf againPreCheckReceiverComplianceWithFailReceiverList:newErrorInfoList];
        };
        forwardFailAlert.cancelBtnBlock = ^{
            //跳转异常详情
            NoaMessageForwardFailVC *failVC = [[NoaMessageForwardFailVC alloc] init];
            failVC.forwardErroInfoList = newErrorInfoList;
            [weakSelf.navigationController pushViewController:failVC animated:YES];
        };
    } else {
        //没有不合规的接受者，直接走发送
        [self continueSendForwardMessageWithRecevierInfoArr:recevierInfoArr];
    }
}

//先剔除掉不合规的接受者 再检查一遍合规性
- (void)againPreCheckReceiverComplianceWithFailReceiverList:(NSArray *)failReceiverList {
    if (failReceiverList.count > 0) {
        //先剔除掉不合规接受者
        NSMutableArray *failDialogIdList = [NSMutableArray array];
        for (NoaForwardMsgPrecheckModel *failDialogModel in failReceiverList) {
            [failDialogIdList addObject:[NSString stringWithFormat:@"%ld", failDialogModel.dialogInfo.dialogId]];
        }
        NSMutableArray *newSelectedObjectList = [NSMutableArray array];
        for (int i = 0; i<self.selectedList.count; i++) {
            NoaBaseUserModel *tempSelectedModel = [self.selectedList objectAtIndex:i];
            if (![failDialogIdList containsObject:tempSelectedModel.userId]) {
                [newSelectedObjectList addObject:tempSelectedModel];
            }
        }
        
        [self.selectedList removeAllObjects];
        [self.selectedList addObjectsFromArray:newSelectedObjectList];
    }
    
    NSMutableArray *selectedReceverInfoList = [NSMutableArray array];
    for (int i = 0; i < self.selectedList.count; i++) {
        NoaBaseUserModel *model = [self.selectedList objectAtIndex:i];
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        [dic setObjectSafe:[NSNumber numberWithInteger:model.isGroup ? CIMChatType_GroupChat : CIMChatType_SingleChat] forKey:@"dialogType"];
        [dic setObjectSafe:model.userId forKey:@"dialogId"];
        [dic setObjectSafe:model.avatar forKey:@"avatar"];
        [dic setObjectSafe:model.name forKey:@"nickname"];
        [selectedReceverInfoList addObject:dic];
    }
    
    [self checkSelectedRecevierComplianceWithRecevierIdArr:[selectedReceverInfoList copy] ];
}

//继续发送
- (void)continueSendForwardMessageWithRecevierInfoArr:(NSArray *)recevierInfoArr {
    //转发接口
    if (self.multiSelectType == ZMultiSelectTypeSingleForward) {
        //转发消息-单条转发、逐条转发
        [self forwardMessageSendToReceiver:self.selectedList message:_forwardMsgList];
    }
    if (self.multiSelectType == ZMultiSelectTypeMergeForward) {
        //合并转发
        if (self.messageRecordReceverListBlock) {
            self.messageRecordReceverListBlock(recevierInfoArr);
        }
        [self.navigationController popViewControllerAnimated:YES];
    }
    if (self.multiSelectType == ZMultiSelectTypeRecommentCard) {
        //推荐名片
        [self recommentFriendCardToRecevier:self.selectedList];
    }
    if (self.multiSelectType == ZMultiSelectTypeShareQRImg) {
        //分享二维码
        [self shareQRcodeImageMessage];
    }
    
    //发送完成后同步发送最后一条消息时间
    [self.selectedList enumerateObjectsUsingBlock:^(NoaBaseUserModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.isGroup) {
            LingIMSessionModel *sessionModel = [IMSDKManager toolCheckMySessionWith:obj.userId];
            if (sessionModel) {
                sessionModel.lastSendMsgTime = [NSDate currentTimeIntervalWithMillisecond];
                [DBTOOL insertOrUpdateSessionModelWith:sessionModel];
            }
        }
    }];
}
#pragma mark - 获取搜索数据
- (void)requestSearchList {
    //搜索
    if (![NSString isNil:self.searchStr]) {
        NSArray *showFriendList = [[IMSDKManager toolSearchMyFriendWith:_searchStr] mutableCopy];
        for (LingIMFriendModel *tempFriend in showFriendList) {
            if (tempFriend.userType == 1) {
                //此处过滤处理
            } else {
                NoaBaseUserModel *baseUserModel = [[NoaBaseUserModel alloc] init];
                baseUserModel.userId = tempFriend.friendUserUID;
                baseUserModel.name = tempFriend.showName;
                baseUserModel.avatar = tempFriend.avatar;
                baseUserModel.roleId = tempFriend.roleId;
                baseUserModel.disableStatus = tempFriend.disableStatus;
                baseUserModel.isGroup = NO;
                [self.searchList addObject:baseUserModel];
            }
        }
        
        NSArray *showGroupList = [[IMSDKManager toolSearchMyGroupWith:_searchStr] mutableCopy];
        for (LingIMGroupModel *tempGroup in showGroupList) {
            NoaBaseUserModel *baseUserModel = [[NoaBaseUserModel alloc] init];
            baseUserModel.userId = tempGroup.groupId;
            baseUserModel.name = tempGroup.groupName;
            baseUserModel.avatar = tempGroup.groupAvatar;
            baseUserModel.roleId = 0;
            baseUserModel.disableStatus = tempGroup.groupStatus;
            baseUserModel.isGroup = YES;
            [self.searchList addObject:baseUserModel];
        }
    }
    [self reloadInviteUI];
    [self.baseTableView reloadData];
}
#pragma mark - ZSearchViewDelegate
//输入框文本变化
- (void)searchViewTextValueChanged:(NSString *)searchStr {
    _searchStr = [searchStr trimString];
    [self.searchList removeAllObjects];
    [self requestSearchList];
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
                [HUD showActivityMessage:@""];
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                    for (NoaBaseUserModel *obj in weakSelf.selectModelList[section].list) {
                        if (![weakSelf.selectedList containsObject:obj]) {
                            [weakSelf.selectedList addObject:obj];
                        }
                    }
                    [weakSelf checkSelectModelIsAllSelected];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        weakSelf.selectModelList[section].isAllSelect = YES;
                        [weakSelf.baseTableView reloadData];
                        [weakSelf navBtnRightRefresh];
                        [weakSelf groupSelectedTopViewRefresh];
                        [HUD hideHUD];
                    });
                });
                
                
            } else {
                [HUD showActivityMessage:@""];
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                    weakSelf.selectModelList[section].isAllSelect = NO;
                    for (NoaBaseUserModel *obj in weakSelf.selectModelList[section].list)  {
                        if ([weakSelf.selectedList containsObject:obj]) {
                            [weakSelf.selectedList removeObject:obj];
                            
                        }
                    }
                    [weakSelf checkSelectModelIsAllSelected];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf.baseTableView reloadData];
                        [weakSelf navBtnRightRefresh];
                        [weakSelf groupSelectedTopViewRefresh];
                        [HUD hideHUD];
                    });
                });
                
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
- (void)showMaxNumTips {
    NoaKnownTipView *viewTip = [NoaKnownTipView new];
    viewTip.lblTip.text = [NSString stringWithFormat:LanguageToolMatch(@"最多只能选择%ld个"), Max_Selected_Num];
    [viewTip knownTipViewSHow];
}

#pragma mark - 消息转发
//组装转发消息接口需要的数据格式
- (void)forwardMessageSendToReceiver:(NSMutableArray *)receiverList message:(NSArray *)messageList {
    /* 后台接口，单聊和群聊转发是分开进行接口操作的，所以调用转发接口时，需要将receiverList进行排序，单聊排在群聊前面*/
    NSMutableArray *resultList = [NSMutableArray array];
    for (int i = 0; i<self.selectedList.count; i++) {
        NoaBaseUserModel *tempModel = [self.selectedList objectAtIndex:i];
        if (tempModel.isGroup) {
            //群聊
            [resultList addObject:tempModel];
        } else {
            //单聊
            [resultList insertObject:tempModel atIndex:0];
        }
    }
    
    IMChatMessageList *chatMessageList = [[IMChatMessageList alloc] init];
    chatMessageList.source = @"iOS";
    
    NSMutableArray *imMessages = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray *toMessages = [NSMutableArray arrayWithCapacity:1];
    
    for (int i = 0; i < messageList.count; i++) {
        NoaMessageModel *forwardMsg = (NoaMessageModel *)[messageList objectAtIndex:i];
        if (forwardMsg.isSelf) {
            if (forwardMsg.message.messageType == CIMChatMessageType_AtMessage) {
                forwardMsg.message.textContent = [NoaMessageTools forwardMessageAtContenTranslateToShowContent:forwardMsg.message.atContent atUsersDictList:forwardMsg.message.atUsersInfoList];
                forwardMsg.message.messageType = CIMChatMessageType_TextMessage;
            }
            if (forwardMsg.message.messageType == CIMChatMessageType_TextMessage) {
                forwardMsg.message.textContent = forwardMsg.message.textContent;
            }
        } else{
            if (forwardMsg.message.messageType == CIMChatMessageType_AtMessage) {
                NSString *resultContent = @"";
                if (![NSString isNil:forwardMsg.message.atTranslateContent]) {
                    resultContent = forwardMsg.message.atTranslateContent;
                } else {
                    resultContent = forwardMsg.message.atContent;
                }
                forwardMsg.message.textContent = [NoaMessageTools forwardMessageAtContenTranslateToShowContent:resultContent atUsersDictList:forwardMsg.message.atUsersInfoList];
                forwardMsg.message.messageType = CIMChatMessageType_TextMessage;
            }
            if (forwardMsg.message.messageType == CIMChatMessageType_TextMessage) {
                NSString *resultContent = @"";
                if (![NSString isNil:forwardMsg.message.translateContent]) {
                    resultContent = forwardMsg.message.translateContent;
                } else {
                    resultContent = forwardMsg.message.textContent;
                }
                forwardMsg.message.textContent = resultContent;
            }
        }
        forwardMsg.message.translateContent = nil;
        forwardMsg.message.againTranslateContent = nil;
        forwardMsg.message.atTranslateContent = nil;
        forwardMsg.message.againAtTranslateContent = nil;
        
        IMMessage *messageModel = [NoaMessageTools getIMMessageFromLingIMChatMessageModel:forwardMsg.message withChatObject:resultList.firstObject index:i];
        IMChatMessage *chatMessage = messageModel.chatMessage;
        chatMessage.deviceType = @"IOS";
        chatMessage.deviceUuid = [FCUUID uuidForDevice];
        [imMessages addObject:chatMessage];
    }
    
    for (NoaBaseUserModel *receiver in resultList) {
        NSMutableArray *msgIds = [NSMutableArray arrayWithCapacity:1];
        for (int i = 0; i < messageList.count; i++) {
            NSString *msgIdStr = [NoaMessageTools getMessageID];
            [msgIds addObject:msgIdStr];
        }
        
        ToMessage *toMessage = [[ToMessage alloc] init];
        toMessage.msgIdArray = msgIds;
        toMessage.to = receiver.userId;
        toMessage.chatType = receiver.isGroup ? ChatType_GroupChat : ChatType_SingleChat;
        [toMessages addObject:toMessage];
    }
    
    chatMessageList.iMchatMessageArray = imMessages;
    chatMessageList.toMessageArray = toMessages;
    
    [self requestForwardMessageWithMessages:chatMessageList];
}

//调用转发消息接口并处理接口返回结果
- (void)requestForwardMessageWithMessages:(IMChatMessageList *)message {
    //_chatMessageList = message;
    WeakSelf
    [HUD showActivityMessage:@""];
    self.multiSendHander.fromSessionId = self.fromSessionId;
    [self.multiSendHander chatMultiSelectSendForwardMessageList:self.forwardMsgList imMessage:message];
    [self.multiSendHander setForwardComleteBlock:^(NSArray<NoaIMChatMessageModel *> * _Nullable sendForwardMsgList) {
        //如果将消息转发给消息来源的同一个群，需要单独处理
        if (weakSelf.forwardMsgSendSuccess) {
            weakSelf.forwardMsgSendSuccess(sendForwardMsgList);
        }
    }];
    [self.multiSendHander setNavBackActionBlock:^(BOOL isSuccess, NSInteger errorCode, NSString *errorMsg) {
        if (isSuccess) {
            [HUD showMessage:LanguageToolMatch(@"转发成功")];
        } else {
            [HUD hideHUD];
            if (weakSelf.forwardMsgSendFail) {
                weakSelf.forwardMsgSendFail();
            }
            [HUD showMessage:LanguageToolMatch(@"消息转发失败")];
        }
        [weakSelf.navigationController popViewControllerAnimated:YES];
    }];
}

#pragma mark - 推荐好友名片
- (void)recommentFriendCardToRecevier:(NSMutableArray *)receiverList {
    WeakSelf
    [HUD showActivityMessage:@""];
    self.multiSendHander.fromSessionId = self.fromSessionId;
    [self.multiSendHander chatMultiSelectRecommendFriendCard:self.cardFriendInfo.userUID receiverList:receiverList];
    [self.multiSendHander setNavBackActionBlock:^(BOOL isSuccess, NSInteger errorCode, NSString *errorMsg) {
        if (isSuccess) {
            [HUD showMessage:LanguageToolMatch(@"已发送")];
        } else {
            [HUD showMessage:LanguageToolMatch(@"操作失败")];
        }
        [weakSelf.navigationController popViewControllerAnimated:YES];
    }];
}

#pragma mark - 分享二维码(个人二维码/群二维码)
- (void)shareQRcodeImageMessage {
    WeakSelf
    [HUD showActivityMessage:@""];
    self.multiSendHander.fromSessionId = self.fromSessionId;
    [self.multiSendHander chatMultiSelectShareQRcodeMessage:self.qrCodeImg selectObjectList:self.selectedList];
    [self.multiSendHander setShareQRcodeComleteBlock:^(NoaIMChatMessageModel * _Nullable sendShareQRMsg) {
        //如果将消息转发给消息来源的同一个群，需要单独处理
        if (weakSelf.shareQrCodeMsgSendSuccess) {
            weakSelf.shareQrCodeMsgSendSuccess(sendShareQRMsg);
        }
    }];
    [self.multiSendHander setNavBackActionBlock:^(BOOL isSuccess, NSInteger errorCode, NSString *errorMsg) {
        if (isSuccess) {
            [HUD showMessage:LanguageToolMatch(@"已发送")];
        } else {
            [HUD showMessage:LanguageToolMatch(@"操作失败")];
        }
        [weakSelf.navigationController popViewControllerAnimated:YES];
    }];
}

#pragma mark - 懒加载
- (NoaNoDataView *)viewNoData {
    if (!_viewNoData) {
        _viewNoData = [[NoaNoDataView alloc] initWithFrame:CGRectMake(0, 0, DScreenWidth, DWScale(60))];
        _viewNoData.tkThemebackgroundColors = @[COLORWHITE, COLOR_11];
    }
    return _viewNoData;
}

- (NoaChatMultiSelectSendHander *)multiSendHander {
    if (!_multiSendHander) {
        _multiSendHander = [[NoaChatMultiSelectSendHander alloc] init];
    }
    return _multiSendHander;
}

- (NSMutableArray<NoaMassMessageSelectModel *> *)selectModelList{
    if (_selectModelList == nil) {
        _selectModelList = [[NSMutableArray alloc] init];
    }
    return _selectModelList;
}

- (NSMutableArray<NoaBaseUserModel *> *)disableList {
    if (_disableList == nil) {
        _disableList = [[NSMutableArray alloc] init];
    }
    return _disableList;
}

- (NSMutableArray<NoaBaseUserModel *> *)searchList {
    if (_searchList == nil) {
        _searchList = [[NSMutableArray alloc] init];
    }
    return _searchList;
}

- (NSMutableArray<NoaBaseUserModel *> *)selectedList {
    if (_selectedList == nil) {
        _selectedList = [[NSMutableArray alloc] init];
    }
    return _selectedList;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
