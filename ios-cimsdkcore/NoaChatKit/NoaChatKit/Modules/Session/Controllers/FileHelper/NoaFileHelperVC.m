//
//  NoaFileHelperVC.m
//  NoaKit
//
//  Created by mac on 2023/6/6.
//

#import "NoaFileHelperVC.h"
#import "SyncMutableArray.h"//同步可变数组
//消息展示Cell
#import "NoaMessageBaseCell.h"
#import "NoaMessageTextCell.h"
#import "NoaMessageImageCell.h"
#import "NoaMessageVideoCell.h"
#import "NoaMessageSystemCell.h"
#import "NoaMessageReferenceCell.h"
#import "NoaMessageAtUserCell.h"
#import "NoaMessageFileCell.h"
#import "NoaMessageVoiceCell.h"
#import "NoaMessageCallCell.h"
#import "NoaMessageGroupNoticeCell.h"
#import "NoaMessageGeoCell.h"
#import "NoaMessageCardCell.h"
#import "NoaMergeMessageRecordCell.h"
#import "NoaMessageStickersCell.h"
#import "NoaMessageGameStickersCell.h"

#import "NoaChatTopView.h"//顶部自定义导航栏
#import "NoaChatInputView.h"//底部输入框
#import "NoaChatMessageMoreView.h"//消息长按 更多功能
#import "NoaImagePickerVC.h"//相册
#import "NoaFilePickerVC.h"//文件
#import "NoaMessageSendHander.h"//消息发送工具
#import "NoaToolManager.h"//工具类
#import "NoaChatMultiSelectViewController.h"//消息转发选择转发对象
#import "NoaChatSingleSetVC.h"//单聊设置VC
#import "NoaAudioPlayManager.h"//语音消息播放单例
#import "NoaChatFileDetailViewController.h"//文件消息中文件详情
#import "KNPhotoBrowser.h"//图片视频浏览
//#import "ZFileNetProgressManager.h"//文件上传
#import "NoaMyCollectionViewController.h"//收藏
#import "NoaChatMultiSelectSendHander.h"
#import "NoaMessageMultiBottomView.h" //多选bottom
#import "NoaChatRecordDetailViewController.h" //会话记录详情
#import "NoaUserHomePageVC.h"//用户主页
#import "NoaMessageAlertView.h"//弹窗提示类的控件
#import "NoaMessageTools.h"//消息工具类
#import "NoaFileHelperSetVC.h"//文件助手 设置VC
#import "NoaSensitiveManager.h" //敏感词过滤
#import "NoaMessageTimeTool.h"
#import "NoaEmojiShopViewController.h"
#import "NoaEmojiPackageDetailViewController.h"//表情包详情
#import "NoaFileUploadManager.h"
#import "NoaMessageSendTask.h"

//多选 最大选择个数
#define Multi_Selected_Max_Num      100

@interface NoaFileHelperVC () <ZChatInputViewDelegate, UITableViewDelegate, UITableViewDataSource, ZMessageBaseCellDelegate, NoaToolMessageDelegate, ZImagePickerVCDelegate, UIDocumentInteractionControllerDelegate, KNPhotoBrowserDelegate, ZMsgMultiSelectDelegate, ZFileUploadTaskDelegate>
//显示刷新界面的专门队列(消息更新)
@property (nonatomic, strong) dispatch_queue_t chatMessageUpdateQueue;
//显示刷新界面的专门队列(消息的时间计算)
@property (nonatomic, strong) dispatch_queue_t chatMessageCalculateTimeQueue;
@property (nonatomic, strong) NoaChatTopView *topView;//顶部导航栏(自定义)
@property (nonatomic, strong) NoaChatInputView *viewInput;//底部输入框
@property (nonatomic, strong) NSIndexPath *chatHistorySelectIndex;//搜索历史文本消息定位的cell位置
@property (nonatomic, strong) NSArray *currentImageVideoMessageList;//当前聊天里的图片视频列表
//@property (nonatomic, strong) ZFileNetProgressManager *fileUploader;//文件上传
@property (nonatomic, strong) NoaChatMultiSelectSendHander *collectionSendHander;//收藏回调
@property (nonatomic, assign) BOOL multiSelectStatus; //是否为多选状态
@property (nonatomic, strong) NoaMessageMultiBottomView *multiSelectBottomView;//多选-底部操作栏
@property (nonatomic, strong) SyncMutableArray *selectedMsgModels;//多选消息
@property (nonatomic, strong) UIButton *btnBottom;//消息滚动到底部功能按钮
//消息显示数据
@property (nonatomic, strong) SyncMutableArray *messageModels;
@property (nonatomic, assign) NSInteger pageNumber;
@end

@implementation NoaFileHelperVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //默认参数
    _pageNumber = 1;
    _multiSelectStatus = NO;
    
    //队列初始化
    _chatMessageUpdateQueue = dispatch_queue_create("com.CIMKit.chatMessageUpdateQueue", DISPATCH_QUEUE_SERIAL);
    _chatMessageCalculateTimeQueue = dispatch_queue_create("com.CIMKit.chatMessageCalculateTimeQueue", DISPATCH_QUEUE_SERIAL);
    
    //界面布局
    [self setupUI];
    
    [self.baseTableView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyBoardAndEmjoy)]];
    
    //通知监听
    [self chatViewAddObserver];
    
    //设置接受消息delegate
    [IMSDKManager addMessageDelegate:self];
    
    //消息请求加载
    [self requestHistoryList];
    

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [IQKeyboardManager sharedManager].enable = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    //立刻聊天界面关闭键盘
    [self.viewInput inputViewResignFirstResponder];
    [IQKeyboardManager sharedManager].enable = YES;
    
    
    //离开聊天界面时，停止语音播放和播放的动画
    if (ZAudioPlayerTOOL.isPlaying) {
        [ZAudioPlayerTOOL stop];
    }
    
    if (ZAudioPlayerTOOL.currentVoiceCell) {
        [ZAudioPlayerTOOL stop];
        [ZAudioPlayerTOOL.currentVoiceCell stopAnimation];
    }
}

- (void)hideKeyBoardAndEmjoy{
    [self.viewInput inputViewResignFirstResponder];
}
#pragma mark - 界面布局
- (void)setupUI {
    
    self.view.tkThemebackgroundColors = @[COLOR_F5F6F9, COLOR_EEEEEE_DARK];
    
    self.navView.hidden = YES;
    UIView *viewTopBg = [[UIView alloc] initWithFrame:CGRectMake(0, 0, DScreenWidth, DNavStatusBarH)];
    viewTopBg.tkThemebackgroundColors = @[COLORWHITE, COLORWHITE_DARK];
    [self.view addSubview:viewTopBg];
    
    
    _topView = [[NoaChatTopView alloc] initWithFrame:CGRectMake(0, DStatusBarH, DScreenWidth, 44)];
    _topView.chatName = LanguageToolMatch(@"文件助手");
    _topView.btnTime.hidden = YES;
    _topView.tipExplainLbl.hidden = YES;
    _topView.tipLockImgView.hidden = YES;
    _topView.isShowTagTool = NO;
    [self.view addSubview:_topView];
    //更新标题布局
    [_topView.chatNameLbl mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(_topView);
        make.height.mas_equalTo(DWScale(20));
        make.width.mas_equalTo(DWScale(220));
    }];
    
    WeakSelf;
    //返回上一级
    _topView.navBackBlock = ^{
        [weakSelf.navigationController popViewControllerAnimated:YES];
    };
    
    //跳转文件助手设置界面
    _topView.navRightBlock = ^{
        NoaFileHelperSetVC *vc = [NoaFileHelperSetVC new];
        vc.sessionID = weakSelf.sessionID;
        [weakSelf.navigationController pushViewController:vc animated:YES];
    };

    //取消多选
    _topView.navCancelBlock = ^{
        [weakSelf setupMultiSelectedStatusDefaultIsReload:YES];
    };

    self.baseTableView.delegate = self;
    self.baseTableView.dataSource = self;
    self.baseTableView.tkThemebackgroundColors = @[COLOR_F5F6F9, COLOR_EEEEEE_DARK];
    self.baseTableView.estimatedRowHeight = 0;
    self.baseTableView.estimatedSectionHeaderHeight = 0;
    self.baseTableView.estimatedSectionFooterHeight = 0;
    [self.view addSubview:self.baseTableView];
    [self.baseTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_topView.mas_bottom);
        make.leading.trailing.equalTo(weakSelf.view);
        make.bottom.equalTo(weakSelf.view).offset(-(DWScale(56 + 50) + DHomeBarH));
    }];
    //添加下拉加载
    self.baseTableView.mj_header = self.refreshHeader;
    
    //底部输入框
    self.viewInput = [[NoaChatInputView alloc] initWithFrame:CGRectMake(0, DScreenHeight - DWScale(56 + 50) - DHomeBarH, DScreenWidth, DWScale(56 + 50) + DHomeBarH)];
    self.viewInput.moreType = ZChatInputViewTypeFileHelper;
    self.viewInput.sessionID = self.sessionID;
    self.viewInput.delegate = self;
    self.viewInput.inputContentStr = @"";
    [self.view addSubview:self.viewInput];
    
    //多选底部控件
    [self.view addSubview:self.multiSelectBottomView];
    
    //消息滚动到底部
    self.btnBottom = [UIButton buttonWithType:UIButtonTypeCustom];
    self.btnBottom.hidden = YES;
    [self.btnBottom setImage:ImgNamed(@"c_go_bottom") forState:UIControlStateNormal];
    [self.btnBottom addTarget:self action:@selector(btnBottomClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.btnBottom];
    [self.btnBottom mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.viewInput.mas_top).offset(-DWScale(25));
        make.trailing.equalTo(self.view).offset(-DWScale(20));
        make.size.mas_equalTo(CGSizeMake(DWScale(36), DWScale(36)));
    }];
}

- (void)setupMultiSelectedStatusDefaultIsReload:(BOOL)isRelaod {
    self.multiSelectStatus = NO;
    self.multiSelectBottomView.selectNum = 0;
    self.multiSelectBottomView.hidden = YES;
    [self.baseTableView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.view);
        make.top.equalTo(_topView.mas_bottom);
        make.bottom.equalTo(self.viewInput.mas_top);
    }];
    [self.selectedMsgModels removeAllObjects];
    self.topView.showCancel = NO;
    
    [self.messageModels enumerateObjectsUsingBlock:^(NoaMessageModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.multiSelected = NO;
    }];
    if (isRelaod) {
        [self.baseTableView reloadData];
    }
    //显示底部输入框
    self.viewInput.hidden = NO;
}

#pragma mark - 各种通知监听处理
- (void)chatViewAddObserver {
    //通用监听
    //查询历史消息后点击跳转到消息为止的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestSelectHistoryList:) name:@"ChatHistorySelectMessage" object:nil];
    //搜索历史记录页面接收到删除文件的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadMessageTabView:) name:@"HistoryVCDeleteFileNotification" object:nil];
    //用户角色权限发生变化(是否线上文件助手)
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userRoleAuthorityFileHelperChange) name:@"UserRoleAuthorityFileHelperChangeNotification" object:nil];
}

#pragma mark - 获取消息记录
- (void)requestHistoryList {
    
    NoaMessageModel *model = [self.messageModels objectAtIndex:0];
    NSString *serviceMsgID = model.message.serviceMsgID;
    
    WeakSelf
    [IMSDKManager messageGetHistoryRecordWith:_sessionID chatType:CIMChatType_SingleChat serviceMsgID:serviceMsgID offset:self.messageModels.count pageNum:_pageNumber historyList:^(NSArray<NoaIMChatMessageModel *> * _Nullable chatMessageHistory, NSInteger offset, BOOL isLocal, NSInteger pageNumber) {
        
        if (chatMessageHistory.count > 0) {
            weakSelf.pageNumber = pageNumber;
            [weakSelf dealChatMessageHistoryWith:chatMessageHistory offset:offset];
        }
        [ZTOOL doInMain:^{
            [weakSelf.baseTableView.mj_header endRefreshing];
        }];
    }];
}

- (void)headerRefreshData {
    [self requestHistoryList];
}
//消息处理
- (void)dealChatMessageHistoryWith:(NSArray<NoaIMChatMessageModel *> * _Nullable) chatMessageHistory offset:(NSInteger)offset {
    WeakSelf
    dispatch_async(_chatMessageUpdateQueue, ^{
        
        __block NSMutableArray *newMessageList = [[NSMutableArray alloc] init];
        
        [chatMessageHistory enumerateObjectsUsingBlock:^(NoaIMChatMessageModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NoaMessageModel *newMsgModel = [[NoaMessageModel alloc] initWithMessageModel:obj];
            [newMessageList addObject:newMsgModel];
        }];
        
        
        if (offset ==0) {
            //首次进入界面 / 最新消息同步完成
            [weakSelf.messageModels removeAllObjects];
            [weakSelf.messageModels addObjectsFromArray:newMessageList];
        }else{
            NSRange range = NSMakeRange(0, newMessageList.count);
            NSIndexSet *nsindex = [NSIndexSet indexSetWithIndexesInRange:range];
            [weakSelf.messageModels insertObjects:newMessageList atIndexes:nsindex];
        }
        
        //处理消息是否显示时间
        [weakSelf computeVisibleTime];
        
        [ZTOOL doInMain:^{
            [weakSelf.baseTableView reloadData];
            
            if (offset == 0) {
                //必须再延迟执行一次滚动到最底部，不然最下面一条消息可能会被挡住
                dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC));
                dispatch_after(delayTime, dispatch_get_main_queue(), ^{
                    //加载滚动到底部
                    [weakSelf tableViewScrollToBottom:NO duration:0.25];
                });
                
            } else {
                //下拉加载，将新加载数据的最后一条，滚动到顶部
                if (newMessageList.count > 0) {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:newMessageList.count inSection:0];
                    [weakSelf.baseTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
                }
            }
        }];
    });
}

#pragma mark - <<<<<<NSNotification通知监听方法处理>>>>>>
//接收到删除文件的通知刷新当前页面
- (void)reloadMessageTabView:(NSNotification *)sender{
    //更新聊天页面
    NoaMessageModel * msgModel;
    NoaMessageModel * senderMsgModel = sender.object;
    for (NoaMessageModel * messageModel in self.messageModels.safeArray) {
        if([senderMsgModel.message.serviceMsgID isEqualToString:messageModel.message.serviceMsgID]){
            msgModel = messageModel;
            break;
        }
    }
    [self.messageModels removeObject:msgModel];
    
    //处理消息是否显示时间
    [self computeVisibleTime];
    
    WeakSelf
    [ZTOOL doInMain:^{
        [weakSelf.baseTableView reloadData];
    }];
    
    if ([[sender.userInfo objectForKeySafe:@"deleteType"] integerValue] == ZMsgDeleteTypeOneWay) {
        [self updateRefreshMsgWithOriginalMsg:msgModel.message.serviceMsgID];
    }
}

//获得选中消息列表
- (void)requestSelectHistoryList:(NSNotification *)sender {
    NSDictionary *userInfo = sender.userInfo;
    
    if ([userInfo.allKeys containsObject:@"selectMessageID"]) {
        NSString *messageID = [userInfo objectForKeySafe:@"selectMessageID"];
        long long startTime = [[userInfo objectForKeySafe:@"selectMessageSendTime"] longLongValue];
        
        //优化一下，不需要每次都查询数据，兼容某些系统不生效的问题
        //当前显示的第一条消息发送实现
        long long nowFirstMessageTime = 0;
        if (self.messageModels.count > 0) {
            NoaMessageModel *model = [self.messageModels objectAtIndex:0];
            nowFirstMessageTime = model.message.sendTime;
        }
        
        __block NSInteger modelIndex = 0;
        if (startTime < nowFirstMessageTime) {
            //被选中的消息，不在当前列表里，查询此时间范围内消息。为了界面体验，多请求一点数据
            __block NSMutableArray *newMessageList = [[NSMutableArray alloc] init];
            
            //查询到的数据
            NSMutableArray *history = [IMSDKManager toolGetChatMessageHistoryWith:_sessionID startTime:startTime endTime:nowFirstMessageTime].mutableCopy;
            //多请求一点数据
            NSArray *moreHistory = [IMSDKManager toolGetChatMessageHistoryWith:_sessionID offset:history.count + self.messageModels.count];
            NSRange moreRange = NSMakeRange(0, moreHistory.count);
            NSIndexSet *moreIndex = [NSIndexSet indexSetWithIndexesInRange:moreRange];
            [history insertObjects:moreHistory atIndexes:moreIndex];
            
            [history enumerateObjectsUsingBlock:^(NoaIMChatMessageModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NoaMessageModel *newMsgModel = [[NoaMessageModel alloc] initWithMessageModel:obj];
                [newMessageList addObject:newMsgModel];
                if ([obj.msgID isEqualToString:messageID]) {
                    modelIndex = idx;
                }
            }];
            NSRange range = NSMakeRange(0, newMessageList.count);
            NSIndexSet *nsindex = [NSIndexSet indexSetWithIndexesInRange:range];
            [self.messageModels insertObjects:newMessageList atIndexes:nsindex];
            
        } else {
            [self.messageModels enumerateObjectsUsingBlock:^(NoaMessageModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj.message.msgID isEqualToString:messageID]) {
                    modelIndex = idx;
                    *stop = YES;
                }
            }];
        }
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:modelIndex inSection:0];
        _chatHistorySelectIndex = indexPath;
        [self.baseTableView reloadData];
        
        //延迟执行滚动到指定位置
        
        //防止越界崩溃
        //当前总行数下标
        NSInteger totalRowIndex = [self.baseTableView numberOfRowsInSection:0] - 1;
        if (_chatHistorySelectIndex.row > totalRowIndex) {
            _chatHistorySelectIndex = [NSIndexPath indexPathForRow:totalRowIndex inSection:0];
        }
        
        WeakSelf
        dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC));
        dispatch_after(delayTime, dispatch_get_main_queue(), ^{
            [weakSelf.baseTableView scrollToRowAtIndexPath:weakSelf.chatHistorySelectIndex atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
            [weakSelf checkVisibleCellDoAnimation];
        });
    }
}

//添加表情图片到表情收藏
- (void)requestAddStickersToCollectionWithDic:(NSMutableDictionary *)dict  isReloadCollection:(BOOL)isReloadCollection {
    WeakSelf
    [IMSDKManager imSdkUserAddStickersToCollectList:dict onSuccess:^(id _Nullable data, NSString * _Nullable traceId) {
        [HUD showMessage:LanguageToolMatch(@"操作成功")];
        if (isReloadCollection) {
            [weakSelf.viewInput reloadGetMyCollectionStickers];
        }
    } onFailure:^(NSInteger code, NSString * _Nullable msg, NSString * _Nullable traceId) {
        [HUD showMessageWithCode:code errorMsg:msg];
    }];
}

// 获取可视化的cell执行选中的动画
- (void)checkVisibleCellDoAnimation {
    if (!_chatHistorySelectIndex) return;;
    
    NoaMessageModel *selectedModel = [self.messageModels objectAtIndex:_chatHistorySelectIndex.row];
    WeakSelf
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [ZTOOL doInMain:^{
            NSArray <NSIndexPath *> *visibleList = [weakSelf.baseTableView indexPathsForVisibleRows];
            [visibleList enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NoaMessageModel *model = [weakSelf.messageModels objectAtIndex:obj.row];
                if ([selectedModel.message.msgID isEqualToString:model.message.msgID]) {
                    //需要执行动画的cell
                    NoaMessageBaseCell *cellBase = [weakSelf.baseTableView cellForRowAtIndexPath:weakSelf.chatHistorySelectIndex];
                    [cellBase mesaagePositionAnimation];
                    //动画执行完后，注销记录
                    weakSelf.chatHistorySelectIndex = nil;
                    *stop = YES;
                }
            }];
            
        }];
    });
}

#pragma mark - Notification
- (void)userRoleAuthorityFileHelperChange {
    if ([UserManager.userRoleAuthInfo.isShowFileAssistant.configValue isEqualToString:@"false"]) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - <<<<<<ZChatInputViewDelegate 底部输入框代理>>>>>>
//输入框高度变化
- (void)chatInputViewHeightChanged:(CGFloat)heigh {
    WeakSelf
    [UIView animateWithDuration:0.3 animations:^{
        weakSelf.viewInput.height = heigh;
        weakSelf.viewInput.y = DScreenHeight - heigh;
        
        //输入框和键盘发生高度变化时，修改聊天tableView的contentInset
        weakSelf.baseTableView.contentInset = UIEdgeInsetsMake(0, 0, heigh - DWScale(56 + 50) - DHomeBarH, 0);
        
        [weakSelf.btnBottom mas_updateConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(weakSelf.viewInput.mas_top).offset(-DWScale(25));
        }];
        //加载滚动到底部
        [weakSelf tableViewScrollToBottom:YES duration:0.25];
    }];
}

//文本消息 发送
- (void)chatInputViewSend:(NSString *)sendStr atUserList:(NSArray *)atUsersDictList atUserSegmentList:(NSArray *)atUserSegmentList {
    //发送内容不能为空
    if ([NSString isNil:sendStr]) {
        [HUD showMessage:LanguageToolMatch(@"发送内容不能为空")];
        return;
    }

    //文件助手不发送 @消息
    NSString *referenceId = @"";
    if (self.viewInput.messageModelReference) {
        //文本消息-引用
        referenceId = self.viewInput.messageModelReference.message.serviceMsgID;
    } else {
        //普通文本消息
        referenceId = @"";
    }
    
    NoaIMChatMessageModel *textSendMsg = [NoaMessageSendHander ZMessageTextSend:ZSensitiveFilter(sendStr) withToUserId:self.sessionID  withChatType:CIMChatType_SingleChat referenceMsgId:referenceId];
    
    //发送消息
    [IMSDKManager toolSendChatMessageWith:textSendMsg];
    
    //添加到UI上
    [self chatListAppendMessage:textSendMsg];
    
    //如果发送的是引用消息，将输入框上引用内容的UI隐藏
    if (self.viewInput.messageModelReference) {
        WeakSelf
        [ZTOOL doInMain:^{
            weakSelf.viewInput.messageModelReference = nil;
        }];
    }
   
    //输入框置空并恢复初始状态
    WeakSelf
    [ZTOOL doInMain:^{
        weakSelf.viewInput.inputContentStr = @"";
    }];
}

// 语音消息发送(录制完成的音频文件路径、音频名称、音频时长)
- (void)chatInputViewVoicePath:(NSString *)vociePath voiceName:(NSString *)voiceName voiceDuration:(CGFloat)voiceDuration{
    WeakSelf
    [NoaMessageSendHander ZMessageVoiceSend:vociePath fileName:voiceName voiceDuring:voiceDuration withToUserId:self.sessionID withChatType:CIMChatType_SingleChat compelete:^(NoaIMChatMessageModel * _Nonnull sendChatMsg) {
        //上传的语音文件
        NSData *audioData = [NSData dataWithContentsOfFile:sendChatMsg.localVoicePath options:NSDataReadingMappedIfSafe error:nil];
        NoaFileUploadTask *audioTask = [[NoaFileUploadTask alloc] initWithTaskId:sendChatMsg.msgID filePath:sendChatMsg.localVoicePath originFilePath:@"" fileName:sendChatMsg.localVoiceName fileType:@"" isEncrypt:NO dataLength:audioData.length uploadType:ZHttpUploadTypeVoice beSendMessage:sendChatMsg delegate:self];
        audioTask.messageTaskType = FileUploadMessageTaskTypeVoice;

        NSBlockOperation * blockOperation = [NSBlockOperation blockOperationWithBlock:^{
            NSLog(@"地理位置图片上传任务完成");
            if (audioTask.status == FileUploadTaskStatus_Completed) {
                sendChatMsg.voiceName = audioTask.originUrl;
                [IMSDKManager toolSendChatMessageWith:sendChatMsg];
            }
            if (audioTask.status == FileUploadTaskStatus_Failed) {
                [ZTOOL doInMain:^{
                    [HUD showMessage:LanguageToolMatch(@"上传失败")];
                }];
            }
        }];
        NoaFileUploadGetSTSTask *getSTSTask = [[NoaFileUploadGetSTSTask alloc] init];
        [audioTask addDependency:getSTSTask];
        [blockOperation addDependency:audioTask];
        
        [[NoaFileUploadManager sharedInstance].operationQueue addOperation:getSTSTask];
        [[NoaFileUploadManager sharedInstance] addUploadTask:audioTask];
        [[NoaFileUploadManager sharedInstance].operationQueue addOperation:blockOperation];

        //将配置好的消息 1.存储到数据库 2.添加到UI上展示(此时展示的图片或视频还没上传完成，正在上传中...)
        [IMSDKManager toolInsertOrUpdateChatMessageWith:sendChatMsg];
        [weakSelf chatListAppendMessage:sendChatMsg];
    }];
}

//选择图片/视频
- (void)chatInputViewShowImage {
    //先检测权限，再进入相册，解决某些系统第一次不能获取照片，杀死进程后可以获取照片的问题
    WeakSelf
    [ZTOOL getPhotoLibraryAuth:^(BOOL granted) {
        if (granted) {
            [ZTOOL doInMain:^{
                NoaImagePickerVC *vc = [NoaImagePickerVC new];
                vc.maxSelectNum = 9;
                vc.isNeedEdit = NO;
                vc.hasCamera = YES;
                vc.delegate = self;
                [vc setPickerType:ZImagePickerTypeAll];
                [weakSelf.navigationController pushViewController:vc animated:YES];
            }];
        }else {
            [HUD showWarningMessage:LanguageToolMatch(@"相册权限未开启，请在设置中选择当前应用，开启相册权限")];
        }
    }];
}

//选择文件
- (void)chatInputViewShowFile {
    //先检测权限，再进入，解决某些系统第一次不能获取相册，杀死进程后可以获取相册的问题
    WeakSelf
    [ZTOOL getPhotoLibraryAuth:^(BOOL granted) {
        if (granted) {
            [ZTOOL doInMain:^{
                NSString *fileFolderPath = [NSString getFileDiectoryWithCustomPath:[NSString stringWithFormat:@"%@-%@",UserManager.userInfo.userUID, weakSelf.sessionID]];
                NoaFilePickerVC *vc = [NoaFilePickerVC new];
                vc.sessionFoldPath = fileFolderPath;
                [weakSelf.navigationController pushViewController:vc animated:YES];
                //直接选择 手机储存的文件
                vc.savePhoneFileSuccess = ^(NoaFilePickModel *selectFileModel) {
                    //手机储存中的文件
                    [weakSelf recombineFileSendData:selectFileModel sendFileDataList:nil];
                };
                //选择的 App中的文件或者相册视频 数组里可以是 PHAsset或者本地文件沙盒路径
                vc.saveLingXinFileSuccess = ^(NSArray * _Nonnull sendSelectFileArr) {
                    //App中的文件或者相册视频
                    [weakSelf recombineFileSendData:nil sendFileDataList:sendSelectFileArr];
                };
            }];
        } else {
            [HUD showWarningMessage:LanguageToolMatch(@"相册权限未开启，请在设置中选择当前应用，开启相册权限")];
        }
    }];
}

//展示收藏列表
- (void)chatInputViewCollection {
    NoaMyCollectionViewController *myCollectionVC = [[NoaMyCollectionViewController alloc] init];
    myCollectionVC.isFromChat = YES;
    myCollectionVC.chatType = CIMChatType_SingleChat;
    myCollectionVC.chatSession = self.sessionID;
    [self.navigationController pushViewController:myCollectionVC animated:YES];
    WeakSelf
    [myCollectionVC setSendCollectionMsgBlock:^(NoaMyCollectionItemModel * _Nonnull collectionMessage) {
        if (collectionMessage) {
            [weakSelf sendCollectionUserForwardAction:collectionMessage];
        }
    }];
}

#pragma mark - ZImagePickerVCDelegate 选好图片视频后上传发送
- (void)imagePickerVCSelected {
    //发送图片、视频消息
    if (IMAGEPICKER.zSelectedAssets.count > 0) {
        /// 发送图片、视频消息
        //目录路径
        NSString *customPath = [NSString stringWithFormat:@"%@-%@", UserManager.userInfo.userUID, self.sessionID];
        WeakSelf
        [NoaMessageSendHander ZMessageMediaSend:IMAGEPICKER.zSelectedAssets withToUserId:self.sessionID withChatType:CIMChatType_SingleChat compelete:^(NSArray <NoaIMChatMessageModel *> * sendChatMsgArr) {
            
            NSMutableArray * taskArray = [NSMutableArray array];
            for (NoaIMChatMessageModel *beSendMessageModel in sendChatMsgArr) {
                //生成上传任务，开始上传
                if (beSendMessageModel.messageType == CIMChatMessageType_ImageMessage) {
                    //本地沙盒路径
                    NSString *localThumbImgPath = [NSString getPathWithImageName:beSendMessageModel.localthumbImgName CustomPath:customPath];
                    NSString *localImgPath = [NSString getPathWithImageName:beSendMessageModel.localImgName CustomPath:customPath];

                    //缩略图
                    NSData *thumbImgData = [NSData dataWithContentsOfFile:localThumbImgPath];
                    NoaFileUploadTask *thumbImgTask = [[NoaFileUploadTask alloc] initWithTaskId:[NSString stringWithFormat:@"%@_thumb", beSendMessageModel.msgID] filePath:localThumbImgPath originFilePath:localImgPath fileName:beSendMessageModel.localthumbImgName fileType:@"" isEncrypt:YES dataLength:thumbImgData.length uploadType:ZHttpUploadTypeImageThumbnail beSendMessage:beSendMessageModel delegate:self];
                    thumbImgTask.messageTaskType = FileUploadMessageTaskTypeThumbImage;
                    [taskArray addObject:thumbImgTask];

                    //图片
                    NoaFileUploadTask *imgTask = [[NoaFileUploadTask alloc] initWithTaskId:beSendMessageModel.msgID filePath:localImgPath originFilePath:@"" fileName:beSendMessageModel.localImgName fileType:@"" isEncrypt:YES dataLength:beSendMessageModel.imgSize uploadType:ZHttpUploadTypeImage beSendMessage:beSendMessageModel delegate:self];
                    imgTask.messageTaskType = FileUploadMessageTaskTypeImage;
                    [taskArray addObject:imgTask];
                }
                if (beSendMessageModel.messageType == CIMChatMessageType_VideoMessage) {
                    //视频-封面图
                    NSString *localCoverPath = [NSString getPathWithImageName:beSendMessageModel.localVideoCover CustomPath:customPath];
                    NoaFileUploadTask *coverTask = [[NoaFileUploadTask alloc] initWithTaskId:[NSString stringWithFormat:@"%@_cover", beSendMessageModel.msgID] filePath:localCoverPath originFilePath:@"" fileName:beSendMessageModel.localVideoCover fileType:@"" isEncrypt:YES dataLength:beSendMessageModel.videoCoverSize uploadType:ZHttpUploadTypeImage beSendMessage:beSendMessageModel delegate:self];
                    coverTask.messageTaskType = FileUploadMessageTaskTypeCover;
                    [taskArray addObject:coverTask];
                    //视频-视频
                    NSString *localVideoPath = [NSString getPathWithVideoName:beSendMessageModel.localVideoName CustomPath:customPath];
                    NoaFileUploadTask *videoTask = [[NoaFileUploadTask alloc] initWithTaskId:beSendMessageModel.msgID filePath:localVideoPath originFilePath:@"" fileName:beSendMessageModel.localVideoName fileType:@"" isEncrypt:YES dataLength:beSendMessageModel.videoSize uploadType:ZHttpUploadTypeVideo beSendMessage:beSendMessageModel delegate:self];
                    videoTask.messageTaskType = FileUploadMessageTaskTypeVideo;
                    [taskArray addObject:videoTask];
                }
                if (beSendMessageModel.messageType == CIMChatMessageType_FileMessage) {
                    //文件(大图以文件方式发送)
                    NSString *localFilePath = [NSString getPathWithFileName:beSendMessageModel.localVideoName CustomPath:customPath];
                    NoaFileUploadTask *fileTask = [[NoaFileUploadTask alloc] initWithTaskId:beSendMessageModel.msgID filePath:localFilePath originFilePath:@"" fileName:beSendMessageModel.fileName fileType:beSendMessageModel.fileType isEncrypt:YES dataLength:beSendMessageModel.fileSize uploadType:ZHttpUploadTypeFile beSendMessage:beSendMessageModel delegate:self];
                    fileTask.messageTaskType = FileUploadMessageTaskTypeFile;
                    [taskArray addObject:fileTask];
                }
            }
            NoaFileUploadGetSTSTask *getSTSTask = [[NoaFileUploadGetSTSTask alloc] init];
            getSTSTask.uploadTask = taskArray;
            
            NoaMessageSendTask *messageSendTask = [[NoaMessageSendTask alloc] init];
            messageSendTask.uploadTask = taskArray;
            for (NoaFileUploadTask * task in taskArray) {
                //所有上传任务在stsTask之后执行
                [[NoaFileUploadManager sharedInstance] addUploadTask:task];
            }
            [[NoaFileUploadManager sharedInstance].operationQueue addOperation:getSTSTask];
            [[NoaFileUploadManager sharedInstance].operationQueue addOperation:messageSendTask];
            
            [ZTOOL doInMain:^{
                [HUD hideHUD];
            }];
            for (NoaIMChatMessageModel *sendMessageModel in sendChatMsgArr) {
                //将配置好的消息添加到UI上展示
                [weakSelf chatListAppendMessage:sendMessageModel];
            }
            //将配置好的消息存储到数据库
            [IMSDKManager toolInsertOrUpdateChatMessagesWith:sendChatMsgArr];
        }];
        [IMAGEPICKER.zSelectedAssets removeAllObjects];
    }
}

#pragma mark - 发送文件类型消息时上传文件并组合消息体
- (void)recombineFileSendData:(NoaFilePickModel *)sendFileModel sendFileDataList:(NSArray <NoaFilePickModel *> *)sendFileDataList {
    [HUD showActivityMessage:LanguageToolMatch(@"处理中...")];
    WeakSelf
    if (sendFileDataList == nil) {
        //手机中存储的文件(每次只发1个文件)
        [NoaMessageSendHander ZMessageFileSendData:sendFileModel withToUserId:self.sessionID withChatType:CIMChatType_SingleChat compelete:^(NoaIMChatMessageModel * _Nonnull sendChatMsg) {
            //目录
            NSString *customPath = [NSString stringWithFormat:@"%@-%@", UserManager.userInfo.userUID, self.sessionID];
            NSString *localFilePath = [NSString getPathWithFileName:sendChatMsg.fileName CustomPath:customPath];
            //上传文件
            NoaFileUploadTask *fileTask = [[NoaFileUploadTask alloc] initWithTaskId:sendChatMsg.msgID filePath:localFilePath originFilePath:@"" fileName:sendChatMsg.fileName fileType:sendChatMsg.fileType isEncrypt:YES dataLength:sendChatMsg.fileSize uploadType:ZHttpUploadTypeFile beSendMessage:sendChatMsg delegate:self];
            fileTask.messageTaskType = FileUploadMessageTaskTypeFile;
            
            NSBlockOperation * blockOperation = [NSBlockOperation blockOperationWithBlock:^{
                NSLog(@"文件上传任务完成");
                if (fileTask.status == FileUploadTaskStatus_Completed) {
                    sendChatMsg.filePath = fileTask.originUrl;
                    [IMSDKManager toolSendChatMessageWith:sendChatMsg];
                }
                if (fileTask.status == FileUploadTaskStatus_Failed) {
                    [ZTOOL doInMain:^{
                        [HUD showMessage:LanguageToolMatch(@"上传失败")];
                    }];
                }
            }];
            NoaFileUploadGetSTSTask *getSTSTask = [[NoaFileUploadGetSTSTask alloc] init];
            [fileTask addDependency:getSTSTask];
            [blockOperation addDependency:fileTask];
            [[NoaFileUploadManager sharedInstance].operationQueue addOperation:getSTSTask];
            [[NoaFileUploadManager sharedInstance] addUploadTask:fileTask];
            [[NoaFileUploadManager sharedInstance].operationQueue addOperation:blockOperation];
            
            [ZTOOL doInMain:^{
                [HUD hideHUD];
            }];
            //将配置好的消息 1.存储到数据库 2.添加到UI上展示
            [IMSDKManager toolInsertOrUpdateChatMessageWith:sendChatMsg];
            [weakSelf chatListAppendMessage:sendChatMsg];
        }];
    } else {
        //相册/App中的文件(每次可能是多个文件)
        __block NSMutableArray *taskArray = [NSMutableArray array];
        __block NSMutableArray *sengMessageArr = [NSMutableArray array];
        dispatch_group_t myGroup = dispatch_group_create();
        for (NoaFilePickModel *filePickModel in sendFileDataList) {
            dispatch_group_enter(myGroup);
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [NoaMessageSendHander ZMessageFileSendData:filePickModel withToUserId:self.sessionID withChatType:CIMChatType_SingleChat compelete:^(NoaIMChatMessageModel * _Nonnull sendChatMsg) {
                    //目录
                    NSString *customPath = [NSString stringWithFormat:@"%@-%@", UserManager.userInfo.userUID, self.sessionID];
                    NSString *localFilePath = [NSString getPathWithFileName:sendChatMsg.fileName CustomPath:customPath];
                    //上传文件
                    NoaFileUploadTask *fileTask = [[NoaFileUploadTask alloc] initWithTaskId:sendChatMsg.msgID filePath:localFilePath originFilePath:@"" fileName:sendChatMsg.fileName fileType:sendChatMsg.fileType isEncrypt:YES dataLength:sendChatMsg.fileSize uploadType:ZHttpUploadTypeFile beSendMessage:sendChatMsg delegate:self];
                    fileTask.messageTaskType = FileUploadMessageTaskTypeFile;
                    [taskArray addObject:fileTask];
                    [sengMessageArr addObject:sendChatMsg];
                    dispatch_group_leave(myGroup);
                }];
            });
        }
    
        dispatch_group_notify(myGroup, dispatch_get_main_queue(), ^{
            NoaFileUploadGetSTSTask *getSTSTask = [[NoaFileUploadGetSTSTask alloc] init];
            getSTSTask.uploadTask = taskArray;
            
            NoaMessageSendTask *messageSendTask = [[NoaMessageSendTask alloc] init];
            messageSendTask.uploadTask = taskArray;
            
            [[NoaFileUploadManager sharedInstance].operationQueue addOperation:getSTSTask];
            for (NoaFileUploadTask * task in taskArray) {
                [[NoaFileUploadManager sharedInstance] addUploadTask:task];
            }
            [[NoaFileUploadManager sharedInstance].operationQueue addOperation:messageSendTask];
            
            [ZTOOL doInMain:^{
                [HUD hideHUD];
            }];
            for (NoaIMChatMessageModel *sendMessageModel in sengMessageArr) {
                //将配置好的消息添加到UI上展示
                [weakSelf chatListAppendMessage:sendMessageModel];
            }
            
            //将配置好的消息存储到数据库
            [IMSDKManager toolInsertOrUpdateChatMessagesWith:sengMessageArr];
        });
    }
}

#pragma mark - 发送位置信息类型的消息
- (void)sendGeoLocationMessageWithLat:(NSString *)lat lng:(NSString *)lng name:(NSString *)name cImg:(UIImage *)cImg detail:(NSString *)detail {
    WeakSelf
    [NoaMessageSendHander ZMessageLocationSendWithLng:lng lat:lat name:name cImg:cImg detail:detail withToUserId:self.sessionID withChatType:CIMChatType_SingleChat compelete:^(NoaIMChatMessageModel * _Nonnull sendChatMsg) {
        //地理位置地图截图
        NSString *customPath = [NSString stringWithFormat:@"%@-%@", UserManager.userInfo.userUID, weakSelf.sessionID];
        NSString *geoImgPath = [NSString getPathWithImageName:sendChatMsg.localGeoImgName CustomPath:customPath];
        NSData *geoImgData = [NSData dataWithContentsOfFile:geoImgPath options:NSDataReadingMappedIfSafe error:nil];
        NoaFileUploadTask *geoImgTask = [[NoaFileUploadTask alloc] initWithTaskId:sendChatMsg.msgID filePath:geoImgPath originFilePath:@"" fileName:sendChatMsg.localGeoImgName fileType:@"" isEncrypt:YES dataLength:geoImgData.length uploadType:ZHttpUploadTypeImage beSendMessage:sendChatMsg delegate:self];
        geoImgTask.messageTaskType = FileUploadMessageTaskTypeImage;
        
        NSBlockOperation * blockOperation = [NSBlockOperation blockOperationWithBlock:^{
            NSLog(@"地理位置图片上传任务完成");
            if (geoImgTask.status == FileUploadTaskStatus_Completed) {
                sendChatMsg.geoImg = geoImgTask.originUrl;
                [IMSDKManager toolSendChatMessageWith:sendChatMsg];
            }
            if (geoImgTask.status == FileUploadTaskStatus_Failed) {
                [ZTOOL doInMain:^{
                    [HUD showMessage:LanguageToolMatch(@"上传失败")];
                }];
            }
        }];
        NoaFileUploadGetSTSTask *getSTSTask = [[NoaFileUploadGetSTSTask alloc] init];
        [geoImgTask addDependency:getSTSTask];
        [blockOperation addDependency:geoImgTask];
        [[NoaFileUploadManager sharedInstance].operationQueue addOperation:getSTSTask];
        [[NoaFileUploadManager sharedInstance] addUploadTask:geoImgTask];
        [[NoaFileUploadManager sharedInstance].operationQueue addOperation:blockOperation];

        //将消息添加到UI上
        [IMSDKManager toolInsertOrUpdateChatMessageWith:sendChatMsg];
        [weakSelf chatListAppendMessage:sendChatMsg];
    }];
}

#pragma mark - 收藏列表消息 点击 发送到当前聊天
- (void)sendCollectionUserForwardAction:(NoaMyCollectionItemModel *)collectionMsg {
    self.collectionSendHander.fromSessionId = self.sessionID;
    [self.collectionSendHander chatCollectionMessagSendWith:collectionMsg chatType:CIMChatType_SingleChat sessionId:self.sessionID];
    WeakSelf
    [self.collectionSendHander setCollectionSendCompleteBlock:^(BOOL isSuccess, NoaIMChatMessageModel * _Nullable sendCollectionMsg) {
        if (isSuccess) {
            [HUD showMessage:LanguageToolMatch(@"已发送")];
        } else {
            [HUD showMessage:LanguageToolMatch(@"操作失败")];
        }
        sendCollectionMsg.localImgName = nil;
        sendCollectionMsg.localVideoName = nil;
        sendCollectionMsg.localVoiceName = nil;
        sendCollectionMsg.localVideoCover = nil;
        sendCollectionMsg.localGeoImgName = nil;
        //转发消息是转发给当前聊天对象
        if ([weakSelf.sessionID isEqualToString:sendCollectionMsg.toID]) {
            //刷新并滚动到底部
            [ZTOOL doInMain:^{
                NoaMessageModel *sendMsg = [[NoaMessageModel alloc] initWithMessageModel:sendCollectionMsg];
                [weakSelf.messageModels addObject:sendMsg];
                //处理消息是否显示时间
                [weakSelf computeVisibleTime];
                [weakSelf.baseTableView reloadData];
                //加载滚动到底部
                [weakSelf tableViewScrollToBottom:NO duration:0.25];
            }];
        }
    }];
}

#pragma mark - 展示输入框表情手势-表情商店
- (void)chatInputViewSearchMoreEmojiAction {
    NoaEmojiShopViewController *vc = [[NoaEmojiShopViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - 发送 收藏的表情、表情包表情、搜索到的表情
- (void)chatInputViewStickersSend:(NoaIMStickersModel *)sendStickersModel {
    NoaIMChatMessageModel *stickersMessageModel = [NoaMessageSendHander ZMessageStickersSendContentUrl:sendStickersModel.contentUrl stickerThumbImgUrl:sendStickersModel.thumbUrl stickerId:sendStickersModel.stickersKey stickerName:sendStickersModel.name stickerHeight:sendStickersModel.height stickerWidth:sendStickersModel.width stickerSize:sendStickersModel.size isStickersSet:sendStickersModel.isStickersSet stickerExt:@"" withToUserId:self.sessionID withChatType:CIMChatType_SingleChat];
    
    //发送的表情消息
    [self chatListAppendMessage:stickersMessageModel];
    [IMSDKManager toolInsertOrUpdateChatMessageWith:stickersMessageModel];
    [IMSDKManager toolSendChatMessageWith:stickersMessageModel];
}

#pragma mark - 打开相册-向收藏表情里添加表情
- (void)chatInputViewOpenAlumAddCollectGifImg {
    //先检测权限，再进入相册，解决某些系统第一次不能获取照片，杀死进程后可以获取照片的问题
    WeakSelf
    [ZTOOL getPhotoLibraryAuth:^(BOOL granted) {
        if (granted) {
            [ZTOOL doInMain:^{
                NoaImagePickerVC *vc = [NoaImagePickerVC new];
                vc.isSignlePhoto = YES;
                vc.isNeedEdit = NO;
                vc.hasCamera = YES;
                vc.delegate = self;
                [vc setPickerType:ZImagePickerTypeImage];
                [weakSelf.navigationController pushViewController:vc animated:YES];
            }];
        }else {
            [HUD showWarningMessage:LanguageToolMatch(@"相册权限未开启，请在设置中选择当前应用，开启相册权限")];
        }
    }];
}

#pragma mark - 发送收藏表情里游戏表情：石头剪刀布、摇骰子
- (void)chatInputViewPlayGameStickerAction:(ZChatGameStickerType)gameType {
    NSString *resultContent;
    ZChatGameStickerType gameStickersType = ZChatGameStickerTypeFingerGuessing;
    if (gameType == ZChatGameStickerTypeFingerGuessing) {
        //石头剪刀布
        resultContent = [NSString randomNumWithMin:1 max:3];
        gameStickersType = ZChatGameStickerTypeFingerGuessing;
    }
    if (gameType == ZChatGameStickerTypePlayDice) {
        //摇骰子
        resultContent = [NSString randomNumWithMin:1 max:6];
        gameStickersType = ZChatGameStickerTypePlayDice;
    }
    
    //生成消息体
    NoaIMChatMessageModel *gameStickersMessageModel = [NoaMessageSendHander ZMessageGameStickersSendResultContent:resultContent gameStickersType:gameStickersType gameStickerExt:@"" withToUserId:self.sessionID withChatType:CIMChatType_SingleChat];
    //发送游戏表情消息
    [IMSDKManager toolSendChatMessageWith:gameStickersMessageModel];
    //添加到UI上
    [self chatListAppendMessage:gameStickersMessageModel];
}

#pragma mark - ZImagePickerVCDelegate
- (void)imagePickerClipImage:(UIImage *)resultImg localIdenti:(NSString *)localIdenti {
    //添加图片到收藏表情
    NSData *stickerData = UIImageJPEGRepresentation(resultImg, 0.5);
    //添加表情需要的参数
    long long stickersSize = CGImageGetHeight(resultImg.CGImage) * CGImageGetBytesPerRow(resultImg.CGImage);
    float stickersWidth = resultImg.size.width;
    float stickersHeight = resultImg.size.height;
    NSString *stickersKey = [[NSString stringWithFormat:@"%@%lld", localIdenti, stickersSize] MD5Encryption];
    //fileName 文件名为：userid+当前时间戳
    NSString *fileName = [[NSString alloc] initWithFormat:@"%@_%lld.%@", UserManager.userInfo.userUID, [NSDate currentTimeIntervalWithMillisecond], [NSString getImageFileFormat:stickerData]];
    //本地沙盒完整路径
    NSString *customPath = [NSString stringWithFormat:@"%@-%@", UserManager.userInfo.userUID, self.sessionID];
    [NSString saveImageToSaxboxWithData:stickerData CustomPath:customPath ImgName:fileName];
    NSString *stickerPath = [NSString getPathWithImageName:fileName CustomPath:customPath];
 
    NSMutableArray * taskArray = [NSMutableArray array];
    
    //上传缩略图
    NSData *thumbnailImgData = [UIImage compressImageSize:[UIImage imageWithData:stickerData] toByte:50*1024];
    NSString *thumbnailFileName = [NSString stringWithFormat:@"thumbnail_%@",fileName];
    [NSString saveImageToSaxboxWithData:thumbnailImgData CustomPath:customPath ImgName:thumbnailFileName];
    NSString *stickerThumbPath = [NSString getPathWithImageName:thumbnailFileName CustomPath:customPath];
    NoaFileUploadTask *stickerThumbTask = [[NoaFileUploadTask alloc] initWithTaskId:thumbnailFileName filePath:stickerThumbPath originFilePath:@"" fileName:thumbnailFileName fileType:@"" isEncrypt:YES dataLength:thumbnailImgData.length uploadType:ZHttpUploadTypeStickers beSendMessage:nil delegate:self];
    stickerThumbTask.messageTaskType = FileUploadMessageTaskTypeStickerThumb;
    [taskArray addObject:stickerThumbTask];
    //上传原图
    NoaFileUploadTask *stickerTask = [[NoaFileUploadTask alloc] initWithTaskId:fileName filePath:stickerPath originFilePath:@"" fileName:fileName fileType:@"" isEncrypt:YES dataLength:stickerData.length uploadType:ZHttpUploadTypeStickers beSendMessage:nil delegate:self];
    stickerTask.messageTaskType = FileUploadMessageTaskTypeSticker;
    [taskArray addObject:stickerTask];
    
    //组装接口数据
    NSMutableDictionary *stickersDic = [NSMutableDictionary dictionary];
    [stickersDic setObjectSafe:@(stickersHeight) forKey:@"height"];
    [stickersDic setObjectSafe:@(stickersSize) forKey:@"size"];
    [stickersDic setObjectSafe:stickersKey forKey:@"stickersKey"];
    [stickersDic setObjectSafe:UserManager.userInfo.userUID forKey:@"userUid"];
    [stickersDic setObjectSafe:@(stickersWidth) forKey:@"width"];
    
    WeakSelf
    __block NSInteger taskNum = 0;
    NSBlockOperation * blockOperation = [NSBlockOperation blockOperationWithBlock:^{
        //上传表情图片完成
        for (NoaFileUploadTask *task in taskArray) {
            if (task.status == FileUploadTaskStatus_Completed) {
                if (task.messageTaskType == FileUploadMessageTaskTypeStickerThumb) {
                    [stickersDic setObjectSafe:task.originUrl forKey:@"thumbUrl"];//缩略图地址
                    taskNum++;
                }
                if (task.messageTaskType == FileUploadMessageTaskTypeSticker) {
                    [stickersDic setObjectSafe:task.originUrl forKey:@"contentUrl"];//原图地址
                    taskNum++;
                }
                if (taskNum == 2) {
                    //调用接口
                    [weakSelf requestAddStickersToCollectionWithDic:stickersDic isReloadCollection:NO];
                }
            } else {
                [ZTOOL doInMain:^{
                    [HUD showMessage:LanguageToolMatch(@"上传失败")];
                }];
            }
        }
    }];
    NoaFileUploadGetSTSTask *getSTSTask = [[NoaFileUploadGetSTSTask alloc] init];
    getSTSTask.uploadTask = taskArray;
    [[NoaFileUploadManager sharedInstance].operationQueue addOperation:getSTSTask];
    for (NoaFileUploadTask *task in taskArray) {
        [[NoaFileUploadManager sharedInstance] addUploadTask:task];
        [blockOperation addDependency:task];
    }
    [[NoaFileUploadManager sharedInstance].operationQueue addOperation:blockOperation];
    [IMAGEPICKER.zSelectedAssets removeAllObjects];
}


#pragma mark - 合并转发(将选择的消息进行数据转换成合并转发需要的IMChatMessage)
- (void)sendChatRecordMessage {
    //选择 消息记录 接收者
    NoaChatMultiSelectViewController *vc = [NoaChatMultiSelectViewController new];
    vc.multiSelectType = ZMultiSelectTypeMergeForward;
    vc.mergeMsgCount = self.selectedMsgModels.count;
    [self.navigationController pushViewController:vc animated:YES];
    WeakSelf
    vc.messageRecordReceverListBlock = ^(NSArray * _Nonnull selectedReceverInfoArr) {
        //文件助手合并转发
       NSString *recordTitle  = [NSString stringWithFormat:LanguageToolMatch(@"%@的会话记录"), UserManager.userInfo.nickname];
        //根据消息时间进行升序排列
        NSArray *sortResultArr = [NSMutableArray sortMultiSelectedMessageArr:weakSelf.selectedMsgModels.safeArray];
        WeakSelf
        [NoaMessageSendHander ZMessageMergeForwardSendWith:sortResultArr withTitle:recordTitle withToUserInfoArr:selectedReceverInfoArr compelete:^(NSArray <NoaIMChatMessageModel *> *sendChatMsgList) {
            //发送消息
            for (NoaIMChatMessageModel *sendChatMsg in sendChatMsgList) {
                [IMSDKManager toolSendChatMessageWith:sendChatMsg];
                if ([sendChatMsg.toID isEqualToString:self.sessionID]) {
                    //添加到UI上(如果转发给当前聊天)
                    [weakSelf chatListAppendMessage:sendChatMsg];
                }
            }
        }];
        [weakSelf setupMultiSelectedStatusDefaultIsReload:YES];
    };
}

#pragma mark - ZFileUploadTaskDelegate
//任务状态改变回调
-(void)fileUploadTask:(NoaFileUploadTask *)task didChangTaskStatus:(FileUploadTaskStatus)status error:(NSError *)error {}

//任务上传进度回调
-(void)fileUploadTask:(NoaFileUploadTask *)task didChangTaskProgress:(float)progress {}

//任务暂停
-(void)fileUploadTaskDidPause:(NoaFileUploadTask *)task {}

//任务继续
-(void)fileUploadTaskDidResume:(NoaFileUploadTask *)task {}

//重新上传
-(void)fileUploadTaskDidReupload:(NoaFileUploadTask *)task {}

#pragma mark - 接收到的消息 进行 消息列表 追加消息
- (void)chatListAppendMessage:(NoaIMChatMessageModel *)newMessage {
    if (newMessage != nil) {
        
        //删除 双向删除的消息(双向删除的消息 不存储，不展示)
        if (newMessage.messageType == CIMChatMessageType_BilateralDel) {
            [self updateDeleteMessageAndRefreshMsgWithOriginalMsg:newMessage.backDelServiceMsgID];
            return;
        }
        
        //删除 要撤回的消息
        if (newMessage.messageType == CIMChatMessageType_BackMessage) {
            [self updateDeleteMessageAndRefreshMsgWithOriginalMsg:newMessage.backDelServiceMsgID];
        }
        
        //追加消息
        NoaMessageModel *newMsgModel = [[NoaMessageModel alloc] initWithMessageModel:newMessage];
        [self.messageModels addObject:newMsgModel];
        
        //处理消息是否显示时间
        [self computeOneMessageVisibleTimeWithMessage:newMsgModel currentIndex:self.messageModels.count - 1];
        
        WeakSelf
        [ZTOOL doInMain:^{
            [weakSelf.baseTableView reloadData];
            //加载滚动到底部
            [weakSelf tableViewScrollToBottom:YES duration:0.25];
        }];
        
    }
}

#pragma mark - tableView滚动到底部
- (void)tableViewScrollToBottom:(BOOL)animated duration:(CGFloat)duration {
    if (self.messageModels.count > 0) {
        if (_btnBottom.hidden == NO) {
            return;
        }
        if (self.baseTableView.dragging || self.baseTableView.decelerating || self.baseTableView.tracking || self.baseTableView.editing) {
            //如果用户一直在操作界面,那么就滑动到最底部
            return ;
        }
        
        if([self.baseTableView numberOfRowsInSection:0] == 0){
            return;
        }
        //防止越界崩溃
        //当前总行数下标
        NSInteger totalRowIndex = [self.baseTableView numberOfRowsInSection:0] - 1;
        //需要滚动到的行数下标
        NSInteger scrollToRowIndex = self.messageModels.count - 1;
        NSIndexPath *indexpath;
        if (scrollToRowIndex > totalRowIndex) {
            indexpath = [NSIndexPath indexPathForRow:totalRowIndex inSection:0];
        } else {
            indexpath = [NSIndexPath indexPathForRow:scrollToRowIndex inSection:0];
        }
        
        @try {
            //加载滚动到底部
            if (animated) {
                [UIView animateWithDuration:duration animations:^{
                    [self.baseTableView scrollToRowAtIndexPath:indexpath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
                }];
            } else {
                [self.baseTableView scrollToRowAtIndexPath:indexpath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
            }
        } @catch (NSException *exception) {
            NSLog(@"%@",exception);
        } @finally {
            
        }
    };
}

#pragma mark - <<<<<<CIMToolMessageDelegate 消息代理>>>>>>
//接收到消息
- (void)cimToolChatMessageReceive:(NoaIMChatMessageModel *)message {
    
    /* 判断该条消息是否是当前聊天会话的消息 */
    if (([message.fromID isEqualToString:self.sessionID] && [message.toID isEqualToString:UserManager.userInfo.userUID]) || ([message.fromID isEqualToString:UserManager.userInfo.userUID] && [message.toID isEqualToString:self.sessionID])) {
        [self chatListAppendMessage:message];
    } else {
        DLog(@"收到的消息，不属于当前会话");
    }

}

//消息发送成功
- (void)cimToolChatMessageSendSuccess:(IMChatMessageACK *)messageACK {
    DLog(@"消息发送成功：%@--服务端生成ID:%@",messageACK.ackMsgId,messageACK.sMsgId);
    WeakSelf
    dispatch_async(_chatMessageUpdateQueue, ^{
        [ZTOOL doAsync:^{
            //更新本地数据
            for (int i= 0; i < weakSelf.messageModels.count; i++) {
                NoaMessageModel *msgModel = [weakSelf.messageModels objectAtIndex:i];
                if ([msgModel.message.msgID isEqualToString:messageACK.ackMsgId]) {
                    msgModel.message.messageSendType = CIMChatMessageSendTypeSuccess;
                    msgModel.message.serviceMsgID = messageACK.sMsgId;
                    msgModel.message.sendTime = messageACK.sendTime;
                    [weakSelf.messageModels replaceObjectAtIndex:i withObject:msgModel];
                    break;
                }
            }
        } completion:^{
            [ZTOOL doInMain:^{
                //更新UI
                [weakSelf.baseTableView reloadData];
            }];
        }];
    });
}

//消息发送失败
- (void)cimToolChatMessageSendFail:(NSString *)messageID {
    DLog(@"消息发送失败：%@",messageID);
    WeakSelf
    dispatch_async(_chatMessageUpdateQueue, ^{
        
        //更新本地数据
        for (int i=0; i<weakSelf.messageModels.count; i++) {
            
            NoaMessageModel *msgModel = [weakSelf.messageModels objectAtIndex:i];
            
            if ([msgModel.message.msgID isEqualToString:messageID]) {
                //更新本地数据
                msgModel.message.messageSendType = CIMChatMessageSendTypeFail;
                [weakSelf.messageModels replaceObjectAtIndex:i withObject:msgModel];
                
                //更新UI，局部刷新
                [ZTOOL doInMain:^{
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
                    [weakSelf.baseTableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath, nil] withRowAnimation:UITableViewRowAnimationNone];
                }];
            }
        }
        
    });
}

//消息清空
- (void)cimToolMessageDeleteAll:(NSString *)sessionID {
    if ([sessionID isEqualToString:self.sessionID]) {
        //当前回话的 消息清空
        DLog(@"当前会话的消息清空了");
        WeakSelf
        dispatch_async(_chatMessageUpdateQueue, ^{
            weakSelf.pageNumber = 1;
            [weakSelf.messageModels removeAllObjects];
            [ZTOOL doInMain:^{
                [weakSelf.baseTableView reloadData];
            }];
        });
    }
}

//消息状态更新
- (void)cimToolChatMessageUpdate:(NoaIMChatMessageModel *)message {
    WeakSelf
    
    dispatch_async(_chatMessageUpdateQueue, ^{
        
        for (int i = 0; i < weakSelf.messageModels.count; i++) {
            
            NoaMessageModel *msgModel = [weakSelf.messageModels objectAtIndex:i];
            
            if ([msgModel.message.serviceMsgID isEqualToString:message.serviceMsgID]) {
                msgModel.message = message;
                [weakSelf.messageModels replaceObjectAtIndex:i withObject:msgModel];
                [ZTOOL doInMain:^{
                    [weakSelf.baseTableView reloadData];
                }];
            }
            
        }
        
    });
}

//消息同步完成
- (void)imSdkChatMessageForSessionSyncFinish:(NSString *)sessionID {
    if ([self.sessionID isEqualToString:sessionID]) {
        //加载消息记录，已经优化为，自动加载出最新的消息了，所以此处可以不用处理了
    }
}

#pragma mark - <<<<<<UITableViewDelegate UITableViewDataSource UIScrollViewDelegate>>>>>>
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messageModels.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NoaMessageModel *model = [self.messageModels objectAtIndex:indexPath.row];
    return model.cellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.messageModels.count) {
        
        NoaMessageBaseCell *cell = [NoaMessageBaseCell new];
        NoaMessageModel *model = [self.messageModels objectAtIndex:indexPath.row];
        model.isShowSelectBox = self.multiSelectStatus;
        //cell
        switch (model.message.messageType) {
            case CIMChatMessageType_TextMessage:    //文本消息
            {
                //文本消息
                if (![NSString isNil:model.message.referenceMsgId]) {
                    //引用类文本消息
                    cell = [tableView dequeueReusableCellWithIdentifier:@"referenceTextCell"];
                    if (cell == nil) {
                        cell = [[NoaMessageReferenceCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"referenceTextCell"];
                    }
                } else {
                    //纯文本消息
                    cell = [tableView dequeueReusableCellWithIdentifier:@"textCell"];
                    if (cell == nil) {
                        cell = [[NoaMessageTextCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"textCell"];
                    }
                }
                cell.delegate = self;
                cell.sessionId = self.sessionID;
                [cell setConfigMessage:model];
            }
                break;
            case CIMChatMessageType_StickersMessage:   //表情消息
            {
                //表情消息
                cell = [tableView dequeueReusableCellWithIdentifier:@"stickerCell"];
                if (cell == nil) {
                    cell = [[NoaMessageStickersCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"stickerCell"];
                }
                cell.delegate = self;
                cell.sessionId = self.sessionID;
                [cell setConfigMessage:model];
            }
                break;
            case CIMChatMessageType_ImageMessage:   //图片消息
            {
                //图片消息
                cell = [tableView dequeueReusableCellWithIdentifier:@"imageCell"];
                if (cell == nil) {
                    cell = [[NoaMessageImageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"imageCell"];
                }
                cell.delegate = self;
                cell.sessionId = self.sessionID;
                [cell setConfigMessage:model];
            }
                break;
            case CIMChatMessageType_VideoMessage:   //视频消息
            {
                //视频消息
                cell = [tableView dequeueReusableCellWithIdentifier:@"videoCell"];
                if (cell == nil) {
                    cell = [[NoaMessageVideoCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"videoCell"];
                }
                cell.delegate = self;
                cell.sessionId = self.sessionID;
                [cell setConfigMessage:model];
            }
                break;
            case CIMChatMessageType_AtMessage:   //At消息
            {
                if (![NSString isNil:model.message.referenceMsgId]) {
                    //引用消息 + At
                    cell = [tableView dequeueReusableCellWithIdentifier:@"referenceTextCell"];
                    if (cell == nil) {
                        cell = [[NoaMessageReferenceCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"referenceTextCell"];
                    }
                } else {
                    //At消息
                    cell = [tableView dequeueReusableCellWithIdentifier:@"AtUsetCell"];
                    if (cell == nil) {
                        cell = [[NoaMessageAtUserCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"AtUsetCell"];
                    }
                }
                cell.delegate = self;
                cell.sessionId = self.sessionID;
                [cell setConfigMessage:model];
            }
                break;
            case CIMChatMessageType_FileMessage:   //文件消息
            {
                //文件消息
                NoaMessageFileCell *fileCell = [tableView dequeueReusableCellWithIdentifier:[NoaMessageFileCell cellIdentifier]];
                if (fileCell == nil) {
                    fileCell = [[NoaMessageFileCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:[NoaMessageFileCell cellIdentifier]];
                }
                fileCell.delegate = self;
                fileCell.sessionId = self.sessionID;
                [fileCell setConfigMessage:model];
                cell = fileCell;
            }
                break;
            case CIMChatMessageType_VoiceMessage:   //音频消息
            {
                //音频消息
                cell = [tableView dequeueReusableCellWithIdentifier:@"voiceCell"];
                if (cell == nil) {
                    cell = [[NoaMessageVoiceCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"voiceCell"];
                }
                cell.delegate = self;
                cell.sessionId = self.sessionID;
                [cell setConfigMessage:model];
            }
                break;
            case CIMChatMessageType_CardMessage:    //名片消息
            {
                //名片消息
                cell = [tableView dequeueReusableCellWithIdentifier:@"nameCardCell"];
                if (cell == nil) {
                    cell = [[NoaMessageCardCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"nameCardCell"];
                }
                cell.delegate = self;
                cell.sessionId = self.sessionID;
                [cell setConfigMessage:model];
            }
                break;
            case CIMChatMessageType_GeoMessage:    //地理位置消息
            {
                //地理位置消息
                cell = [tableView dequeueReusableCellWithIdentifier:@"geoLocationCell"];
                if (cell == nil) {
                    cell = [[NoaMessageGeoCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"geoLocationCell"];
                }
                cell.delegate = self;
                cell.sessionId = self.sessionID;
                [cell setConfigMessage:model];
            }
                break;
            case CIMChatMessageType_GroupNotice:   //群公告消息
            {
                cell = [tableView dequeueReusableCellWithIdentifier:@"groupNoticeCell"];
                if (!cell) {
                    cell = [[NoaMessageGroupNoticeCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"groupNoticeCell"];
                }
                cell.delegate = self;
                cell.sessionId = self.sessionID;
                [cell setConfigMessage:model];
            }
                break;
            case CIMChatMessageType_ForwardMessage:    //合并转发的消息记录
            {
                //合并转发的消息记录
                cell = [tableView dequeueReusableCellWithIdentifier:@"NoaMergeMessageRecordCell"];
                if (cell == nil) {
                    cell = [[NoaMergeMessageRecordCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NoaMergeMessageRecordCell"];
                }
                cell.delegate = self;
                cell.sessionId = self.sessionID;
                [cell setConfigMessage:model];
            }
                break;
            case CIMChatMessageType_NetCallMessage://即构 音视频通话
            {
                //音视频通话操作提示消息
                cell = [tableView dequeueReusableCellWithIdentifier:@"mediaCallCell"];
                if (cell == nil) {
                    cell = [[NoaMessageCallCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"mediaCallCell"];
                }
                cell.delegate = self;
                cell.sessionId = self.sessionID;
                [cell setConfigMessage:model];
            }
                break;
            case CIMChatMessageType_GameStickersMessage:   //游戏表情消息
            {
                //游戏消息
                cell = [tableView dequeueReusableCellWithIdentifier:@"gameStickerCell"];
                if (cell == nil) {
                    cell = [[NoaMessageGameStickersCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"gameStickerCell"];
                }
                cell.delegate = self;
                cell.sessionId = self.sessionID;
                [cell setConfigMessage:model];
            }
                break;
            case CIMChatMessageType_BackMessage:    //撤回提示消息
            case CIMChatMessageType_ServerMessage:  //系统通知类消息
            {
                //音视频通话操作提示消息
               IMServerMessage *serverMessage = model.message.serverMessage;
               CustomEvent *customEvent = serverMessage.customEvent;
               if (customEvent.type == 101 || customEvent.type == 103) {
                    //音视频通话操作提示消息
                    cell = [tableView dequeueReusableCellWithIdentifier:@"mediaCallCell"];
                    if (cell == nil) {
                        cell = [[NoaMessageCallCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"mediaCallCell"];
                    }
                    cell.delegate = self;
                    cell.sessionId = self.sessionID;
                    [cell setConfigMessage:model];
                    break;
                }
                
                //其他系统通知类型消息展示
                cell = [tableView dequeueReusableCellWithIdentifier:@"systemTipsCell"];
                if (cell == nil) {
                    cell = [[NoaMessageSystemCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"systemTipsCell"];
                }
                cell.delegate = self;
                cell.sessionId = self.sessionID;
                [cell setConfigMessage:model];
            }
                break;
            default:
                break;
        }
        cell.cellIndex = indexPath;
        [cell showSendMessageReadProgressView:NO];
        return cell;
    } else {
        return [UITableViewCell new];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    CGFloat height = scrollView.frame.size.height;
    CGFloat contentOffsetY = scrollView.contentOffset.y;
    CGFloat bottomOffset = scrollView.contentSize.height - contentOffsetY;
    if (bottomOffset <= (height + DWScale(100))) {
        //在最底部
        _btnBottom.hidden = YES;
    } else {
        _btnBottom.hidden = NO;
    }

}

#pragma mark - <<<<<<ZMessageBaseCellDelegate 消息Cell交互代理>>>>>>
//点击用户头像
- (void)userAvatarClick:(NSString *)userId role:(NSInteger)role {
    //多选状态不能跳转
    if (self.multiSelectStatus) return;
    //机器人
    if (role == 3) return;
    
    //文件助手，属于单聊
    NoaUserHomePageVC *vc = [NoaUserHomePageVC new];
    vc.userUID = userId;
    vc.groupID = @"";
    [self.navigationController pushViewController:vc animated:YES];
}

//图片或视频的浏览
- (void)messageCellBrowserImageAndVideo:(NoaIMChatMessageModel *)messageModel {
    if (self.multiSelectStatus) {
        return;
    }
    [self.viewInput inputViewResignFirstResponder];
    [self imageVideoBrowserWith:messageModel];
}

//长按消息 菜单弹窗
- (void)messageCellLongTapWithIndex:(NSIndexPath *)cellIndex {
    
    if (self.multiSelectStatus) {
        //多选时，不可长按
        return;
    }
    
    NoaMessageBaseCell *longTapCell = [self.baseTableView cellForRowAtIndexPath:cellIndex];
    
    NoaMessageModel *longTapModel = [self.messageModels objectAtIndex:cellIndex.row];
    
    //配置弹窗里的菜单选项
    NSMutableArray *menuArr = [NSMutableArray array];
    
    if (longTapModel.message.messageSendType == CIMChatMessageSendTypeFail || longTapModel.message.messageSendType == CIMChatMessageSendTypeSending) {
        
        //发送失败或者发送中的消息，只能存在”复制或者删除“操作
        if (longTapModel.message.messageType == CIMChatMessageType_TextMessage || longTapModel.message.messageType == CIMChatMessageType_AtMessage) {
            //文字消息、 @消息（复制、删除）
            [menuArr addObjectsFromArray:@[[NSNumber numberWithInteger:MessageMenuItemActionTypeCopy],
                        [NSNumber numberWithInteger:MessageMenuItemActionTypeDelete]]];
        } else if (longTapModel.message.messageType == CIMChatMessageType_ImageMessage || longTapModel.message.messageType == CIMChatMessageType_VideoMessage || longTapModel.message.messageType == CIMChatMessageType_VoiceMessage || longTapModel.message.messageType == CIMChatMessageType_FileMessage || longTapModel.message.messageType == CIMChatMessageType_CardMessage || longTapModel.message.messageType == CIMChatMessageType_GeoMessage || longTapModel.message.messageType == CIMChatMessageType_ForwardMessage || longTapModel.message.messageType == CIMChatMessageType_StickersMessage || longTapModel.message.messageType == CIMChatMessageType_GameStickersMessage) {
            //图片/视频/音频/文件/名片 消息（删除）
            [menuArr addObjectsFromArray:@[[NSNumber numberWithInteger:MessageMenuItemActionTypeDelete]]];
        }
        
    } else {
        //单聊
        if (longTapModel.isSelf) {  //该消息是自己发送的
            if (longTapModel.message.messageType == CIMChatMessageType_TextMessage ||longTapModel.message.messageType == CIMChatMessageType_AtMessage) {
                //文字消息、 @消息（复制、转发、删除、撤回、引用）
                [menuArr addObjectsFromArray:@[
                        [NSNumber numberWithInteger:MessageMenuItemActionTypeCopy],
                        [NSNumber numberWithInteger:MessageMenuItemActionTypeForward],
                        [NSNumber numberWithInteger:MessageMenuItemActionTypeDelete],
                        [NSNumber numberWithInteger:MessageMenuItemActionTypeRevoke],
                        [NSNumber numberWithInteger:MessageMenuItemActionTypeReference]]];
            } else if (longTapModel.message.messageType == CIMChatMessageType_ImageMessage || longTapModel.message.messageType == CIMChatMessageType_VideoMessage || longTapModel.message.messageType == CIMChatMessageType_VoiceMessage || longTapModel.message.messageType == CIMChatMessageType_FileMessage || longTapModel.message.messageType == CIMChatMessageType_GeoMessage || longTapModel.message.messageType == CIMChatMessageType_ForwardMessage) {
                //图片/视频/语音/文件消息（转发、删除、撤回、引用）
                [menuArr addObjectsFromArray:@[
                        [NSNumber numberWithInteger:MessageMenuItemActionTypeForward],
                        [NSNumber numberWithInteger:MessageMenuItemActionTypeDelete],
                        [NSNumber numberWithInteger:MessageMenuItemActionTypeRevoke],
                        [NSNumber numberWithInteger:MessageMenuItemActionTypeReference]]];
            } else if (longTapModel.message.messageType == CIMChatMessageType_CardMessage) {
                //名片消息（删除、撤回、引用）
                [menuArr addObjectsFromArray:@[
                        [NSNumber numberWithInteger:MessageMenuItemActionTypeDelete],
                        [NSNumber numberWithInteger:MessageMenuItemActionTypeRevoke],
                        [NSNumber numberWithInteger:MessageMenuItemActionTypeReference]]];
            } else if (longTapModel.message.messageType == CIMChatMessageType_StickersMessage) {
                //表情消息（转发、删除、撤回、引用）
                if (longTapModel.message.isStickersSet) {
                    [menuArr addObjectsFromArray:@[
                        [NSNumber numberWithInteger:MessageMenuItemActionTypeForward],
                        [NSNumber numberWithInteger:MessageMenuItemActionTypeStickersAdd],
                        [NSNumber numberWithInteger:MessageMenuItemActionTypeStickersPackage],
                        [NSNumber numberWithInteger:MessageMenuItemActionTypeDelete],
                        [NSNumber numberWithInteger:MessageMenuItemActionTypeRevoke],
                        [NSNumber numberWithInteger:MessageMenuItemActionTypeReference]]];
                } else {
                    [menuArr addObjectsFromArray:@[
                        [NSNumber numberWithInteger:MessageMenuItemActionTypeForward],
                        [NSNumber numberWithInteger:MessageMenuItemActionTypeStickersAdd],
                        [NSNumber numberWithInteger:MessageMenuItemActionTypeDelete],
                        [NSNumber numberWithInteger:MessageMenuItemActionTypeRevoke],
                        [NSNumber numberWithInteger:MessageMenuItemActionTypeReference]]];
                }
            } else if (longTapModel.message.messageType == CIMChatMessageType_GameStickersMessage) {
                //游戏表情消息（删除、撤回、引用）
                [menuArr addObjectsFromArray:@[
                    [NSNumber numberWithInteger:MessageMenuItemActionTypeDelete],
                    [NSNumber numberWithInteger:MessageMenuItemActionTypeRevoke],
                    [NSNumber numberWithInteger:MessageMenuItemActionTypeReference]]];
            } else {
                return;
            }
        } else {
            //该消息是对方发送的
            if (longTapModel.message.messageType == CIMChatMessageType_TextMessage || longTapModel.message.messageType == CIMChatMessageType_AtMessage) {
                //文字消息、 @消息（复制、转发、删除、引用）
                [menuArr addObjectsFromArray:@[
                        [NSNumber numberWithInteger:MessageMenuItemActionTypeCopy],
                        [NSNumber numberWithInteger:MessageMenuItemActionTypeForward],
                        [NSNumber numberWithInteger:MessageMenuItemActionTypeDelete],
                        [NSNumber numberWithInteger:MessageMenuItemActionTypeReference]]];
            } else if (longTapModel.message.messageType == CIMChatMessageType_ImageMessage || longTapModel.message.messageType == CIMChatMessageType_VideoMessage || longTapModel.message.messageType == CIMChatMessageType_VoiceMessage || longTapModel.message.messageType == CIMChatMessageType_FileMessage || longTapModel.message.messageType == CIMChatMessageType_GeoMessage || longTapModel.message.messageType == CIMChatMessageType_ForwardMessage) {
                //图片/视频/文件/语音...消息（转发、删除、引用）
                [menuArr addObjectsFromArray:@[
                        [NSNumber numberWithInteger:MessageMenuItemActionTypeForward],
                        [NSNumber numberWithInteger:MessageMenuItemActionTypeDelete],
                        [NSNumber numberWithInteger:MessageMenuItemActionTypeReference]]];
            } else if (longTapModel.message.messageType == CIMChatMessageType_CardMessage) {
                //名片消息（删除、引用）
                [menuArr addObjectsFromArray:@[
                        [NSNumber numberWithInteger:MessageMenuItemActionTypeDelete],
                        [NSNumber numberWithInteger:MessageMenuItemActionTypeReference]]];
            } else if (longTapModel.message.messageType == CIMChatMessageType_StickersMessage) {
                //表情消息（转发、删除、撤回、引用）
                if (longTapModel.message.isStickersSet) {
                    [menuArr addObjectsFromArray:@[
                        [NSNumber numberWithInteger:MessageMenuItemActionTypeForward],
                        [NSNumber numberWithInteger:MessageMenuItemActionTypeStickersAdd],
                        [NSNumber numberWithInteger:MessageMenuItemActionTypeStickersPackage],
                        [NSNumber numberWithInteger:MessageMenuItemActionTypeDelete],
                        [NSNumber numberWithInteger:MessageMenuItemActionTypeReference]]];
                } else {
                    [menuArr addObjectsFromArray:@[
                        [NSNumber numberWithInteger:MessageMenuItemActionTypeForward],
                        [NSNumber numberWithInteger:MessageMenuItemActionTypeStickersAdd],
                        [NSNumber numberWithInteger:MessageMenuItemActionTypeDelete],
                        [NSNumber numberWithInteger:MessageMenuItemActionTypeReference]]];
                }
            } else if (longTapModel.message.messageType == CIMChatMessageType_GameStickersMessage) {
                [menuArr addObjectsFromArray:@[
                    [NSNumber numberWithInteger:MessageMenuItemActionTypeDelete],
                    [NSNumber numberWithInteger:MessageMenuItemActionTypeReference]]];
            } else {
                return;
            }
        }
        
        //收藏
        if (((longTapModel.message.messageType == CIMChatMessageType_TextMessage || longTapModel.message.messageType == CIMChatMessageType_AtMessage) && [NSString isNil:longTapModel.message.referenceMsgId] == YES)|| longTapModel.message.messageType == CIMChatMessageType_ImageMessage || longTapModel.message.messageType == CIMChatMessageType_VideoMessage || longTapModel.message.messageType == CIMChatMessageType_FileMessage || longTapModel.message.messageType == CIMChatMessageType_GeoMessage) {
            //文本消息(不包括引用消息)、图片消息、视频消息、文件消息、位置信息消息支持 收藏
            [menuArr addObject:[NSNumber numberWithInteger:MessageMenuItemActionTypeCollection]];
        }
        
        //多选
        if (longTapModel.message.messageType == CIMChatMessageType_TextMessage || longTapModel.message.messageType == CIMChatMessageType_AtMessage || longTapModel.message.messageType == CIMChatMessageType_ImageMessage || longTapModel.message.messageType == CIMChatMessageType_VideoMessage || longTapModel.message.messageType == CIMChatMessageType_VoiceMessage ||
            longTapModel.message.messageType == CIMChatMessageType_FileMessage || longTapModel.message.messageType == CIMChatMessageType_GeoMessage || longTapModel.message.messageType == CIMChatMessageType_ForwardMessage || longTapModel.message.messageType == CIMChatMessageType_StickersMessage) {
            //文本消息、图片消息、视频消息、语音消息、文件消息、名片消息、位置信息消息、表情消息 支持 多选
            [menuArr addObject:[NSNumber numberWithInteger:MessageMenuItemActionTypeMultiSelect]];
        }
    }
   

    //计算消息的坐标位置,确定菜单弹窗弹出的位置的坐标
    CGRect targetRect = [self.baseTableView convertRect:longTapCell.frame toView:self.view];
    if (longTapModel.isSelf) {
        //x坐标为气泡最右端
        targetRect.origin.x = DScreenWidth - 16 - 40 - 6 - longTapModel.messageWidth - 20;
    } else {
        //x坐标为气泡最左端
        targetRect.origin.x = 16 + 40 + 6;
    }
    //y坐标为气泡最下端 width和height是cell的宽度和高度
    targetRect.origin.y -= 10;
    
    BOOL isBottom = (cellIndex.row == (self.messageModels.count - 1) && self.messageModels.count > 2) ? YES : NO;
    //显示出弹窗
    NoaChatMessageMoreView *msgMoreMenu = [[NoaChatMessageMoreView alloc] initWithMenu:menuArr targetRect:targetRect isFromMy:longTapModel.isSelf isBottom:isBottom msgContentSize:CGSizeMake(longTapModel.messageWidth, longTapModel.messageHeight)];
    WeakSelf;
    [msgMoreMenu setMenuClick:^(MessageMenuItemActionType actionType) {
        switch (actionType) {
            case MessageMenuItemActionTypeCopy:
                //复制
                [weakSelf messageCopyActionWithModel:longTapModel];
                break;
            case MessageMenuItemActionTypeForward:
                //转发
                [weakSelf messageForwardActionWithMsgList:@[longTapModel] multiSelectType:ZMultiSelectTypeSingleForward];
                break;
            case MessageMenuItemActionTypeDelete:
                //删除
                [weakSelf messageDeleteActionWithMsg:longTapModel index:cellIndex.row];
                break;
            case MessageMenuItemActionTypeRevoke:
                //撤回
                [weakSelf messageRevokeActionWithMsg:longTapModel];
                break;
            case MessageMenuItemActionTypeReference:
                //引用
                [weakSelf messageReferenceActionWithMsg:longTapModel];
                break;
            case MessageMenuItemActionTypeCollection:
                //收藏
                [weakSelf messageCollectionActionWithMsg:longTapModel];
                break;
            case MessageMenuItemActionTypeMultiSelect:
                //多选
                [weakSelf messageMultiSelectAction];
                break;
            case MessageMenuItemActionTypeStickersAdd:
                //添加表情到收藏
                [weakSelf messageStickersAddToCollectionActionWithMsg:longTapModel];
                break;
            case MessageMenuItemActionTypeStickersPackage:
                //查找当前表情所属表情包
                [weakSelf messageStickersSearchPackageActionWithMsg:longTapModel];
                break;
            default:
                break;
        }
    }];
}

//消息发送失败，重发消息
- (void)messageReSendClick:(NSIndexPath *)cellIndex {
    if (self.multiSelectStatus) {
        return;
    }
    
    NoaMessageModel *reSendMsgModel = [self.messageModels objectAtIndex:cellIndex.row];
    WeakSelf
    if (reSendMsgModel.message.messageType == CIMChatMessageType_FileMessage) {
        NoaPresentItem *saveItem = [NoaPresentItem creatPresentViewItemWithText:LanguageToolMatch(@"重新上传") textColor:COLOR_11 font:FONTR(17) itemHeight:DWScale(54) backgroundColor:COLORWHITE];
        self.tkThemeChangeBlock = ^(id  _Nullable itself, NSUInteger themeIndex) {
            if (themeIndex == 0) {
                saveItem.textColor = COLOR_11;
                saveItem.backgroundColor = COLORWHITE;
            }else {
                saveItem.textColor = COLORWHITE;
                saveItem.backgroundColor = COLOR_11;
            }
        };
        NoaPresentItem *cancelItem = [NoaPresentItem creatPresentViewItemWithText:LanguageToolMatch(@"取消") textColor:COLOR_99 font:FONTR(17) itemHeight:DWScale(54) backgroundColor:COLORWHITE];
        self.tkThemeChangeBlock = ^(id  _Nullable itself, NSUInteger themeIndex) {
            if (themeIndex == 0) {
                cancelItem.textColor = COLOR_99;
                cancelItem.backgroundColor = COLORWHITE;
            }else {
                cancelItem.textColor = COLOR_99;
                cancelItem.backgroundColor = COLOR_11;
            }
        };
        NoaPresentView *viewAlert = [[NoaPresentView alloc] initWithFrame:CGRectMake(0, 0, DScreenWidth, DScreenHeight) titleItem:nil selectItems:@[saveItem] cancleItem:cancelItem doneClick:^(NSInteger index) {
            [weakSelf reSendFailMessageWithReSendMsg:reSendMsgModel Index:cellIndex.row];
        } cancleClick:^{
            
        }];
        [self.view addSubview:viewAlert];
        [viewAlert showPresentView];
    } else {
        NoaMessageAlertView *msgAlertView = [[NoaMessageAlertView alloc] initWithMsgAlertType:ZMessageAlertTypeNomal supView:nil];
        msgAlertView.lblContent.text = LanguageToolMatch(@"是否重新发送");
        [msgAlertView.btnSure setTitle:LanguageToolMatch(@"确认") forState:UIControlStateNormal];
        [msgAlertView alertShow];
        msgAlertView.sureBtnBlock = ^(BOOL isCheckBox) {
            [weakSelf reSendFailMessageWithReSendMsg:reSendMsgModel Index:cellIndex.row];
        };
    }
}

//给非好友发送消息，notFriend消息中点击添加好友的弹窗
- (void)systemMessageNotFriendAlert:(NSIndexPath *)cellIndex {
    //文件助手，不会出现此情形
}

//语音消息点击，播放或者停止
- (void)voiceMessageClick:(NSIndexPath *)cellIndex {
    if (self.multiSelectStatus) {
        return;
    }
    NoaMessageVoiceCell *clickVoiceCell = (NoaMessageVoiceCell *)[self.baseTableView cellForRowAtIndexPath:cellIndex];
    NoaMessageModel *voiceMsgModel = [self.messageModels objectAtIndex:cellIndex.row];
    if (ZAudioPlayerTOOL.isPlaying) {
        [ZAudioPlayerTOOL stop];
    }
    if (clickVoiceCell.isAnimation) {
        [clickVoiceCell stopAnimation];
        [ZAudioPlayerTOOL stop];
    } else {
        if (ZAudioPlayerTOOL.currentVoiceCell && ![ZAudioPlayerTOOL.currentVoiceCell isEqual:clickVoiceCell]) {
            [ZAudioPlayerTOOL stop];
            [ZAudioPlayerTOOL.currentVoiceCell stopAnimation];
        }
        ZAudioPlayerTOOL.currentVoiceCell = clickVoiceCell;
        if (voiceMsgModel.isSelf) {
            //本地音频文件路径
            NSString *folderPath = [NSString getVoiceDiectoryWithCustomPath:[NSString stringWithFormat:@"%@-%@",UserManager.userInfo.userUID, _sessionID]];
            NSString *meLocalPath = [NSString stringWithFormat:@"%@/%@", folderPath, voiceMsgModel.message.localVoiceName];
            //判断本地音频文件是否存在
            if ([[NSFileManager defaultManager] fileExistsAtPath:meLocalPath]) {
                //本地存在对应的音频文件
                BOOL isPlay = [ZAudioPlayerTOOL playAudioPath:meLocalPath];
                if (isPlay) {
                    [clickVoiceCell startAnimation];
                    ZAudioPlayerTOOL.currentAudioPath = voiceMsgModel.message.localVoiceName;
                    ZAudioPlayerTOOL.playMessageID = voiceMsgModel.message.msgID;
                }
            } else {
                //本地不存在对应的音频文件，需要先缓存，再播放(先判断是否有网络)
                if ([ZTOOL isNetworkAvailable]) {
                    //有网络，下载语音文件，下载成功后并进行播放
                    NSString *downloadVoicePath = [NSString stringWithFormat:@"%@/%@", folderPath, [voiceMsgModel.message.voiceName MD5Encryption]];
                    //下载语音音频文件
                    [NoaMessageTools downloadAudioWith:voiceMsgModel.message.voiceName AudioCachePath:downloadVoicePath completion:^(BOOL success, NSString * _Nonnull audioPath) {
                        if (success) {
                            BOOL isPlay = [ZAudioPlayerTOOL playAudioPath:audioPath];
                            if (isPlay) {
                                [clickVoiceCell startAnimation];
                                ZAudioPlayerTOOL.currentAudioPath = voiceMsgModel.message.localVoiceName;
                                ZAudioPlayerTOOL.playMessageID = voiceMsgModel.message.msgID;
                            }
                        } else {
                            [HUD showMessage:LanguageToolMatch(@"语音播放失败，请稍后再试")];
                        }
                    }];
                } else {
                    //无网络
                    [HUD showMessage:LanguageToolMatch(@"网络错误,播放失败")];
                }
            }
        } else {
            //本地音频文件路径
            NSString *folderPath = [NSString getVoiceDiectoryWithCustomPath:[NSString stringWithFormat:@"%@-%@",UserManager.userInfo.userUID, _sessionID]];
            NSString *meLocalPath = [NSString stringWithFormat:@"%@/%@", folderPath, [voiceMsgModel.message.voiceName MD5Encryption]];
            //判断本地音频文件是否存在
            if ([[NSFileManager defaultManager] fileExistsAtPath:meLocalPath]) {
                //本地存在对应的音频文件
                BOOL isPlay = [ZAudioPlayerTOOL playAudioPath:meLocalPath];
                if (isPlay) {
                    [clickVoiceCell startAnimation];
                    ZAudioPlayerTOOL.currentAudioPath = voiceMsgModel.message.voiceName;
                    ZAudioPlayerTOOL.playMessageID = voiceMsgModel.message.msgID;
                }
            } else {
                //本地不存在对应的音频文件，需要先缓存，再播放(先判断是否有网络)
                if ([ZTOOL isNetworkAvailable]) {
                    //有网络，下载语音文件，下载成功后并进行播放
                    [NoaMessageTools downloadAudioWith:voiceMsgModel.message.voiceName AudioCachePath:meLocalPath completion:^(BOOL success, NSString * _Nonnull audioPath) {
                        if (success) {
                            BOOL isPlay = [ZAudioPlayerTOOL playAudioPath:audioPath];
                            if (isPlay) {
                                [clickVoiceCell startAnimation];
                                ZAudioPlayerTOOL.currentAudioPath = voiceMsgModel.message.voiceName;
                                ZAudioPlayerTOOL.playMessageID = voiceMsgModel.message.msgID;
                            }
                        } else {
                            [HUD showMessage:LanguageToolMatch(@"语音播放失败，请稍后再试")];
                        }
                    }];
                } else {
                    //无网络
                    [HUD showMessage:LanguageToolMatch(@"网络错误,播放失败")];
                }
            }
        }
    }
}

//消息气泡点击
- (void)messageBubbleClick:(NSIndexPath *)cellIndex {
    if (self.multiSelectStatus) {
        return;
    }
    NoaMessageModel *bubbleMsgClickModel = [self.messageModels objectAtIndex:cellIndex.row];
    if (bubbleMsgClickModel.message.messageType == CIMChatMessageType_FileMessage) {
        //文件消息-文件详情
        NSString *foldPath = [NSString getFileDiectoryWithCustomPath:[NSString stringWithFormat:@"%@-%@",UserManager.userInfo.userUID, self.sessionID]];
        NSString *fileFullPath = [NSString stringWithFormat:@"%@/%@", foldPath, bubbleMsgClickModel.message.fileName];
        
        NoaChatFileDetailViewController *fileDetailVC = [[NoaChatFileDetailViewController alloc] init];
        fileDetailVC.fileMsgModel = bubbleMsgClickModel;
        fileDetailVC.fromSessionId = self.sessionID;
        fileDetailVC.localFilePath = fileFullPath;
        fileDetailVC.isShowRightBtn = YES;
        fileDetailVC.isFromCollcet = NO;
        [self.navigationController pushViewController:fileDetailVC animated:YES];
    } else if (bubbleMsgClickModel.message.messageType == CIMChatMessageType_CardMessage) {
        //名片消息-用户个人资料页
        NoaUserHomePageVC *userHomeVC = [NoaUserHomePageVC new];
        userHomeVC.userUID = bubbleMsgClickModel.message.cardUserId;
        userHomeVC.groupID = @"";
        [self.navigationController pushViewController:userHomeVC animated:YES];
    } else if (bubbleMsgClickModel.message.messageType == CIMChatMessageType_ForwardMessage) {
        //消息记录详情页面
        NoaChatRecordDetailViewController *chatRecordDetailVC = [[NoaChatRecordDetailViewController alloc] init];
        chatRecordDetailVC.levelNum = 1;
        chatRecordDetailVC.model = bubbleMsgClickModel;
        [self.navigationController pushViewController:chatRecordDetailVC animated:YES];
    }
}

//cell的点击事件 (多选)
- (void)messageCellClick:(NSIndexPath *)cellIndex {
    if (self.multiSelectStatus) {
        NoaMessageModel *multiClickModel = [self.messageModels objectAtIndex:cellIndex.row];
        if (multiClickModel.message.messageType != CIMChatMessageType_GroupNotice && multiClickModel.message.messageType != CIMChatMessageType_CardMessage  && multiClickModel.message.messageType != CIMChatMessageType_GameStickersMessage && multiClickModel.message.messageType != CIMChatMessageType_ServerMessage && multiClickModel.message.messageSendType == CIMChatMessageSendTypeSuccess) {
            NoaMessageModel *multiClickModel = [self.messageModels objectAtIndex:cellIndex.row];
            if (multiClickModel.multiSelected == NO && self.selectedMsgModels.count >= Multi_Selected_Max_Num) {
                [HUD showMessage:LanguageToolMatch(@"最多选择100条消息")];
                return;
            }
            multiClickModel.multiSelected = !multiClickModel.multiSelected;
            [self.messageModels replaceObjectAtIndex:cellIndex.row withObject:multiClickModel];
            [self.baseTableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:cellIndex, nil] withRowAnimation:UITableViewRowAnimationNone];
            
            if (multiClickModel.multiSelected) {
                [self.selectedMsgModels addObject:multiClickModel];
            } else {
                WeakSelf
                [self.selectedMsgModels.safeArray enumerateObjectsUsingBlock:^(NoaMessageModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if (multiClickModel.multiSelected == NO && [obj.message.msgID isEqualToString:multiClickModel.message.msgID]) {
                        [weakSelf.selectedMsgModels removeObject:obj];
                    }
                }];
            }
        }
        self.multiSelectBottomView.selectNum = self.selectedMsgModels.count;
    }
}

#pragma mark - 消息重新发送
- (void)reSendFailMessageWithReSendMsg:(NoaMessageModel *)reSendMsgModel Index:(NSInteger)index {
    WeakSelf
    [NoaMessageSendHander ZMessageReSendWithFailMsg:reSendMsgModel compelete:^(NoaIMChatMessageModel * _Nonnull sendChatMsg) {
        //将重新发送的消息移动到消息列表最底端
        [weakSelf.messageModels removeObjectAtIndex:index];
        [weakSelf chatListAppendMessage:sendChatMsg];
        //如果是文本消息、At消息、名片消息、表情消息，添加到UI上后，直接发送消息
        if (sendChatMsg.messageType == CIMChatMessageType_TextMessage || sendChatMsg.messageType == CIMChatMessageType_AtMessage || sendChatMsg.messageType == CIMChatMessageType_CardMessage || sendChatMsg.messageType == CIMChatMessageType_ForwardMessage || sendChatMsg.messageType == CIMChatMessageType_StickersMessage || sendChatMsg.messageType == CIMChatMessageType_GameStickersMessage) {
            [IMSDKManager toolSendChatMessageWith:sendChatMsg];
        } else if (sendChatMsg.messageType == CIMChatMessageType_ImageMessage || sendChatMsg.messageType == CIMChatMessageType_VideoMessage || sendChatMsg.messageType == CIMChatMessageType_VoiceMessage || reSendMsgModel.message.messageType == CIMChatMessageType_FileMessage || sendChatMsg.messageType == CIMChatMessageType_GeoMessage) {
               
            NSMutableArray *taskArray = [NSMutableArray array];
            NSString *customPath = [NSString stringWithFormat:@"%@-%@", UserManager.userInfo.userUID, sendChatMsg.toID];
            if (sendChatMsg.messageType == CIMChatMessageType_ImageMessage) {
                //本地沙盒路径
                NSString *localThumbImgPath = [NSString getPathWithImageName:sendChatMsg.localthumbImgName CustomPath:customPath];
                NSString *imagePath = [NSString getPathWithImageName:sendChatMsg.localImgName CustomPath:customPath];
                
                //缩略图
                NSData *thumbImgData = [NSData dataWithContentsOfFile:localThumbImgPath];
                NoaFileUploadTask *thumbImgTask = [[NoaFileUploadTask alloc] initWithTaskId:[NSString stringWithFormat:@"%@_thumb", sendChatMsg.msgID] filePath:localThumbImgPath originFilePath:imagePath fileName:sendChatMsg.localthumbImgName fileType:@"" isEncrypt:YES dataLength:thumbImgData.length uploadType:ZHttpUploadTypeImageThumbnail beSendMessage:sendChatMsg delegate:self];
                thumbImgTask.messageTaskType = FileUploadMessageTaskTypeThumbImage;
                [taskArray addObject:thumbImgTask];
                
                //图片
                NoaFileUploadTask *imgTask = [[NoaFileUploadTask alloc] initWithTaskId:sendChatMsg.msgID filePath:imagePath originFilePath:@"" fileName:sendChatMsg.localImgName fileType:@"" isEncrypt:YES dataLength:sendChatMsg.imgSize uploadType:ZHttpUploadTypeImage beSendMessage:sendChatMsg delegate:self];
                imgTask.messageTaskType = FileUploadMessageTaskTypeImage;
                [taskArray addObject:imgTask];
                [[NoaFileUploadManager sharedInstance] addUploadTask:imgTask];
            } else if (sendChatMsg.messageType == CIMChatMessageType_VideoMessage) {
                /// 视频
                //视频封面上传
                NSString *coverPath = [NSString getPathWithImageName:sendChatMsg.localVideoCover CustomPath:customPath];
                NoaFileUploadTask *coverTask = [[NoaFileUploadTask alloc] initWithTaskId:[NSString stringWithFormat:@"%@_cover", sendChatMsg.msgID] filePath:coverPath originFilePath:@"" fileName:sendChatMsg.localVideoCover fileType:@"" isEncrypt:YES dataLength:sendChatMsg.videoCoverSize uploadType:ZHttpUploadTypeImage beSendMessage:sendChatMsg delegate:self];
                coverTask.messageTaskType = FileUploadMessageTaskTypeCover;
                [taskArray addObject:coverTask];
                [[NoaFileUploadManager sharedInstance] addUploadTask:coverTask];
                
                //视频文件上传
                NSString *videoPath = [NSString getPathWithVideoName:sendChatMsg.localVideoName CustomPath:customPath];
                NoaFileUploadTask *videoTask = [[NoaFileUploadTask alloc] initWithTaskId:sendChatMsg.msgID filePath:videoPath originFilePath:@"" fileName:sendChatMsg.localVideoName fileType:@"" isEncrypt:YES dataLength:sendChatMsg.videoSize uploadType:ZHttpUploadTypeVideo beSendMessage:sendChatMsg delegate:self];
                videoTask.messageTaskType = FileUploadMessageTaskTypeVideo;
                [taskArray addObject:videoTask];
                [[NoaFileUploadManager sharedInstance] addUploadTask:videoTask];
            } else if (sendChatMsg.messageType == CIMChatMessageType_VoiceMessage) {
                //音频
                NSData *audioData = [NSData dataWithContentsOfFile:sendChatMsg.localVoicePath options:NSDataReadingMappedIfSafe error:nil];
                NoaFileUploadTask *voiceTask = [[NoaFileUploadTask alloc] initWithTaskId:sendChatMsg.msgID filePath:sendChatMsg.localVoicePath originFilePath:@"" fileName:sendChatMsg.localVoiceName fileType:@"" isEncrypt:NO dataLength:audioData.length uploadType:ZHttpUploadTypeVoice beSendMessage:sendChatMsg delegate:self];
                voiceTask.messageTaskType = FileUploadMessageTaskTypeVoice;
                [taskArray addObject:voiceTask];
                [[NoaFileUploadManager sharedInstance] addUploadTask:voiceTask];
            } else if (sendChatMsg.messageType == CIMChatMessageType_FileMessage) {
                //文件
                NSString *filePath = [NSString getPathWithFileName:sendChatMsg.fileName CustomPath:customPath];

                NoaFileUploadTask *fileTask = [[NoaFileUploadTask alloc] initWithTaskId:sendChatMsg.msgID filePath:filePath originFilePath:@"" fileName:sendChatMsg.fileName fileType:sendChatMsg.fileType isEncrypt:YES dataLength:sendChatMsg.fileSize uploadType:ZHttpUploadTypeFile beSendMessage:sendChatMsg delegate:self];
                fileTask.messageTaskType = FileUploadMessageTaskTypeFile;
                [taskArray addObject:fileTask];
                [[NoaFileUploadManager sharedInstance] addUploadTask:fileTask];
            } else if (sendChatMsg.messageType == CIMChatMessageType_GeoMessage) {
                //地理位置
                NSString *geoImgPath = [NSString getPathWithImageName:sendChatMsg.localGeoImgName CustomPath:customPath];
                NSData *geoImgData = [NSData dataWithContentsOfFile:sendChatMsg.localVoicePath options:NSDataReadingMappedIfSafe error:nil];
                NoaFileUploadTask *geoImgTask = [[NoaFileUploadTask alloc] initWithTaskId:sendChatMsg.msgID filePath:geoImgPath originFilePath:@"" fileName:sendChatMsg.localImgName fileType:@"" isEncrypt:YES dataLength:geoImgData.length uploadType:ZHttpUploadTypeImage beSendMessage:sendChatMsg delegate:self];
                geoImgTask.messageTaskType = FileUploadMessageTaskTypeImage;
                [taskArray addObject:geoImgTask];
                [[NoaFileUploadManager sharedInstance] addUploadTask:geoImgTask];
            }
            NoaFileUploadGetSTSTask *getSTSTask = [[NoaFileUploadGetSTSTask alloc] init];
            getSTSTask.uploadTask = taskArray;
            [[NoaFileUploadManager sharedInstance].operationQueue addOperation:getSTSTask];

            NoaMessageSendTask *messageSendTask = [[NoaMessageSendTask alloc] init];
            messageSendTask.uploadTask = taskArray;
            [[NoaFileUploadManager sharedInstance].operationQueue addOperation:messageSendTask];
        } else {
            return;
        }
    }];
}

#pragma mark - <<<<<<ZMsgMultiSelectDelegate 多选bottom事件代理>>>>>>
//多选-合并转发
- (void)mergeForwardMessageAction {
    if (self.selectedMsgModels.count <= 0) {
        return;
    }
    //合并转发
    [self sendChatRecordMessage];
    //UI恢复状态
    self.multiSelectStatus = NO;
    self.multiSelectBottomView.selectNum = 0;
    self.multiSelectBottomView.hidden = YES;
    [self.baseTableView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.view);
        make.top.equalTo(_topView.mas_bottom);
        make.bottom.equalTo(self.viewInput.mas_top);
    }];
    
    [self.messageModels enumerateObjectsUsingBlock:^(NoaMessageModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.multiSelected = NO;
    }];
    [self.baseTableView reloadData];
    //显示底部输入框
    self.viewInput.hidden = NO;
}

//多选-逐条转发
- (void)singleForwardMessageAction {
    if (self.selectedMsgModels.count <= 0) {
        return;
    }
    //根据消息时间进行升序排列
    NSArray *sortResultArr = [NSMutableArray sortMultiSelectedMessageArr:self.selectedMsgModels.safeArray];
    //逐条转发调用的还是以前转发消息的接口
    [self messageForwardActionWithMsgList:sortResultArr multiSelectType:ZMultiSelectTypeSingleForward];
    //UI恢复状态
    [self setupMultiSelectedStatusDefaultIsReload:YES];
}

//多选-删除
- (void)deleteSelectedMessageAction {
    if (self.selectedMsgModels.count <= 0) {
        return;
    }
    
    WeakSelf
    //文件助手单向删除
    NoaMessageAlertView *msgAlertView = [[NoaMessageAlertView alloc] initWithMsgAlertType:ZMessageAlertTypeNomal supView:nil];
    msgAlertView.lblContent.text = LanguageToolMatch(@"删除所选消息");
    [msgAlertView.btnSure setTitle:LanguageToolMatch(@"确认") forState:UIControlStateNormal];
    [msgAlertView.btnCancel setTitle:LanguageToolMatch(@"取消") forState:UIControlStateNormal];
    [msgAlertView alertShow];
    msgAlertView.sureBtnBlock = ^(BOOL isCheckBox) {
        [weakSelf integratedMultiSelectedDeleteData:isCheckBox ? ZMsgDeleteTypeBothWay : ZMsgDeleteTypeOneWay];
        [weakSelf setupMultiSelectedStatusDefaultIsReload:YES];
    };
}

//整合 多选-删除 的数据
- (void)integratedMultiSelectedDeleteData:(ZMsgDeleteType)deleteType {
    //删除所选消息
    __block NSMutableArray *selectedMsgIdArr = [NSMutableArray array];

    [self.selectedMsgModels enumerateObjectsUsingBlock:^(NoaMessageModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [selectedMsgIdArr addObject:obj.message.serviceMsgID];
    }];
    
    [self messageDeleteWithSMgIds:selectedMsgIdArr withDeleteType:deleteType];
}

#pragma mark - <<<<<<长按菜单弹窗点击事件>>>>>>
//复制
- (void)messageCopyActionWithModel:(NoaMessageModel *)menuModel {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    if (menuModel.message.messageType == CIMChatMessageType_TextMessage) {
        pasteboard.string = menuModel.message.textContent;
    } else if (menuModel.message.messageType == CIMChatMessageType_AtMessage) {
        pasteboard.string = menuModel.message.showContent;
    } else {
        return;
    }
    [HUD showMessage:LanguageToolMatch(@"复制成功")];
}

//转发
- (void)messageForwardActionWithMsgList:(NSArray *)msgModelList multiSelectType:(ZMultiSelectType)multiSelectType {
    NoaChatMultiSelectViewController *vc = [NoaChatMultiSelectViewController new];
    vc.multiSelectType = multiSelectType;
    vc.fromSessionId = self.sessionID;
    vc.forwardMsgList = msgModelList;
    [self.navigationController pushViewController:vc animated:YES];
    WeakSelf
    vc.forwardMsgSendSuccess = ^(NSArray<NoaIMChatMessageModel *> * _Nullable sendForwardMsgList) {
        [HUD showMessage:LanguageToolMatch(@"转发成功")];
        //转发消息是转发给当前聊天对象
        [sendForwardMsgList enumerateObjectsUsingBlock:^(NoaIMChatMessageModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([weakSelf.sessionID isEqualToString:obj.toID]) {
                NoaMessageModel *sendMsg = [[NoaMessageModel alloc] initWithMessageModel:obj];
                //刷新并滚动到底部
                [weakSelf.messageModels addObject:sendMsg];
            }
        }];
        //[weakSelf setupMultiSelectedStatusDefaultIsReload:NO];
        //处理消息是否显示时间
        [weakSelf computeVisibleTime];
        [ZTOOL doInMain:^{
            [weakSelf.baseTableView reloadData];
        }];
        //加载滚动到底部
        [weakSelf tableViewScrollToBottom:NO duration:0.25];
    };
    vc.forwardMsgSendFail = ^{
        //[weakSelf setupMultiSelectedStatusDefaultIsReload:YES];
    };
}

//长按弹窗 删除
- (void)messageDeleteActionWithMsg:(NoaMessageModel *)msgModel index:(NSInteger)msgIndex {
    NoaMessageModel *deleteMsgModel = [self.messageModels objectAtIndex:msgIndex];
    /**
     如果消息是发送中/发送失败的状态，删除操作只删除本地且只有单向删除，如果消息发送成功，则是按正常删除逻辑
     */
    if (deleteMsgModel.message.messageSendType == CIMChatMessageSendTypeFail || deleteMsgModel.message.messageSendType == CIMChatMessageSendTypeSending) {
        WeakSelf
        NoaMessageAlertView *msgAlertView = [[NoaMessageAlertView alloc] initWithMsgAlertType:ZMessageAlertTypeNomal supView:nil];
        msgAlertView.lblContent.text = LanguageToolMatch(@"删除所选消息");
        [msgAlertView.btnSure setTitle:LanguageToolMatch(@"确认") forState:UIControlStateNormal];
        [msgAlertView.btnCancel setTitle:LanguageToolMatch(@"取消") forState:UIControlStateNormal];
        [msgAlertView alertShow];
        msgAlertView.sureBtnBlock = ^(BOOL isCheckBox) {
           //只从本地删除
            BOOL isDelete = [IMSDKManager toolDeleteChatMessageWith:msgModel.message];
            if (isDelete) {
                [weakSelf.messageModels removeObject:msgModel];
                //处理消息是否显示时间
                [weakSelf computeVisibleTime];
                
                [ZTOOL doInMain:^{
                    [weakSelf.baseTableView reloadData];
                }];
            }
        };
    } else {
        WeakSelf
        NoaMessageAlertView *msgAlertView = [[NoaMessageAlertView alloc] initWithMsgAlertType:ZMessageAlertTypeNomal supView:nil];
        msgAlertView.lblContent.text = LanguageToolMatch(@"删除所选消息");
        [msgAlertView.btnSure setTitle:LanguageToolMatch(@"确认") forState:UIControlStateNormal];
        [msgAlertView.btnCancel setTitle:LanguageToolMatch(@"取消") forState:UIControlStateNormal];
        [msgAlertView alertShow];
        msgAlertView.sureBtnBlock = ^(BOOL isCheckBox) {
            [weakSelf.selectedMsgModels addObject:msgModel];
            [weakSelf messageDeleteWithSMgIds:@[msgModel.message.serviceMsgID] withDeleteType:isCheckBox ? ZMsgDeleteTypeBothWay : ZMsgDeleteTypeOneWay];
        };
    }
}

//撤回
- (void)messageRevokeActionWithMsg:(NoaMessageModel *)msgModel {
    NoaMessageAlertView *msgAlertView = [[NoaMessageAlertView alloc] initWithMsgAlertType:ZMessageAlertTypeNomal supView:nil];
    msgAlertView.lblContent.text = LanguageToolMatch(@"撤回所选消息");
    [msgAlertView.btnSure setTitle:LanguageToolMatch(@"确认") forState:UIControlStateNormal];
    [msgAlertView.btnSure setTkThemeTitleColor:@[COLORWHITE,COLORWHITE] forState:UIControlStateNormal];
    msgAlertView.btnSure.tkThemebackgroundColors = @[COLOR_5966F2, COLOR_5966F2];
    [msgAlertView.btnSure setTkThemeBackgroundImage:@[[UIImage ImageForColor:COLOR_4069B9],[UIImage ImageForColor:COLOR_4069B9_DARK]] forState:UIControlStateSelected];
    [msgAlertView.btnSure setTkThemeBackgroundImage:@[[UIImage ImageForColor:COLOR_4069B9],[UIImage ImageForColor:COLOR_4069B9_DARK]] forState:UIControlStateHighlighted];
    
    [msgAlertView.btnCancel setTitle:LanguageToolMatch(@"取消") forState:UIControlStateNormal];
    [msgAlertView.btnCancel setTkThemeTitleColor:@[COLOR_66,COLORWHITE] forState:UIControlStateNormal];
    msgAlertView.btnCancel.tkThemebackgroundColors = @[COLOR_F6F6F6, COLOR_F5F6F9_DARK];
    [msgAlertView.btnCancel setTkThemeBackgroundImage:@[[UIImage ImageForColor:COLOR_EEEEEE],[UIImage ImageForColor:COLOR_EEEEEE_DARK]] forState:UIControlStateSelected];
    [msgAlertView.btnCancel setTkThemeBackgroundImage:@[[UIImage ImageForColor:COLOR_EEEEEE],[UIImage ImageForColor:COLOR_EEEEEE_DARK]] forState:UIControlStateHighlighted];
    [msgAlertView alertShow];
    WeakSelf
    msgAlertView.sureBtnBlock = ^(BOOL isCheckBox) {
        [weakSelf messageReCallWithMsg:msgModel];
    };
}

//引用
- (void)messageReferenceActionWithMsg:(NoaMessageModel *)msgModel {
    self.viewInput.messageModelReference = msgModel;
    [self.viewInput inputViewBecomeFirstResponder];
}

//收藏
- (void)messageCollectionActionWithMsg:(NoaMessageModel *)msgModel {
    //调用收藏消息接口
    //消息的会话类型
    NSString *chatTypeStr = @"SINGLE_CHAT";
    
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic setObjectSafe:msgModel.message.serviceMsgID forKey:@"smsgId"];
    [dic setObjectSafe:UserManager.userInfo.userUID forKey:@"userUid"];
    [dic setObjectSafe:chatTypeStr forKey:@"chatType"];
    
    [IMSDKManager MessageCollectionSave:dic onSuccess:^(id _Nullable data, NSString * _Nullable traceId) {
        [HUD hideHUD];
        BOOL result = [data boolValue];
        if (result) {
            [HUD showMessage:LanguageToolMatch(@"收藏成功")];
        } else {
            [HUD showMessage:LanguageToolMatch(@"收藏失败")];
        }
    } onFailure:^(NSInteger code, NSString * _Nullable msg, NSString * _Nullable traceId) {
        [HUD hideHUD];
        [HUD showMessageWithCode:code errorMsg:msg];
        return;
    }];
}

//多选
- (void)messageMultiSelectAction {
    NSLog(@"消息多选");
    [self.viewInput inputViewResignFirstResponder];
    
    [self.selectedMsgModels removeAllObjects];
    [self.multiSelectBottomView reloadShowMultiBottom];
    self.multiSelectBottomView.hidden = NO;
    [self.view bringSubviewToFront:self.multiSelectBottomView];
    [self.baseTableView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.view);
        make.top.equalTo(_topView.mas_bottom);
        make.bottom.equalTo(self.multiSelectBottomView.mas_top);
    }];
    self.multiSelectStatus = YES;
    self.topView.showCancel = YES;
    [self.baseTableView reloadData];
    //隐藏底部输入框
    self.viewInput.hidden = YES;
}

//添加表情到收藏
- (void)messageStickersAddToCollectionActionWithMsg:(NoaMessageModel *)msgModel {
    //组装接口数据
    NSMutableDictionary *stickersDic = [NSMutableDictionary dictionary];
    [stickersDic setObjectSafe:msgModel.message.stickersImg forKey:@"contentUrl"];
    [stickersDic setObjectSafe:@(msgModel.message.stickersHeight) forKey:@"height"];
    [stickersDic setObjectSafe:@(msgModel.message.stickersSize) forKey:@"size"];
    [stickersDic setObjectSafe:msgModel.message.stickersId forKey:@"stickersKey"];
    [stickersDic setObjectSafe:msgModel.message.stickersThumbnailImg forKey:@"thumbUrl"];
    [stickersDic setObjectSafe:UserManager.userInfo.userUID forKey:@"userUid"];
    [stickersDic setObjectSafe:@(msgModel.message.stickersWidth) forKey:@"width"];
    //调用接口
    [self requestAddStickersToCollectionWithDic:stickersDic isReloadCollection:YES];
}

//查找当前表情所属表情包
- (void)messageStickersSearchPackageActionWithMsg:(NoaMessageModel *)msgModel {
    //跳转表情包详情
    NoaEmojiPackageDetailViewController *vc = [[NoaEmojiPackageDetailViewController alloc] init];
    vc.stickersId = msgModel.message.stickersId;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Network Request
//删除消息(单向/双向)
- (void)messageDeleteWithSMgIds:(NSArray *)sMsgIdsList withDeleteType:(ZMsgDeleteType)deleteType {
    [HUD showActivityMessage:LanguageToolMatch(@"删除中...")];
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:@(CIMChatType_SingleChat) forKey:@"chatType"];//单聊
    [dict setValue:sMsgIdsList forKey:@"msgIdList"];//删除的消息列表
    [dict setValue:@(deleteType) forKey:@"operationStatus"];//删除类型
    [dict setValue:self.sessionID forKey:@"receiveId"];
    [dict setValue:UserManager.userInfo.userUID forKey:@"userUid"];
    [dict setValue:@"" forKey:@"msgId"];
    [dict setValue:@"" forKey:@"sMsgId"];
    WeakSelf
    [[NoaIMSDKManager sharedTool] deleteMessage:dict onSuccess:^(id _Nullable data, NSString * _Nullable traceId) {
        [weakSelf.selectedMsgModels enumerateObjectsUsingBlock:^(NoaMessageModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            //接口成功后，删除本地
            BOOL isDelete = [IMSDKManager toolDeleteChatMessageWith:obj.message];
            if (isDelete) {
                [weakSelf updateDeleteMessageAndRefreshMsgWithOriginalMsg:obj.message.serviceMsgID];
            }
        }];
      
        [weakSelf setupMultiSelectedStatusDefaultIsReload:NO];
        //处理消息是否显示时间
        [weakSelf computeVisibleTime];
        
        [ZTOOL doInMain:^{
            [weakSelf.baseTableView reloadData];
        }];
        
        [HUD showMessage:LanguageToolMatch(@"消息删除成功")];
    } onFailure:^(NSInteger code, NSString * _Nullable msg, NSString * _Nullable traceId) {
        [HUD showMessage:LanguageToolMatch(@"消息删除失败")];
    }];
}

//消息撤回
- (void)messageReCallWithMsg:(NoaMessageModel *)msgModel {
    //status  消息的状态：1-正常，2-撤回，3-删除
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithInteger:msgModel.message.chatType],@"chatType",
                                   UserManager.userInfo.userUID,@"userUid",
                                   UserManager.userInfo.nickname,@"operateNick",
                                   msgModel.message.toID,@"receiveId",
                                   msgModel.message.serviceMsgID,@"sMsgId",
                                   [NSNumber numberWithInteger:2],@"status",
                                   msgModel.message.fromID,@"uid",nil];
    
    WeakSelf
    [[NoaIMSDKManager sharedTool] recallMessage:params onSuccess:^(id _Nullable data, NSString * _Nullable traceId) {
        BOOL isRecalled = [data boolValue];
        if (isRecalled) {
            //撤回成功后，本地删除该条消息，修改消息状态为2(其实收到撤回提示消息已经做了处理，这个可以不用写的，但...)
            BOOL isDelete = [IMSDKManager toolBackDeleteChatMessageWith:msgModel.message];
            if (isDelete) {
                [weakSelf.messageModels removeObject:msgModel];
                //处理消息是否显示时间
                [weakSelf computeVisibleTime];
                [ZTOOL doInMain:^{
                    [weakSelf.baseTableView reloadData];
                }];
                
                if ([msgModel.message.fromID isEqualToString:UserManager.userInfo.userUID]) {
                    [weakSelf updateRefreshMsgWithOriginalMsg:msgModel.message.serviceMsgID];
                }
            }

        } else {
            [HUD showMessage:LanguageToolMatch(@"消息撤回失败")];
        }
    } onFailure:^(NSInteger code, NSString * _Nullable msg, NSString * _Nullable traceId) {
        [HUD showMessageWithCode:code errorMsg:msg];
    }];
}

#pragma mark - <<<<<<图片和视频的浏览>>>>>>
// 按点击消息为中心，取前后各25条，包含点击项
- (void)imageVideoBrowserWith:(NoaIMChatMessageModel *)messageModel {
    if ([NSString isNil:_sessionID]) return;
    
    NSArray *currentImageVideoMessageList = [IMSDKManager toolGetImageVideoAroundWith:_sessionID centerMsgId:messageModel.msgID before:25 after:25];
    if (currentImageVideoMessageList.count == 0) {
        currentImageVideoMessageList = @[messageModel];
    }
    _currentImageVideoMessageList = currentImageVideoMessageList;
    
    WeakSelf
    __block NSMutableArray *browserMessages = [NSMutableArray array];
    __block NSInteger messageModelIndex = 0;//点击的cell在图片视频列表中的位置
    
    [currentImageVideoMessageList enumerateObjectsUsingBlock:^(NoaIMChatMessageModel * _Nonnull chatMessage, NSUInteger idx, BOOL * _Nonnull stop) {
        
        //找到被点击的消息 下标
        if ([messageModel.msgID isEqualToString:chatMessage.msgID]) {
            messageModelIndex = idx;
        }
        
        if (chatMessage.messageType == CIMChatMessageType_ImageMessage) {
            KNPhotoItems *item = [[KNPhotoItems alloc] init];
            //图片
            item.isVideo = false;
            if (chatMessage.localImgName) {
                //本地有图片
                NSString *customPath = [NSString stringWithFormat:@"%@-%@", UserManager.userInfo.userUID, weakSelf.sessionID];
                UIImage *localImage = [NSString getImageWithImgName:chatMessage.localImgName CustomPath:customPath];
                item.sourceImage = localImage;
                //item.url = [NSString getPathWithImageName:chatMessage.localImgName CustomPath:customPath];
                //如果是本地图片有item.sourceView值时可赋值url，没有的时候，要赋值item.sourceImage
            }else {
                //网络图片
                item.url = [chatMessage.imgName getImageFullString];
                //缩略图地址
                item.thumbnailUrl = [chatMessage.thumbnailImg getImageFullString];
            }
            
            [browserMessages addObjectIfNotNil:item];
        }else if (chatMessage.messageType == CIMChatMessageType_VideoMessage) {
            //视频
            KNPhotoItems *item = [[KNPhotoItems alloc] init];
            item.isVideo = true;
            if (chatMessage.localVideoCover) {
                //本地视频封面
                NSString *customPath = [NSString stringWithFormat:@"%@-%@", UserManager.userInfo.userUID, weakSelf.sessionID];
                NSString *pathStr = [NSString getPathWithImageName:chatMessage.localVideoCover CustomPath:customPath];
                item.videoPlaceHolderImageUrl = pathStr;
            }else {
                //网络视频封面
                item.videoPlaceHolderImageUrl = [chatMessage.videoCover getImageFullString];
                //item.videoPlaceHolderImageUrlThumbnail视频封面缩略图地址
            }
            if (chatMessage.localVideoName) {
                //本地视频地址
                NSString *customPath = [NSString stringWithFormat:@"%@-%@", UserManager.userInfo.userUID, weakSelf.sessionID];
                NSString *videoUrl = [NSString getPathWithVideoName:chatMessage.localVideoName CustomPath:customPath];
                item.url = videoUrl;
            }else {
                //网络视频地址
                item.url = [chatMessage.videoName getImageFullString];
            }
            
            [browserMessages addObjectIfNotNil:item];
        }
        
    }];
    if (messageModelIndex == 0 && currentImageVideoMessageList.count > 0) {
        NoaIMChatMessageModel *first = [currentImageVideoMessageList firstObject];
        if (![first.msgID isEqualToString:messageModel.msgID]) {
            NSMutableArray *fix = [currentImageVideoMessageList mutableCopy];
            NSUInteger mid = MIN(25, fix.count);
            [fix insertObject:messageModel atIndex:mid];
            _currentImageVideoMessageList = fix.copy;
            messageModelIndex = mid;
            [browserMessages removeAllObjects];
            [fix enumerateObjectsUsingBlock:^(NoaIMChatMessageModel * _Nonnull chatMessage, NSUInteger idx, BOOL * _Nonnull stop) {
                if (chatMessage.messageType == CIMChatMessageType_ImageMessage) {
                    KNPhotoItems *item = [[KNPhotoItems alloc] init];
                    item.isVideo = false;
                    if (chatMessage.localImgName) {
                        NSString *customPath = [NSString stringWithFormat:@"%@-%@", UserManager.userInfo.userUID, weakSelf.sessionID];
                        UIImage *localImage = [NSString getImageWithImgName:chatMessage.localImgName CustomPath:customPath];
                        item.sourceImage = localImage;
                    } else {
                        item.url = [chatMessage.imgName getImageFullString];
                        item.thumbnailUrl = [chatMessage.thumbnailImg getImageFullString];
                    }
                    [browserMessages addObjectIfNotNil:item];
                } else if (chatMessage.messageType == CIMChatMessageType_VideoMessage) {
                    KNPhotoItems *item = [[KNPhotoItems alloc] init];
                    item.isVideo = true;
                    if (chatMessage.localVideoCover) {
                        NSString *customPath = [NSString stringWithFormat:@"%@-%@", UserManager.userInfo.userUID, weakSelf.sessionID];
                        NSString *pathStr = [NSString getPathWithImageName:chatMessage.localVideoCover CustomPath:customPath];
                        item.videoPlaceHolderImageUrl = pathStr;
                    } else {
                        item.videoPlaceHolderImageUrl = [chatMessage.videoCover getImageFullString];
                    }
                    if (chatMessage.localVideoName) {
                        NSString *customPath = [NSString stringWithFormat:@"%@-%@", UserManager.userInfo.userUID, weakSelf.sessionID];
                        NSString *videoUrl = [NSString getPathWithVideoName:chatMessage.localVideoName CustomPath:customPath];
                        item.url = videoUrl;
                    } else {
                        item.url = [chatMessage.videoName getImageFullString];
                    }
                    [browserMessages addObjectIfNotNil:item];
                }
            }];
        }
    }
    
    KNPhotoBrowser *photoBrowser = [[KNPhotoBrowser alloc] init];
    
    [KNPhotoBrowserConfig share].isNeedCustomActionBar = false;
    
    photoBrowser.delegate = self;
    photoBrowser.itemsArr = browserMessages;
    photoBrowser.placeHolderColor = UIColor.lightTextColor;
    photoBrowser.currentIndex = messageModelIndex;
    photoBrowser.isSoloAmbient = true;//音频模式
    photoBrowser.isNeedPageNumView = false;//分页
    photoBrowser.isNeedRightTopBtn = true;//更多按钮
    photoBrowser.isNeedLongPress = false;//长按
    photoBrowser.isNeedPanGesture = true;//拖拽
    photoBrowser.isNeedPrefetch = true;//预取图像(最大8)
    photoBrowser.isNeedAutoPlay = true;//自动播放
    photoBrowser.isNeedOnlinePlay = false;//在线播放(先自动下载视频)
    
    [photoBrowser present];
}
#pragma mark - KNPhotoBrowserDelegate
//图片浏览右侧按钮点击事件
- (void)photoBrowser:(KNPhotoBrowser *)photoBrowser rightBtnOperationActionWithIndex:(NSInteger)index {
    
    NoaIMChatMessageModel *currentModel = [_currentImageVideoMessageList objectAtIndexSafe:index];
    
    NSString *imageUrl;
    NSString *videoUrl;
    if (currentModel.messageType == CIMChatMessageType_ImageMessage) {
        //图片
        if (![NSString isNil:currentModel.localImgName]) {
            imageUrl = currentModel.localImgName;
        } else {
            imageUrl = [currentModel.imgName getImageFullString];
        }
    }else if (currentModel.messageType == CIMChatMessageType_VideoMessage) {
        //视频
        if (currentModel.localVideoName) {
            //本地视频地址
            NSString *customPath = [NSString stringWithFormat:@"%@-%@", UserManager.userInfo.userUID, self.sessionID];
            videoUrl = [NSString getPathWithVideoName:currentModel.localVideoName CustomPath:customPath];
        }else {
            //网络视频地址
            videoUrl = [currentModel.videoName getImageFullString];
        }
    }
    
    WeakSelf
    NoaPresentItem *saveItem = [NoaPresentItem creatPresentViewItemWithText:LanguageToolMatch(@"保存到手机") textColor:COLOR_11 font:FONTR(17) itemHeight:DWScale(54) backgroundColor:COLORWHITE];
    self.tkThemeChangeBlock = ^(id  _Nullable itself, NSUInteger themeIndex) {
        if (themeIndex == 0) {
            saveItem.textColor = COLOR_11;
            saveItem.backgroundColor = COLORWHITE;
        }else {
            saveItem.textColor = COLORWHITE;
            saveItem.backgroundColor = COLOR_11;
        }
    };
    NoaPresentItem *cancelItem = [NoaPresentItem creatPresentViewItemWithText:LanguageToolMatch(@"取消") textColor:COLOR_99 font:FONTR(17) itemHeight:DWScale(54) backgroundColor:COLORWHITE];
    self.tkThemeChangeBlock = ^(id  _Nullable itself, NSUInteger themeIndex) {
        if (themeIndex == 0) {
            cancelItem.textColor = COLOR_99;
            cancelItem.backgroundColor = COLORWHITE;
        }else {
            cancelItem.textColor = COLOR_99;
            cancelItem.backgroundColor = COLOR_11;
        }
    };
    NoaPresentView *viewAlert = [[NoaPresentView alloc] initWithFrame:CGRectMake(0, 0, DScreenWidth, DScreenHeight) titleItem:nil selectItems:@[saveItem] cancleItem:cancelItem doneClick:^(NSInteger index) {
        if (![NSString isNil:imageUrl]) {
            NSString *customPath = [NSString stringWithFormat:@"%@-%@", UserManager.userInfo.userUID, weakSelf.sessionID];
            [ZTOOL saveImageToAlbumWith:imageUrl Cusotm:customPath];
        }
        if (![NSString isNil:videoUrl]) {
            [weakSelf saveVideoToAlbumWithUrl:videoUrl];
        }
        
    } cancleClick:^{
    }];
    [CurrentVC.view addSubview:viewAlert];
    [viewAlert showPresentView];
}

//保存视频到相册
- (void)saveVideoToAlbumWithUrl:(NSString *)videoUrl {
    [HUD showActivityMessage:LanguageToolMatch(@"正在保存...")];
    //此处的逻辑应该是，先查询本地缓存有没有该视频
    //有的话，直接保存，没有的话先缓存到本地，再保存
    NSString *videoPath = [ZTOOL videoExistsWith:videoUrl];
    if (![NSString isNil:videoPath]) {
        //已有缓存，直接保存
        [ZTOOL saveVideoToAlbumWith:videoPath];
    }else {
        //先下载缓存，再保存
        [ZTOOL downloadVideoWith:videoUrl completion:^(BOOL success, NSString * _Nonnull videoPath) {
            if (success) {
                [ZTOOL saveVideoToAlbumWith:videoPath];
            }
        }];
    }
}


#pragma mark - <<<<<<交互事件>>>>>>
//列表滚动到最底部
- (void)btnBottomClick {
    //列表滚动到最底部
    _btnBottom.hidden = YES;
    [self tableViewScrollToBottom:YES duration:0.25];
}

#pragma mark - 通过点击全局搜索结果进入聊天界面
- (void)clickSearchResultInChatRoomWithMessage:(NoaIMChatMessageModel *)messageModel {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:messageModel.msgID forKey:@"selectMessageID"];
    [dict setValue:@(messageModel.sendTime) forKey:@"selectMessageSendTime"];
    
    dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC));
    dispatch_after(delayTime, dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ChatHistorySelectMessage" object:nil userInfo:dict];
    });
}

#pragma mark - 撤回或者删除了某条消息，并处理引用这条消息的消息里被引用消息展示状态(处理被撤回的消息和引用的消息)
//此消息说明是 消息撤回或者删除时，先找到被撤回或删除的消息，然后在处理引用的消息相关的撤回或删除
- (void)updateDeleteMessageAndRefreshMsgWithOriginalMsg:(NSString *)originalMsgId {
    WeakSelf
    dispatch_async(_chatMessageUpdateQueue, ^{
        
        for (int i = 0; i < weakSelf.messageModels.count; i++) {
            
            NoaMessageModel *tempMessageModel = [weakSelf.messageModels objectAtIndex:i];
            
            if ([originalMsgId isEqualToString:tempMessageModel.message.serviceMsgID]) {
                //UI层删除被撤回的消息
                [weakSelf.messageModels removeObject:tempMessageModel];
            }
            
            if (tempMessageModel.message.referenceMsgId != nil && [tempMessageModel.message.referenceMsgId isEqualToString:originalMsgId]) {
                
                NoaMessageModel *refreshMsg = [[NoaMessageModel alloc] initWithMessageModel:tempMessageModel.message];
                [weakSelf.messageModels replaceObjectAtIndex:i withObject:refreshMsg];
            }
        }
        //处理消息是否显示时间
        [weakSelf computeVisibleTime];
        
        [ZTOOL doInMain:^{
            [weakSelf.baseTableView reloadData];
        }];
    });
}

#pragma mark - 当撤回或者删除了某条消息，那引用这条消息的消息里也要改变被引用消息展示状态(只处理引用消息)
//此方法仅需要处理引用的消息里有撤回或删除的消息，不需要关心被撤回或者删除的消息(比如我撤回或删除消息的时候，我已经知道是哪个消息被撤回或删除了，直接删除该消息，不需要去查找是哪个消息被撤回或者删除了)
- (void)updateRefreshMsgWithOriginalMsg:(NSString *)originalMsgId {
    WeakSelf
    dispatch_async(_chatMessageUpdateQueue, ^{
        
        for (int i = 0; i < weakSelf.messageModels.count; i++) {
            
            NoaMessageModel *msgModel = [weakSelf.messageModels objectAtIndex:i];
            
            if (msgModel.message.referenceMsgId != nil && [msgModel.message.referenceMsgId isEqualToString:originalMsgId]) {
                
                NoaMessageModel *refreshMsg = [[NoaMessageModel alloc] initWithMessageModel:msgModel.message];
                [weakSelf.messageModels replaceObjectAtIndex:i withObject:refreshMsg];
                
                //处理消息是否显示时间
                [weakSelf computeVisibleTime];
                
                [ZTOOL doInMain:^{
                    [weakSelf.baseTableView reloadData];
                }];
            }
        }
    });
}

#pragma mark - 计算每条消息是否显示时间
#pragma mark - Other
//计算每条消息是否显示时间
-(void)computeVisibleTime {
    WeakSelf
    dispatch_async(_chatMessageCalculateTimeQueue, ^{
        NoaMessageModel *temoMsgModel;
        long long  prevSendTime = 0;
        for (int i = 0; i < weakSelf.messageModels.count; i++) {
            temoMsgModel = [weakSelf.messageModels objectAtIndex:i];
            if (i==0) {
                //最上面一条消息的时间
                prevSendTime = temoMsgModel.message.sendTime;
                //显示时间
                temoMsgModel.isShowSendTime = YES;
            } else {
                //如果聊天消息是同一天的，不显示间隔的日期
                if ([NoaMessageTimeTool isSameDay:temoMsgModel.message.sendTime Time2:prevSendTime]){
                    //不显示时间
                    temoMsgModel.isShowSendTime = NO;
                } else {
                    //显示时间
                    temoMsgModel.isShowSendTime = YES;
                }
                //上一条消息的发送时间
                prevSendTime = temoMsgModel.message.sendTime;
            }
            //时间设置完成后数据替换
            [weakSelf.messageModels replaceObjectAtIndex:i withObject:temoMsgModel];
        }
    });
}

//如果某条消息增加、删除、撤回等单条消息操作后，只需继续该消息和前一条消息的时间间隔
- (void)computeOneMessageVisibleTimeWithMessage:(NoaMessageModel *)currentMsg currentIndex:(NSInteger)currentIndex {
    if (currentIndex < self.messageModels.count) {
        if (currentIndex == 0) {
            currentMsg.isShowSendTime = YES;
        } else {
            NoaMessageModel *prevMessage = [self.messageModels objectAtIndex:currentIndex - 1];
            //如果聊天消息是同一天的，不显示间隔的日期
            if ([NoaMessageTimeTool isSameDay:currentMsg.message.sendTime Time2: prevMessage.message.sendTime]){
                //不显示时间
                currentMsg.isShowSendTime = NO;
            } else {
                //不显示时间
                currentMsg.isShowSendTime = YES;
            }
        }
        [self.messageModels replaceObjectAtIndex:currentIndex withObject:currentMsg];
    }
}
#pragma mark - 懒加载
//消息列表
- (SyncMutableArray *)messageModels {
    if (!_messageModels) {
        _messageModels = [[SyncMutableArray alloc] init];
    }
    return _messageModels;
}

//多选
- (NoaChatMultiSelectSendHander *)collectionSendHander {
    if (!_collectionSendHander) {
        _collectionSendHander = [[NoaChatMultiSelectSendHander alloc] init];
    }
    return _collectionSendHander;
}

//底部多选控件
- (NoaMessageMultiBottomView *)multiSelectBottomView {
    if (!_multiSelectBottomView) {
        _multiSelectBottomView = [[NoaMessageMultiBottomView alloc] initWithFrame:CGRectMake(0, DScreenHeight - DWScale(56) - DHomeBarH, DScreenWidth, DWScale(56) + DHomeBarH)];
        _multiSelectBottomView.hidden = YES;
        _multiSelectBottomView.delegate = self;
    }
    return _multiSelectBottomView;
}

//选中的消息列表
- (SyncMutableArray *)selectedMsgModels {
    if (!_selectedMsgModels) {
        _selectedMsgModels = [[SyncMutableArray alloc] init];
    }
    return _selectedMsgModels;
}

//- (ZFileNetProgressManager *)fileUploader {
//    if (!_fileUploader) {
//        _fileUploader = [[ZFileNetProgressManager alloc] init];
//    }
//    return _fileUploader;
//}

#pragma mark - life cycle
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
