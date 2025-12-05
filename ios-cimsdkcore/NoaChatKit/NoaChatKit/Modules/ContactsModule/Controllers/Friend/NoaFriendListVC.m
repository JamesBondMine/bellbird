//
//  NoaFriendListVC.m
//  NoaKit
//
//  Created by mac on 2023/7/3.
//

#import "NoaFriendListVC.h"
#import "NoaChineseSort.h"
#import "UITableView+SCIndexView.h"
#import "NoaFriendListSectionHeaderView.h"
#import "NoaContactListTableCell.h"
#import "NoaFriendModel.h"
#import "NoaToolManager.h"//工具类
#import <DZNEmptyDataSet/UIScrollView+EmptyDataSet.h>
#import "SyncMutableArray.h"
//跳转
#import "NoaUserHomePageVC.h"//用户主页

@interface NoaFriendListVC () <UITableViewDataSource, UITableViewDelegate, NoaToolUserDelegate, ZBaseCellDelegate, SCTableViewSectionIndexDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, UIGestureRecognizerDelegate>

/// 好友列表队列
@property (nonatomic, strong) dispatch_queue_t friendListQueue;

/// 好友列表
@property (nonatomic, strong) SyncMutableArray *friendList;

/// 账号注销的好友列表
@property (nonatomic, strong) NSMutableArray <NoaFriendModel *>*friendSignOutList;

/// 排序后的出现过的拼音首字母数组
@property (nonatomic, strong) NSMutableArray *firstLetterArr;

/// 排序好的结果字典
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSMutableArray<NoaFriendModel *> *> *sortedModelDict;

@end

@implementation NoaFriendListVC

- (instancetype)init {
    self = [super init];
    if (self) {
        _friendListQueue = dispatch_queue_create("com.CIMKit.friendListQueue", DISPATCH_QUEUE_SERIAL);
        
        _friendList = [SyncMutableArray new];
        
        _friendSignOutList = [NSMutableArray new];
        
        _firstLetterArr = [NSMutableArray new];

        _sortedModelDict = [NSMutableDictionary new];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [IMSDKManager addUserDelegate:self];
    
    [self setupUI];
    
    //数据库获得好友信息
    [self requestFriendListFromDB:YES];
}

#pragma mark - 界面布局
- (void)setupUI {
    //隐藏导航栏
    self.navView.hidden = YES;
    
    //列表布局
    [self.view addSubview:self.baseTableView];
    self.baseTableView.delaysContentTouches = NO;
    self.baseTableView.dataSource = self;
    self.baseTableView.delegate = self;
    self.baseTableView.emptyDataSetSource = self;
    self.baseTableView.emptyDataSetDelegate = self;
    self.baseTableView.tkThemebackgroundColors = @[COLOR_F8F9FB, COLOR_F8F9FB_DARK];
    [self.baseTableView registerClass:[NoaContactListTableCell class] forCellReuseIdentifier:[NoaContactListTableCell cellIdentifier]];
    [self.baseTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    //默认不可滑动
    self.baseTableView.scrollEnabled = YES;
    
    if(!ZLanguageTOOL.isRTL){
        SCIndexViewConfiguration *configuration = [SCIndexViewConfiguration configurationWithIndexViewStyle:SCIndexViewStyleDefault];
        configuration.indexItemSelectedBackgroundColor = COLOR_5966F2;
        self.tkThemeChangeBlock = ^(id  _Nullable itself, NSUInteger themeIndex) {
            if (themeIndex == 0) {
                configuration.indexItemTextColor = COLOR_66;
                configuration.indexItemSelectedTextColor = COLORWHITE;
            }else {
                configuration.indexItemTextColor = COLOR_66;
                configuration.indexItemSelectedTextColor = COLORWHITE;
            }
        };
        configuration.indexItemsSpace = DWScale(6);
        self.baseTableView.sc_indexViewConfiguration = configuration;
        self.baseTableView.sc_translucentForTableViewInNavigationBar = NO;
        self.baseTableView.sc_indexViewDelegate = self;
    }
}

- (void)friendListScrollEnable:(BOOL)canScroll {
    self.baseTableView.scrollEnabled = canScroll;
    if (!canScroll) {
        [self.baseTableView setContentOffset:CGPointMake(0, 0)];
    }
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
    return YES;
}

#pragma mark - DZNEmptyDataSetSource
- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    NSString *string = LanguageToolMatch(@"暂无好友");
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
    return ImgNamed(@"c_no_friend");
}

#pragma mark - DZNEmptyDataSetDelegate
//允许滑动
- (BOOL)emptyDataSetShouldAllowScroll:(UIScrollView *)scrollView {
    return NO;
}

#pragma mark - UITableViewDataSource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return [self.firstLetterArr count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (self.firstLetterArr.count > section) {
        NSString *tempLetter = (NSString *)[self.firstLetterArr objectAtIndexSafe:section];
        if ([self.sortedModelDict objectForKey:tempLetter]) {
            NSArray *sectionArr = [self.sortedModelDict objectForKey:tempLetter];
            return sectionArr.count;
        }
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{

    NoaContactListTableCell *cell = [tableView dequeueReusableCellWithIdentifier:[NoaContactListTableCell cellIdentifier] forIndexPath:indexPath];
    
    if (self.firstLetterArr.count > indexPath.section) {
        NSString *tempLetter = (NSString *)[self.firstLetterArr objectAtIndexSafe:indexPath.section];
        if ([self.sortedModelDict objectForKey:tempLetter]) {
            NSArray *sectionArr = [self.sortedModelDict objectForKey:tempLetter];
            NoaFriendModel *tempModel = [sectionArr objectAtIndexSafe:indexPath.row];
            LingIMFriendModel *friendModel = [LingIMFriendModel mj_objectWithKeyValues:[tempModel mj_JSONString]];
            cell.friendModel = friendModel;
        }
    }
    cell.baseDelegate = self;
    cell.baseCellIndexPath = indexPath;
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = indexPath.row;
    if (row != 0) {
        // 其他 cell 清除圆角
        cell.layer.mask = nil;
        return;
    }
    
    if (!CGRectIsEmpty(cell.contentView.bounds)) {
        UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:cell.contentView.bounds
                                                       byRoundingCorners:(UIRectCornerTopLeft | UIRectCornerTopRight)
                                                             cornerRadii:CGSizeMake(20, 20)];
        
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        maskLayer.frame = cell.contentView.bounds;
        maskLayer.path = maskPath.CGPath;
        cell.layer.mask = maskLayer;
    }
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return DWScale(68);
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    
    static NSString *headerID = @"NoaFriendListSectionHeaderView";
    NoaFriendListSectionHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:headerID];
    if (headerView == nil) {
        headerView = [[NoaFriendListSectionHeaderView alloc] initWithReuseIdentifier:headerID];
    }
    
    headerView.contentLabel.text = [self.firstLetterArr objectAtIndexSafe:section];
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return DWScale(32);
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

#pragma mark - ZBaseCellDelegate
- (void)cellClickAction:(NSIndexPath *)indexPath {
    if (self.firstLetterArr.count > indexPath.section) {
        NSString *tempLetter = (NSString *)[self.firstLetterArr objectAtIndexSafe:indexPath.section];
        if ([self.sortedModelDict objectForKey:tempLetter]) {
            NSArray *sectionArr = [self.sortedModelDict objectForKey:tempLetter];
            NoaFriendModel *friendModel = [sectionArr objectAtIndexSafe:indexPath.row];
            
            if (friendModel.userType == 0) {
                //好友 普通用户级别
                NoaUserHomePageVC *vc = [NoaUserHomePageVC new];
                vc.userUID = friendModel.friendUserUID;
                vc.groupID = @"";
                [self.navigationController pushViewController:vc animated:YES];
            }
        }
    }
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat offsetY = scrollView.contentOffset.y;
    if (offsetY > 0) {
    }else {
        //[self friendListScrollEnable:NO];
        //告知上层进行滑动
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ContactScrollEnable" object:nil];
        
    }
}

#pragma mark - SCTableViewSectionIndexDelegate
- (void)tableView:(UITableView *)tableView didSelectIndexViewAtSection:(NSUInteger)section {
    [self friendListScrollEnable:YES];
}

#pragma mark - CIMToolUserDelegate
- (void)cimToolUserFriendConfirm:(IMServerMessage *)message {
//    WeakSelf
//    dispatch_async(_friendListQueue, ^{
//        FriendConfirmMessage *friendConfirm = message.friendConfirmMessage;
//        if (friendConfirm.status == 1) {
//            DLog(@"通讯录好友同意了你的好友申请");
//            [weakSelf requestFriendListFromDB:YES];
//        }
//    });
    FriendConfirmMessage *friendConfirm = message.friendConfirmMessage;
    if (friendConfirm.status == 1) {
        DLog(@"通讯录好友同意了你的好友申请");
        [self requestFriendListFromDB:YES];
    }
}
- (void)cimToolUserFriendChange:(LingIMFriendModel *)message {
    DLog(@"通讯录好友信息发生变化");
    WeakSelf
    dispatch_async(_friendListQueue, ^{
        [weakSelf.friendList.safeArray enumerateObjectsUsingBlock:^(NoaFriendModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.friendUserUID isEqualToString:message.friendUserUID]) {
                NSString *jsonStr = [message mj_JSONString];
                NoaFriendModel *model = [NoaFriendModel mj_objectWithKeyValues:jsonStr];
                // 获取sortName
                model.sortName = [self processedSortNameFromModel:model];
                // 将变化的model替换位置
                [weakSelf.friendList replaceObjectAtIndex:idx withObject:model];
                *stop = YES;
            }
        }];
        
        [weakSelf requestFriendListFromDB:NO];
    });
}

- (void)cimToolUserFriendRemarkChange:(SynchroMessage *)message {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setValue:UserManager.userInfo.userUID forKey:@"userUid"];
    [params setValue:message.sessionId forKey:@"friendUserUid"];
    [IMSDKManager getFriendInfoWith:params onSuccess:^(id _Nullable data, NSString * _Nullable traceId) {
        NSDictionary *friendDict = (NSDictionary *)data;
        LingIMFriendModel *friendModel = [LingIMFriendModel mj_objectWithKeyValues:friendDict];
        [IMSDKManager toolUpdateMyFriendWith:friendModel];
    } onFailure:^(NSInteger code, NSString * _Nullable msg, NSString * _Nullable traceId) {
    }];
}

- (void)imSdkUserFriendAdd:(LingIMFriendModel *)friendAddModel {
    DLog(@"通讯录好友新增");
//    WeakSelf
//    dispatch_async(_friendListQueue, ^{
//        [weakSelf requestFriendListFromDB:YES];
//    });
    [self requestFriendListFromDB:YES];
}
- (void)imSdkUserFriendDelete:(LingIMFriendModel *)friendDeleteModel {
    DLog(@"通讯录好友被删除");
    WeakSelf
    dispatch_async(_friendListQueue, ^{
        [weakSelf.friendList.safeArray enumerateObjectsUsingBlock:^(NoaFriendModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.friendUserUID isEqualToString:friendDeleteModel.friendUserUID]) {
                [weakSelf.friendList removeObjectAtIndex:idx];
                *stop = YES;
            }
        }];
        
        [weakSelf requestFriendListFromDB:NO];
    });
}

- (void)imSdkUserContactsSyncFinish {
    DLog(@"通讯录好友同步服务器通讯录成功");
    
//    WeakSelf
//    dispatch_async(_friendListQueue, ^{
//        [weakSelf requestFriendListFromDB:YES];
//    });
    [self requestFriendListFromDB:YES];
}

- (void)imSdkUserContactsSyncFailed:(NSString *)errorMsg {
    DLog(@"通讯录好友同步服务器通讯录失败：%@",errorMsg);
}

#pragma mark - 数据处理
////数据库获取好友信息 --- 2.1.9版本旧代码臃肿，已废弃
//- (void)requestFriendListFromDB:(BOOL)fromDB {
//    WeakSelf
//    if (fromDB) {
//        NSArray *friendArray = [IMSDKManager toolGetMyFriendList];
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            if (friendArray.count > 0) {
//                [weakSelf.friendList removeAllObjects];
//                [weakSelf.friendSignOutList removeAllObjects];
//                __block NSMutableArray *tempFriendArray = [NSMutableArray array];
//                [friendArray enumerateObjectsUsingBlock:^(LingIMFriendModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//                    //去掉系统级好友(文件助手)
//                    if (obj.userType == 0) {
//                        NSString *jsonStr = [obj mj_JSONString];
//                        ZFriendModel *model = [ZFriendModel mj_objectWithKeyValues:jsonStr];
//                        NSMutableString *tempSortName;
//                        if (![NSString isNil:model.userName]) {
//                            tempSortName = [NSMutableString stringWithFormat:@"%@%@", model.showName, model.userName];
//                        } else {
//                            tempSortName = [NSMutableString stringWithFormat:@"%@", model.showName];
//                        }
//                        
//                        //判断字符串是否包含汉字
//                        NSString *pattern = @".*[\u4e00-\u9fa5].*";
//                        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", pattern];
//                        if ([predicate evaluateWithObject:tempSortName]) {//包含汉字
//                            NSMutableString *result = [NSMutableString string];
//                            //遍历待汉字的字符串
//                            for (int i = 0; i < tempSortName.length; i++) {
//                                unichar character = [tempSortName characterAtIndex:i];
//                                //判断该字符是否为汉字
//                                if ((character >= 0x4e00 && character <= 0x9fff)) {
//                                    NSString *chineseCharacter = [NSString stringWithCharacters:&character length:1];
//                                    NSMutableString *pinyinString = [chineseCharacter mutableCopy];
//                                    CFStringTransform((__bridge CFMutableStringRef)pinyinString, NULL, kCFStringTransformMandarinLatin, NO);
//                                    // 去除拼音中的空格和音标
//                                    NSString *resultPinyinString = [pinyinString stringByFoldingWithOptions:NSDiacriticInsensitiveSearch locale:[NSLocale currentLocale]];
//                                    NSString *pinyinInitial = [resultPinyinString safeSubstringWithRange:NSMakeRange(0, 1)];
//                                    [result appendString:pinyinInitial];
//                                } else {
//                                    // 字母、数字等直接添加到结果中
//                                    [result appendString:[NSString stringWithFormat:@"%c", character]];
//                                }
//                            }
//                            tempSortName = result;
//                        }
//                        //去除空格
//                        model.sortName = [[tempSortName stringByReplacingOccurrencesOfString:@" " withString:@""] uppercaseString];
//                        
//                        if (model.disableStatus == 4) {
//                            //账号已注销
//                            [weakSelf.friendSignOutList addObjectIfNotNil:model];
//                        }else {
//                            [tempFriendArray addObject:model];
//                        }
//                    }
//                }];
//                
//                [self.friendList addObjectsFromArray:tempFriendArray];
//            }
//            
//            
//            if (weakSelf.friendList.count > 0) {
//                [weakSelf.firstLetterArr removeAllObjects];
//                NSMutableDictionary *sortFriendDict = [[NSMutableDictionary alloc] init];
//                NSMutableArray *letterArray = [[NSMutableArray alloc] init];
//                NSMutableArray *specialSortArr = [[NSMutableArray alloc] init];
//                for (ZFriendModel *model in weakSelf.friendList.safeArray) {
//                    //全转为大写，并取第一个字符
//                    NSString *upperCaseStr = [model.sortName uppercaseString];
//                    NSString *firstLetter = @"";
//                    if (upperCaseStr.length > 0) {
//                        firstLetter = [upperCaseStr substringToIndex:1];
//                    } else {
//                        firstLetter = @"#";
//                    }
//                    //判断第一个字符是否为字母 英文或者中文转拼音后都是字母开头
//                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @".*[a-zA-Z].*"];
//                    BOOL containsLetters = [predicate evaluateWithObject:firstLetter];
//                    if (containsLetters) {
//                        if (![letterArray containsObject:firstLetter]) {
//                            [letterArray addObject:firstLetter];
//                            NSMutableArray *tempSortArray = [[NSMutableArray alloc] init];
//                            [tempSortArray addObject:model];
//                            [sortFriendDict setObjectSafe:tempSortArray forKey:firstLetter];
//                        } else {
//                            NSMutableArray *tempSortArray = [[sortFriendDict objectForKeySafe:firstLetter] mutableCopy];
//                            [tempSortArray addObject:model];
//                            [sortFriendDict setObjectSafe:tempSortArray forKey:firstLetter];
//                        }
//                    } else {
//                        //所有非字母的字符放在#分组中
//                        [specialSortArr addObject:model];
//                    }
//                }
//                
//                NSArray *allLetter = [sortFriendDict allKeys];
//                NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:nil ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
//                [weakSelf.firstLetterArr addObjectsFromArray:[allLetter sortedArrayUsingDescriptors:@[sortDescriptor]]];
//                //处理 #分组
//                if (specialSortArr.count > 0) {
//                    [weakSelf.firstLetterArr addObject:@"#"];
//                    [sortFriendDict setObjectSafe:specialSortArr forKey:@"#"];
//                }
//                for (int i = 0; i < weakSelf.firstLetterArr.count; i++) {
//                    NSString *tempLetter = (NSString *)[weakSelf.firstLetterArr objectAtIndexSafe:i];
//                    NSArray *letterSortArray = (NSArray *)[sortFriendDict objectForKey:tempLetter];
//                    // 使用NSSortDescriptor进行排序
//                    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"sortName" ascending:YES comparator:^NSComparisonResult(id obj1, id obj2) {
//                        return customCompare(obj1, obj2, 0);
//                    }];
//                    NSArray *sortedFriendsArray =  [letterSortArray sortedArrayUsingDescriptors:@[sortDescriptor]];
//                    [sortFriendDict setObjectSafe:sortedFriendsArray forKey:tempLetter];
//                }
//                
//                //把已注销的账号添加到#分组最后面
//                NSMutableArray *tempSpecialSortArr = [[sortFriendDict objectForKeySafe:@"#"] mutableCopy];
//                [tempSpecialSortArr addObjectsFromArray:weakSelf.friendSignOutList];
//                [sortFriendDict setObjectSafe:tempSpecialSortArr forKey:@"#"];
//                
//                [weakSelf.sortedModelDict removeAllObjects];
//                [weakSelf.sortedModelDict addEntriesFromDictionary:sortFriendDict];
//                //界面刷新
//                [ZTOOL doInMain:^{
//                    if(!ZLanguageTOOL.isRTL) {
//                        weakSelf.baseTableView.sc_indexViewDataSource = weakSelf.firstLetterArr;
//                    }
//                    [weakSelf.baseTableView reloadData];
//                }];
//            } else {
//                if (weakSelf.friendSignOutList.count > 0) {
//                    weakSelf.firstLetterArr = @[@"#"].mutableCopy;
//                    [weakSelf.sortedModelDict setObjectSafe:weakSelf.friendSignOutList forKey:@"#"];
//                } else {
//                    [weakSelf.firstLetterArr removeAllObjects];
//                    [weakSelf.sortedModelDict removeAllObjects];
//                }
//                [ZTOOL doInMain:^{
//                    weakSelf.baseTableView.sc_indexViewDataSource = weakSelf.firstLetterArr;
//                    [weakSelf.baseTableView reloadData];
//                }];
//            }
//        });
//    } else {
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            if (weakSelf.friendList.count > 0) {
//                NSArray *tempFriendList = [NSArray arrayWithArray:weakSelf.friendList.safeArray];
//                [weakSelf.firstLetterArr removeAllObjects];
//                NSMutableDictionary *sortFriendDict = [[NSMutableDictionary alloc] init];
//                NSMutableArray *letterArray = [[NSMutableArray alloc] init];
//                NSMutableArray *specialSortArr = [[NSMutableArray alloc] init];
//                for (int i = 0; i < tempFriendList.count; i++) {
//                    ZFriendModel *model = [tempFriendList objectAtIndexSafe:i];
//                    //全转为大写，并取第一个字符
//                    NSString *upperCaseStr = [model.sortName uppercaseString];
//                    NSString *firstLetter = @"";
//                    if (upperCaseStr.length > 0) {
//                        firstLetter = [upperCaseStr substringToIndex:1];
//                    } else {
//                        firstLetter = @"#";
//                    }
//                    //判断第一个字符是否为字母 英文或者中文转拼音后都是字母开头
//                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @".*[a-zA-Z].*"];
//                    BOOL containsLetters = [predicate evaluateWithObject:firstLetter];
//                    if (containsLetters) {
//                        if (![letterArray containsObject:firstLetter]) {
//                            [letterArray addObject:firstLetter];
//                            NSMutableArray *tempSortArray = [[NSMutableArray alloc] init];
//                            [tempSortArray addObject:model];
//                            [sortFriendDict setObjectSafe:tempSortArray forKey:firstLetter];
//                        } else {
//                            NSMutableArray *tempSortArray = [[sortFriendDict objectForKeySafe:firstLetter] mutableCopy];
//                            [tempSortArray addObject:model];
//                            [sortFriendDict setObjectSafe:tempSortArray forKey:firstLetter];
//                        }
//                    } else {
//                        //所有非字母的字符放在#分组中
//                        [specialSortArr addObject:model];
//                    }
//                }
//                
//                NSArray *allLetter = [sortFriendDict allKeys];
//                NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:nil ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
//                [weakSelf.firstLetterArr addObjectsFromArray:[allLetter sortedArrayUsingDescriptors:@[sortDescriptor]]];
//                //处理 #分组
//                if (specialSortArr.count > 0) {
//                    [weakSelf.firstLetterArr addObject:@"#"];
//                    [sortFriendDict setObjectSafe:specialSortArr forKey:@"#"];
//                }
//                for (NSString *tempLetter in weakSelf.firstLetterArr) {
//                    NSArray *letterSortArray = (NSArray *)[sortFriendDict objectForKey:tempLetter];
//                    // 使用NSSortDescriptor进行排序
//                    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"sortName" ascending:YES comparator:^NSComparisonResult(id obj1, id obj2) {
//                        return customCompare(obj1, obj2, 0);
//                    }];
//                    NSArray *sortedFriendsArray =  [letterSortArray sortedArrayUsingDescriptors:@[sortDescriptor]];
//                    [sortFriendDict setObjectSafe:sortedFriendsArray forKey:tempLetter];
//                }
//                
//                //把已注销的账号添加到#分组最后面
//                NSMutableArray *tempSpecialSortArr = [[sortFriendDict objectForKeySafe:@"#"] mutableCopy];
//                [tempSpecialSortArr addObjectsFromArray:weakSelf.friendSignOutList];
//                [sortFriendDict setObjectSafe:tempSpecialSortArr forKey:@"#"];
//                
//                [weakSelf.sortedModelDict removeAllObjects];
//                [weakSelf.sortedModelDict addEntriesFromDictionary:sortFriendDict];
//                //界面刷新
//                [ZTOOL doInMain:^{
//                    if(!ZLanguageTOOL.isRTL) {
//                        weakSelf.baseTableView.sc_indexViewDataSource = weakSelf.firstLetterArr;
//                    }
//                    [weakSelf.baseTableView reloadData];
//                }];
//            } else {
//                if (weakSelf.friendSignOutList.count > 0) {
//                    weakSelf.firstLetterArr = @[@"#"].mutableCopy;
//                    [weakSelf.sortedModelDict setObjectSafe:weakSelf.friendSignOutList forKey:@"#"];
//                } else {
//                    [weakSelf.firstLetterArr removeAllObjects];
//                    [weakSelf.sortedModelDict removeAllObjects];
//                }
//                [ZTOOL doInMain:^{
//                    weakSelf.baseTableView.sc_indexViewDataSource = weakSelf.firstLetterArr;
//                    [weakSelf.baseTableView reloadData];
//                }];
//            }
//        });
//    }
//}

NSComparisonResult customCompare(NSString *str1, NSString *str2, NSUInteger index) {
    unichar char1 = [str1 characterAtIndex:index];
    unichar char2 = [str2 characterAtIndex:index];

    if (char1 == char2) {
        // 如果相同位置的字符相等，递归比较下一个位置
        if (index < str1.length - 1 && index < str2.length - 1) {
            return customCompare(str1, str2, index + 1);
        }
    } else {
        NSCharacterSet *letterCharacterSet = [NSCharacterSet letterCharacterSet];
        NSCharacterSet *digitCharacterSet = [NSCharacterSet decimalDigitCharacterSet];
        
        NSInteger typeA;
        if ([letterCharacterSet characterIsMember:char1]) {
            typeA = 10;
        } else if ([digitCharacterSet characterIsMember:char1]) {
            typeA = 8;
        } else {
            return 0;
        }
        
        NSInteger typeB;
        if ([letterCharacterSet characterIsMember:char2]) {
            typeB = 10;
        } else if ([digitCharacterSet characterIsMember:char2]) {
            typeB = 8;
        } else {
            return 0;
        }
        
        if (typeA > typeB) {
            return NSOrderedAscending;
        } else if (typeA < typeB) {
            return NSOrderedDescending;
        } else {
            return [@(char1) compare:@(char2)];
        }
    }

    // 如果相同位置的字符相等，或者已经比较到字符串末尾，则按照字符串长度进行比较
    return [@(str1.length) compare:@(str2.length)];
}


- (void)requestFriendListFromDB:(BOOL)fromDB {
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.friendListQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        
        NSArray *friendArray = fromDB ? [IMSDKManager toolGetMyFriendList] : strongSelf.friendList.safeArray;
        if (friendArray.count == 0 && strongSelf.friendSignOutList.count == 0) {
            // 无好友、无已注销账号
            [strongSelf clearFriendDataOnMainThread];
            return;
        }
        
        // 更新 friendList
        if (fromDB) {
            [strongSelf.friendSignOutList removeAllObjects];
            [strongSelf.friendList removeAllObjects];
        }
        
        NSMutableArray<NoaFriendModel *> *tempFriendArray = [NSMutableArray new];
        for (LingIMFriendModel *obj in friendArray) {
            if (fromDB && obj.userType != 0) continue;
            
            NSString *jsonStr = [obj mj_JSONString] ? [obj mj_JSONString] : @"";
            if ([NSString isNil:jsonStr]) continue;
            
            NoaFriendModel *model = [NoaFriendModel mj_objectWithKeyValues:jsonStr];
            if (!model) continue;
            
            // 处理 sortName
            model.sortName = [strongSelf processedSortNameFromModel:model];
            
            if (model.disableStatus == 4) {
                [strongSelf.friendSignOutList addObjectIfNotNil:model];
            } else {
                [tempFriendArray addObject:model];
            }
        }
        
        // 更新 friendList
        if (fromDB) {
            [strongSelf.friendList addObjectsFromArray:tempFriendArray];
        }
        
        if (strongSelf.friendList.count == 0) {
            if (strongSelf.friendSignOutList.count > 0) {
                NSString *letter = @"#";
                NSMutableArray *firstLetterArr = [[NSMutableArray alloc] init];
                [firstLetterArr addObject:letter];
                strongSelf.firstLetterArr = firstLetterArr;
                [strongSelf.sortedModelDict setObjectSafe:strongSelf.friendSignOutList forKey:letter];
            }else {
                [strongSelf.firstLetterArr removeAllObjects];
                [strongSelf.sortedModelDict removeAllObjects];
            }
            
            // 刷新数据
            [strongSelf reloadData];
            return;
        }
        
        // 分组、排序
        NSDictionary<NSString *, NSArray<NoaFriendModel *> *> *sortDict = [strongSelf sortFriends:strongSelf.friendList.safeArray safeSignOutList:strongSelf.friendSignOutList];
        strongSelf.sortedModelDict = [NSMutableDictionary dictionaryWithDictionary:sortDict];
        // 刷新数据
        [strongSelf reloadData];
    });
}

- (void)reloadData {
    // 主线程刷新 UI
    dispatch_async(dispatch_get_main_queue(), ^{
        if(!ZLanguageTOOL.isRTL) {
            self.baseTableView.sc_indexViewDataSource = self.firstLetterArr;
        }
        [self.baseTableView reloadData];
    });
}

#pragma mark - Private helpers

- (NSString *)processedSortNameFromModel:(NoaFriendModel *)model {
    // 处理字符串
    NSString *showName = [NSString isNil:model.showName] ? @"" : model.showName;
    NSString *userName = [NSString isNil:model.userName] ? @"" : model.userName;
    
    NSMutableString *tempSortName = [NSMutableString stringWithFormat:@"%@%@", showName, userName];
    
    // 判断是否包含汉字
    NSString *pattern = @".*[\u4e00-\u9fa5].*";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", pattern];
    if ([predicate evaluateWithObject:tempSortName]) {
        NSMutableString *result = [NSMutableString string];
        
        for (int i = 0; i < tempSortName.length; i++) {
            unichar character = [tempSortName characterAtIndex:i];
            if (character >= 0x4e00 && character <= 0x9fff) {
                NSString *chineseChar = [NSString stringWithCharacters:&character length:1];
                NSMutableString *pinyin = [chineseChar mutableCopy];
                CFStringTransform((__bridge CFMutableStringRef)pinyin, NULL, kCFStringTransformMandarinLatin, NO);
                NSString *resultPinyin = [pinyin stringByFoldingWithOptions:NSDiacriticInsensitiveSearch locale:[NSLocale currentLocale]];
                NSString *initial = [resultPinyin safeSubstringWithRange:NSMakeRange(0, 1)];
                [result appendString:initial];
            } else {
                [result appendFormat:@"%c", character];
            }
        }
        tempSortName = result;
    }
    
    return [[tempSortName stringByReplacingOccurrencesOfString:@" " withString:@""] uppercaseString];
}

- (NSDictionary<NSString *, NSArray<NoaFriendModel *> *> *)sortFriends:(NSMutableArray *)friendList safeSignOutList:(NSArray<NoaFriendModel *> *)signOutList {
    // 拼音首字母初始化
    NSMutableArray *firstLetterArr = [NSMutableArray new];
    
    // 排序字典
    NSMutableDictionary<NSString *, NSMutableArray<NoaFriendModel *> *> *sortDict = [NSMutableDictionary new];
    
    // 排序数据处理
    NSMutableArray<NoaFriendModel *> *specialArr = [NSMutableArray array];
    
    for (NoaFriendModel *model in friendList) {
        if (!model) {
            continue;
        }
        // 全转为大写，并取第一个字符
        NSString *firstLetter = model.sortName.length > 0 ? [[model.sortName substringToIndex:1] uppercaseString] : @"#";
        // 判断第一个字符是否为字母 英文或者中文转拼音后都是字母开头
        NSPredicate *letterPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @".*[A-Z].*"];
        BOOL isLetter = [letterPredicate evaluateWithObject:firstLetter];
        if (isLetter) {
            if (!sortDict[firstLetter]) {
                NSMutableArray <NoaFriendModel *>*friendModelArr = [NSMutableArray new];
                [friendModelArr addObject:model];
                [sortDict setValue:friendModelArr forKey:firstLetter];
            }else {
                NSMutableArray <NoaFriendModel *>*friendModelArr = sortDict[firstLetter];
                [friendModelArr addObject:model];
                [sortDict setValue:friendModelArr forKey:firstLetter];
            }
        } else {
            [specialArr addObject:model];
        }
    }
    
    NSArray *allLetter = [sortDict allKeys];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:nil ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    [firstLetterArr addObjectsFromArray:[allLetter sortedArrayUsingDescriptors:@[sortDescriptor]]];
    
    if (specialArr.count > 0 && ![firstLetterArr containsObject:@"#"]) {
        [firstLetterArr addObject:@"#"];
        [sortDict setValue:specialArr forKey:@"#"];
    }
    
    // 排序每个分组
    for (NSString *firstLetterStr in firstLetterArr) {
        NSMutableArray <NoaFriendModel *>*friendModelArr = sortDict[firstLetterStr];
        NSArray *sortedArr = [self customCompareArr:friendModelArr];
        [sortDict setValue:[sortedArr mutableCopy] forKey:firstLetterStr];
    }
    
    //把已注销的账号添加到#分组最后面
    NSMutableArray *tempSpecialSortArr = [sortDict objectForKey:@"#"];
    if (!tempSpecialSortArr) {
        tempSpecialSortArr = [NSMutableArray new];
    }
    [tempSpecialSortArr addObjectsFromArray:signOutList];
    [sortDict setValue:tempSpecialSortArr forKey:@"#"];
    
    self.firstLetterArr = firstLetterArr;
    
    return sortDict;
}

/// 传入一个数组，按照sortName排序，自定义的比较规则
/// - Parameter friendModelArr: ZFriendModel数组
- (NSArray *)customCompareArr:(NSMutableArray <NoaFriendModel *> *)friendModelArr {
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"sortName" ascending:YES comparator:^NSComparisonResult(id obj1, id obj2) {
        return customCompare(obj1, obj2, 0);
    }];
    NSArray *sortedFriendsArray =  [friendModelArr sortedArrayUsingDescriptors:@[sortDescriptor]];
    return sortedFriendsArray;
}

/// 清理数据
- (void)clearFriendDataOnMainThread {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.firstLetterArr removeAllObjects];
        [self.sortedModelDict removeAllObjects];
        self.baseTableView.sc_indexViewDataSource = self.firstLetterArr;
        [self.baseTableView reloadData];
    });
}




@end
