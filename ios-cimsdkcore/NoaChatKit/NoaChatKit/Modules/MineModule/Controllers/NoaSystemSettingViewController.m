//
//  NoaSystemSettingViewController.m
//  NoaKit
//
//  Created by Mac on 2022/11/13.
//

#import "NoaSystemSettingViewController.h"
#import "NoaSystemSettingCell.h"
#import "NoaSystemFooterView.h"
#import "NoaToolManager.h"
#import "NoaAboutUsViewController.h"
#import "NoaMessageAlertView.h"
#import "NoaToolManager.h"
#import "NoaAccountRemoveViewController.h"

//#import "ZContentTranslateViewController.h"//内容翻译

@interface NoaSystemSettingViewController () <UITableViewDelegate, UITableViewDataSource, ZBaseCellDelegate>

@property (nonatomic, strong) NSArray *dataArr;
@property (nonatomic, assign) int isNewMsgNotify;
@property (nonatomic, assign) int isShakeNotice;
@property (nonatomic, assign) int isVoiceNotice;

@end

@implementation NoaSystemSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navTitleStr = LanguageToolMatch(@"系统设置");
    [self setUpData];
    [self setupUI];
    
    //获取用户系统设置信息
    [self requestGetSystemSetInfo];
}

- (void)setUpData {
    
    self.dataArr = @[
                    @[LanguageToolMatch(@"新消息通知"), LanguageToolMatch(@"声音"), LanguageToolMatch(@"震动")],
                    @[LanguageToolMatch(@"清理缓存")],
                    @[LanguageToolMatch(@"注销账号")],
                    @[LanguageToolMatch(@"退出登录")]
                    ];

}

- (void)setupUI {
    self.baseTableView.delegate = self;
    self.baseTableView.dataSource = self;
    self.baseTableView.bounces = NO;
    self.baseTableView.delaysContentTouches = NO;
    self.baseTableView.tkThemebackgroundColors = @[COLOR_F5F6F9, COLOR_11];
    [self.view addSubview:self.baseTableView];
    [self.baseTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(DNavStatusBarH);
        make.leading.trailing.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(-DHomeBarH);
    }];
    
    [self.baseTableView registerClass:[NoaSystemSettingCell class] forCellReuseIdentifier:NSStringFromClass([NoaSystemSettingCell class])];
    [self.baseTableView registerClass:[NoaSystemFooterView class] forHeaderFooterViewReuseIdentifier:NSStringFromClass([NoaSystemFooterView class])];
}

#pragma mark - UITableViewDelegate  UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.dataArr.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *itemArr = (NSArray *)[self.dataArr objectAtIndex:section];
    return itemArr.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return DWScale(54);
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return DWScale(16);
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 2) {
        CGSize footerContentSize = [LanguageToolMatch(@"注销账号后无法通过账号找到你，你也无法再登录此账号。你的消息将全部清空，但对方接收的消息依然存在") sizeWithFont:FONTR(14) constrainedToSize:CGSizeMake( DScreenWidth - 16*2, 10000)];
        return footerContentSize.height + 10;
    } else {
        return CGFLOAT_MIN;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, DScreenWidth, DWScale(16))];
    headerView.tkThemebackgroundColors = @[COLOR_F5F6F9, COLOR_11];
    return headerView;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 2) {
        NoaSystemFooterView *viewFooter = [tableView dequeueReusableHeaderFooterViewWithIdentifier:NSStringFromClass([NoaSystemFooterView class])];
        viewFooter.contentStr = LanguageToolMatch(@"注销账号后无法通过账号找到你，你也无法再登录此账号。你的消息将全部清空，但对方接收的消息依然存在");
        return viewFooter;
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NoaSystemSettingCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([NoaSystemSettingCell class]) forIndexPath:indexPath];
    NSArray *itemArr = (NSArray *)[self.dataArr objectAtIndex:indexPath.section];
    if (indexPath.section == 0) {
        cell.leftTitleStr = (NSString *)[itemArr objectAtIndex:indexPath.row];
        if (indexPath.row == 0) {
            cell.switchIsOn = self.isNewMsgNotify == 0 ? NO : YES;
        }
        if (indexPath.row == 1) {
            cell.switchIsOn = self.isVoiceNotice == 0 ? NO : YES;
        }
        if (indexPath.row == 2) {
            cell.switchIsOn = self.isShakeNotice == 0 ? NO : YES;
        }
        WeakSelf
        cell.switchBlock = ^(BOOL isOn) {
            [weakSelf settingCellSwitch:isOn index:indexPath.row];
        };
    }
    if (indexPath.section == 1) {
        cell.leftTitleStr = (NSString *)[itemArr objectAtIndex:indexPath.row];
        if (indexPath.row == 0) {
            cell.rightTitleStr = [self getCacheSizeMedth];
        }
    }
    if (indexPath.section == 2) {
        cell.leftTitleStr = (NSString *)[itemArr objectAtIndex:indexPath.row];
        if (indexPath.row == 0) {
            cell.rightTitleStr = LanguageToolMatch(@"不可撤回");
        }
    }
    if (indexPath.section == 3) {
        cell.centerTitleStr = (NSString *)[itemArr objectAtIndex:indexPath.row];
    }
    [cell configCellRoundWithCellIndex:indexPath.row totalIndex:itemArr.count];
    cell.baseCellIndexPath = indexPath;
    cell.baseDelegate = self;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - ZBaseCellDelegate
- (void)cellClickAction:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            //清理缓存
            NoaMessageAlertView *msgAlertView = [[NoaMessageAlertView alloc] initWithMsgAlertType:ZMessageAlertTypeTitle supView:nil];
            msgAlertView.lblTitle.text = LanguageToolMatch(@"清理缓存");
            msgAlertView.lblContent.text = LanguageToolMatch(@"只清理本地图片视频等缓存，不清理文本信息");
            [msgAlertView.btnSure setTitle:LanguageToolMatch(@"立即清理") forState:UIControlStateNormal];
            [msgAlertView.btnCancel setTitle:LanguageToolMatch(@"取消") forState:UIControlStateNormal];
            [msgAlertView alertShow];
            WeakSelf
            msgAlertView.sureBtnBlock = ^(BOOL isCheckBox) {
                [weakSelf clearLocalCache];
            };
            
            return;
        }
    }
    
    if (indexPath.section == 2) {
        if (indexPath.row == 0) {
            //注销账号
            [self accountLogoutAction];
        }
    }
    
    if (indexPath.section == 3) {
        if (indexPath.row == 0) {
            NoaMessageAlertView *msgAlertView = [[NoaMessageAlertView alloc] initWithMsgAlertType:ZMessageAlertTypeTitle supView:nil];
            msgAlertView.lblTitle.text = LanguageToolMatch(@"退出登录");
            msgAlertView.lblContent.text = LanguageToolMatch(@"确定要退出当前账户?");
            [msgAlertView.btnSure setTitle:LanguageToolMatch(@"确认") forState:UIControlStateNormal];
            [msgAlertView.btnCancel setTitle:LanguageToolMatch(@"取消") forState:UIControlStateNormal];
            [msgAlertView alertShow];
            WeakSelf
            msgAlertView.sureBtnBlock = ^(BOOL isCheckBox) {
                //退出登录
                [weakSelf logoutBtnAction];
            };
        }
    }
}

- (void)settingCellSwitch:(BOOL)isOn index:(NSInteger)index {
    if (index == 0) {
        self.isNewMsgNotify = isOn ? 1 : 0;
    }
    if (index == 1) {
        self.isVoiceNotice = isOn ? 1 : 0;
    }
    if (index == 2) {
        self.isShakeNotice = isOn ? 1 : 0;
    }
    //调用接口
    [self requestSetSystemSetting];
}

#pragma mark - 更新SDK的消息提醒状态
- (void)updateSDKMessageRemindState {
    [IMSDKManager toolMessageReceiveRemindOpen:self.isNewMsgNotify == 1];
    [IMSDKManager toolMessageReceiveRemindVoiceOpen:self.isVoiceNotice == 1];
    [IMSDKManager toolMessageReceiveRemindVibrationOpen:self.isShakeNotice == 1];
}

//跳转到注销账号流程
- (void)accountLogoutAction {
    NoaAccountRemoveViewController *accountRemove = [[NoaAccountRemoveViewController alloc] init];
    [self.navigationController pushViewController:accountRemove animated:YES];
}

#pragma mark - 网络请求
//获取用户系统设置信息
- (void)requestGetSystemSetInfo {
    WeakSelf
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:UserManager.userInfo.userUID forKey:@"userUid"];
    [IMSDKManager userGetMessageRemindWith:dict onSuccess:^(id _Nullable data, NSString * _Nullable traceId) {
        if ([data isKindOfClass:[NSDictionary class]]) {
            NSDictionary *dataDict = (NSDictionary *)data;
            weakSelf.isNewMsgNotify = [[dataDict objectForKey:@"isNewMsgNotify"] intValue];
            weakSelf.isShakeNotice = [[dataDict objectForKey:@"isShakeNotice"] intValue];
            weakSelf.isVoiceNotice = [[dataDict objectForKey:@"isVoiceNotice"] intValue];
            [weakSelf.baseTableView reloadData];
            [weakSelf updateSDKMessageRemindState];
        }
    } onFailure:^(NSInteger code, NSString * _Nullable msg, NSString * _Nullable traceId) {
    }];
}

//设置用户系统信息
- (void)requestSetSystemSetting {
    WeakSelf
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:UserManager.userInfo.userUID forKey:@"userUid"];
    [dict setValue:@(self.isNewMsgNotify) forKey:@"isNewMsgNotify"];
    [dict setValue:@(self.isShakeNotice) forKey:@"isShakeNotice"];
    [dict setValue:@(self.isVoiceNotice) forKey:@"isVoiceNotice"];
    [IMSDKManager userMessageRemindSetWith:dict onSuccess:^(id _Nullable data, NSString * _Nullable traceId) {
        [weakSelf.baseTableView reloadData];
        [weakSelf updateSDKMessageRemindState];
    } onFailure:^(NSInteger code, NSString * _Nullable msg, NSString * _Nullable traceId) {
        [HUD showMessageWithCode:code errorMsg:msg];
    }];
}

#pragma mark - Action
//退出登录
- (void)logoutBtnAction {
    NoaUserModel *userModel = [NoaUserModel getUserInfo];
    //退出登录接口
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObjectSafe:userModel.userUID forKey:@"userUid"];
    [params setObjectSafe:userModel.token forKey:@"tokenLogin"];
    [IMSDKManager authUserLogoutWith:params onSuccess:nil onFailure:nil];
    
    // 退出到登录页面
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [HUD showMessage:LanguageToolMatch(@"退出账号成功")];
        [ZTOOL setupLoginUI];
    });
}

#pragma mark - Common
//计算缓存文件大小
- (NSString *)getCacheSizeMedth {
    NSFileManager *manager = [NSFileManager defaultManager];
    //本地文件总大小
    NSInteger totalSize = 0;
    //图片、视频、语音、文件等 路径
    NSString *openIMPath = [NSString stringWithFormat:@"OpenIM/"];
    NSString *imgDiectoryPath = [NSTemporaryDirectory() stringByAppendingPathComponent:openIMPath];
    NSArray *subPathArr = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:imgDiectoryPath error:nil];
    
    for (NSString *filePath in subPathArr) {
        NSString *path = [imgDiectoryPath stringByAppendingPathComponent:filePath];
        // 判断是否为文件
        BOOL isDir = NO;
        [manager fileExistsAtPath:path isDirectory:&isDir];
        if (!isDir) {
            NSDictionary *attrs = [manager attributesOfItemAtPath:path error:nil];
            totalSize += [attrs[NSFileSize] integerValue];
        }
    }
    
    //SDWebImage
    NSUInteger SDImageSize = [[SDImageCache sharedImageCache] totalDiskSize];
    totalSize += SDImageSize;
    
    //将文件夹大小转换为 M/KB/B
    NSString *totleStr = nil;

    if (totalSize < 1024) { //小于1k
        totleStr = [NSString stringWithFormat:@"%ldB",(long)totalSize];
    } else if (totalSize < 1024.0 * 1024) { //小于1M
        CGFloat cFloat = totalSize / 1024.0;
        totleStr = [NSString stringWithFormat:@"%.1fKB",cFloat];
    } else if (totalSize < 1024.0 * 1024 * 1024) { //小于1G
        CGFloat cFloat = totalSize / (1024.0 * 1024);
        totleStr = [NSString stringWithFormat:@"%.1fMB",cFloat];
    } else { //大于1G
        CGFloat cFloat = totalSize / (1024.0 * 1024 * 1024);
        totleStr = [NSString stringWithFormat:@"%.1fGB",cFloat];
    }
    return totleStr;
}

//清除缓存
- (void)clearLocalCache {
    [HUD showMessage:LanguageToolMatch(@"正在清理缓存...")];
    //图片、视频、语音、文件
    NSString *openIMPath = [NSString stringWithFormat:@"OpenIM/"];
    NSString *imDiectoryPath = [NSTemporaryDirectory() stringByAppendingPathComponent:openIMPath];
    NSArray *subPathArr = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:imDiectoryPath error:nil];
    
    NSString *filePath = nil;
    NSError *error = nil;
    for (NSString *subPath in subPathArr)
    {
        filePath = [imDiectoryPath stringByAppendingPathComponent:subPath];
        //删除子文件夹
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
    }
    
    NoaSsoInfoModel *ssoInfoModel = [NoaSsoInfoModel getSSOInfo];
    [[MMKV defaultMMKV] removeValueForKey:[NSString stringWithFormat:@"%@%@",CONNECT_LOCAL_CACHE,ssoInfoModel.liceseId]];
    [NoaSsoInfoModel clearSSOInfoWithLiceseId:ssoInfoModel.liceseId];
    
    //清除SDWebImage缓存数据
    WeakSelf
    [[SDImageCache sharedImageCache] clearDiskOnCompletion:^{
        [HUD showMessage:LanguageToolMatch(@"清理完成")];
        [weakSelf.baseTableView reloadData];
    }];
    
}

@end
