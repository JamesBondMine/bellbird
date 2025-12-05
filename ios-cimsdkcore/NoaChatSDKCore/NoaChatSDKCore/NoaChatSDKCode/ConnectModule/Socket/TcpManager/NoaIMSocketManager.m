//
//  NoaIMSocketManager.m
//  NoaChatSDKCore
//
//  Created by mac on 2023/5/22.
//

#import "NoaIMSocketManager.h"
#import "LingIMMacorHeader.h"//宏header
#import "FCUUID.h"//获取设备唯一标识
#import "NoaIMManagerTool.h"//工具
#import "NoaIMSocketManagerTool.h"//消息处理工具类
#import "NoaIMDeviceTool.h"
#import <NetworkStatus/NetworkStatus-Swift.h>
#import "NovDecryptorManager.h"
#import <LocalLogLib/LocalLogLib-Swift.h>
#import <Sentry/Sentry.h>
#import "NoaIMSDKManager.h"

// echo 加密
#import "NoaIMSocketManager+EchoEncryption.h"
//
#import "NoaIMSocketManagerTool+LingImTcpReplaceHttp.h"

typedef NS_ENUM(NSInteger, LingIMSocketConnectState) {
    LingIMSocketConnectStateDisconnected,   // 未连接
    LingIMSocketConnectStateConnecting,     // 正在连接
    LingIMSocketConnectStateConnected       // 已连接
};

#define kEncryptionEnabled 1

// Socket日志开关 - 控制本文件中所有CIMLog输出
// Debug模式：可以设置开关，默认开启
// Release模式：强制关闭
#ifdef DEBUG
#define SOCKET_LOG_SWITCH 0
#else
#define SOCKET_LOG_SWITCH 0  // Release模式强制关闭
#endif

// 重定义CIMLog宏，根据开关控制是否输出
#if SOCKET_LOG_SWITCH
// 开关开启时，使用NSLog输出并添加Socket前缀
#undef CIMLog
#define CIMLog(fmt, ...) NSLog(@"[Socket] " fmt, ##__VA_ARGS__)
#else
// 开关关闭时，CIMLog为空操作
#undef CIMLog
#define CIMLog(fmt, ...)
#endif

/// 连接后多久发送第一个协议
static const NSTimeInterval kInitialDelayAfterConnect = 0.1;

/// ECDH交换密钥超时时间
static const NSTimeInterval kKeyExchangeTimeout = 15.0;

@interface NoaIMSocketManager () <GCDAsyncSocketDelegate>

/// 是否是初始化(第一次连接)
@property (nonatomic, assign) BOOL initedSocket;

/// 能否联网
@property (nonatomic, assign) BOOL isReachable;

/// 能否联网的标识，默认为NO。当网络断开时，变为NO；当网络恢复时，变为YES。
@property (nonatomic, assign) BOOL isCanConnectNet;

/// socket 主机 地址
@property (nonatomic, copy) NSString *socketHost;
/// socket 主机 端口
@property (nonatomic, assign) NSInteger socketPort;
/// socket 主机 租户标识
@property (nonatomic, copy) NSString *socketOrgName;

/// socket 用户 id
@property (nonatomic, copy) NSString *socketUserID;
/// socket 用户 token
@property (nonatomic, copy) NSString *socketUserToken;

/// 套接字对象
@property (nonatomic, strong, readwrite) GCDAsyncSocket *gcdSocket;

/// 心跳机制定时器
@property (nonatomic, strong) dispatch_source_t heartTimer;

/// 心跳定时器专用锁（使用 NSLock 性能更好）
@property (nonatomic, strong) NSLock *heartTimerLock;

/// 发送Ping消息后，没有收到Pong响应次数
@property (nonatomic, assign) NSInteger heartNoPongCount;

/// 已重连的次数
@property (nonatomic, assign) NSInteger reconnectCount;

/// socket接收到数据信息
@property (nonatomic, strong) NSMutableData *receiveData;

/// 是否是重连
@property (nonatomic, assign) BOOL isReconnect;

/// 内部连接串行队列，统一所有状态变更，避免竞态
@property (nonatomic, strong) dispatch_queue_t internalQueue;

/// 当前tcp的连接状态
@property (nonatomic, assign) LingIMSocketConnectState connectState;


/// 应用层复用相关属性
@property (nonatomic, strong) NSMutableData *frameBuffer;
@property (nonatomic, strong) dispatch_queue_t frameProcessingQueue;

/// ECDH密钥交换超时检测
@property (nonatomic, strong) dispatch_source_t keyExchangeTimer;

/// 密钥交换处理类
@property (nonatomic, strong) NovDecryptorManager *novDecryptorManager;

@end

@implementation NoaIMSocketManager

#pragma mark - <<<<<<单例>>>>>>
+ (instancetype)sharedTool {
    
    static NoaIMSocketManager *_manager = nil;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        //不能再使用alloc方法，因为已经重写了allocWithZone方法，所以这里要调用父类的方法
        _manager = [[super allocWithZone:NULL] init];

        //默认配置
        [_manager socketDefaultConfig];
        
        //开始网络状态监听
        [_manager startNetworkStatusMonitoring];
    });
    
    return _manager;
}
// 防止外部调用alloc 或者 new
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [NoaIMSocketManager sharedTool];
}
// 防止外部调用copy
- (id)copyWithZone:(nullable NSZone *)zone {
    return [NoaIMSocketManager sharedTool];
}
// 防止外部调用mutableCopy
- (id)mutableCopyWithZone:(nullable NSZone *)zone {
    return [NoaIMSocketManager sharedTool];
}

#pragma mark - socket的用户id
- (NSString *)socketUserID {
    return _socketUserID;
}

#pragma mark - socket的用户token
- (NSString *)socketUserToken {
    return _socketUserToken;
}

#pragma mark - socket 主机 地址
- (NSString *)socketHostValue {
    return _socketHost;
}

#pragma mark - socket 主机 端口
- (NSInteger)socketPortValue {
    return _socketPort;
}

#pragma mark - 清空用户信息
- (void)clearUserInfo {
    _socketUserID = nil;
    _socketUserToken = nil;
}

#pragma mark - 默认配置
- (void)socketDefaultConfig {
    // 每次启动App默认不是重连
    _isReconnect = NO;
    // 心跳无响应次数
    _heartNoPongCount = 0;
    // 重连次数
    _reconnectCount = 0;
    // 初始化接收数据对象
    _receiveData = [[NSMutableData alloc] init];
    // 当前连接状态默认为未连接
    _connectState = LingIMSocketConnectStateDisconnected;
    // tcp连接队列
    _internalQueue = dispatch_queue_create("com.lingim.socket.internal", DISPATCH_QUEUE_SERIAL);
    // 当前网络状态
    _isReachable = [[NetWorkStatusManager shared] getConnectStatus];
    // 应用层复用相关属性初始化
    _frameBuffer = [[NSMutableData alloc] init];
    _frameProcessingQueue = dispatch_queue_create("com.lingim.frame.processing", DISPATCH_QUEUE_SERIAL);
    
    // 心跳定时器专用锁初始化（使用 NSLock，性能更好，便于调试）
    _heartTimerLock = [[NSLock alloc] init];
    _heartTimerLock.name = @"com.lingim.heartTimer.lock";
    
    // 密钥交换相关
    _novDecryptorManager = [[NovDecryptorManager alloc] init];
    
    // 网络连接处理
    [self configureSocketConnect];
}

#pragma mark - 开始网络状态监听
- (void)startNetworkStatusMonitoring {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkChange:) name:NetWorkStatusManager.NetworkStatusChangedNotification object:nil];
}

#pragma mark - 监听网络状态是否可用
- (void)networkChange:(NSNotification *)notification {
    self.isReachable = [[NetWorkStatusManager shared] getConnectStatus];
    [self configureSocketConnect];
}

- (void)configureSocketConnect {
    if (self.isReachable) {
        // 网络现在可用
        self.isCanConnectNet = YES;
        
        // 处理连接
        if (self.initedSocket) {
            // socket配置完成之后的网络状态监听
            CIMLog(@"网络变化，准备重连...");
            [self scheduleReconnectIfNeeded];
        }else {
            // socket没有初始化，开始调用连接
            CIMLog(@"网络变化，正在连接...");
            [self startSocketConnect];
        }
    }else {
        CIMLog(@"网络不可用, 清理数据");
        
        // 网络现在不可用
        self.isCanConnectNet = NO;
        
        // 清理数据
        [self cleanForNetworkLoss];
    }
}

#pragma mark - Connect
- (void)startSocketConnect {
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.internalQueue, ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        
        // 没网不再连接
        if (!self.isCanConnectNet) return;
        
        // 判断tcp连接地址
        if (self.socketHost.length == 0) {
            [Logger error:@"[socket连接] 暂无主机信息，不再连接"];
            
            [self sentryUploadWithEventObj:@{
                @"event" : @"socket连接",
                @"error" : @"暂无主机信息，不再连接",
                @"host" : self.socketHost ? self.socketHost : @"",
                @"port" : @(self.socketPort)
            } errorCode:@""];
            
            return;
        }
        
        // 判断tcp连接状态，正在连接或已连接，避免重复
        if (self.connectState == LingIMSocketConnectStateConnecting ||
            self.connectState == LingIMSocketConnectStateConnected) {
            [Logger info:[NSString stringWithFormat:@"[socket连接] 当前状态为%@，跳过连接",
                          self.connectState == LingIMSocketConnectStateConnecting ? @"正在连接" : @"已连接"]];
            
            return;
        }
        
        // 标记socket已经初始化了
        if (!self.initedSocket) {
            self.initedSocket = YES;
        }
        
        // 重新设置为连接状态(此处手动将连接状态置为正在连接中，是因为连接是在0.1s后)
        [self updateConnectState:LingIMSocketConnectStateConnecting];
        
        // 强制清理旧连接，确保状态一致(如果已经在连接中了，会把连接状态置为没有连接)
        [self forceDisconnectSocket];
        
        // 等待一小段时间确保断开完成
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), self.internalQueue, ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;
            
            // 重新设置为连接状态
            [self updateConnectState:LingIMSocketConnectStateConnecting];
            
            // 通知代理开始连接了
            [SOCKETMANAGERTOOL cimConnecting];
            
            NSError *error = nil;
            BOOL ok = [self.gcdSocket connectToHost:self.socketHost
                                             onPort:self.socketPort
                                        withTimeout:LingIMConnectTimeout
                                              error:&error];
            if (!ok || error) {
                [Logger error: [NSString stringWithFormat:@"[socket连接] 参数连接失败，失败信息:%@", error]];
                
                [self sentryUploadWithEventObj:@{
                    @"event" : @"socket连接",
                    @"error" : [NSString stringWithFormat:@"使用参数连接失败，失败信息:%@", error],
                    @"host" : self.socketHost ? self.socketHost : @"",
                    @"port" : @(self.socketPort)
                } errorCode:@""];
                
                [SOCKETMANAGERTOOL cimConnectFailWithError:error];
                [self updateConnectState:LingIMSocketConnectStateDisconnected];
                [self startingSocketReconnect];
                [Logger error:@"[企业号竞速] 通知连接失败"];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"socketECDHDidConnectFailure" object:nil];
            } else {
                [Logger info: @"[socket连接] 参数配置成功，已成功创建连接，等待连接成功"];
            }
        });
    });
}

#pragma mark - Disconnect
- (void)disconnectSocket {
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.internalQueue, ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        
        // 停止心跳机制
        [self stopSocketHeartbeat];
        
        //停止重连机制
        [self stopSocketReconnect];
        
        // 断开连接
        if (self.gcdSocket.isConnected) {
            [Logger info:@"调用disconnectSocket断开"];
            [self.gcdSocket disconnect];
        }
        
        // 更新连接状态
        [self updateConnectState:LingIMSocketConnectStateDisconnected];
    });
}

/// 强制断开Socket连接，用于连接前清理
- (void)forceDisconnectSocket {
    // 强制断开连接，不等待回调
    if (self.gcdSocket.isConnected) {
        [self.gcdSocket disconnectAfterReadingAndWriting];
        [Logger info:@"强制断开旧连接"];
    }
    
    // 重置相关状态
    [self clearKeyExchangeInfo];
    
    // 停止ECDH密钥交换超时定时器
    [self stopKeyExchangeTimer];
    
    
    // 清理应用层复用相关状态
    [self cleanupReceiveBuffers];
}

/// 网络断开时的清理，不触发重连
- (void)cleanForNetworkLoss {
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.internalQueue, ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        
        // 停止心跳机制
        [self stopSocketHeartbeat];
        
        //停止重连机制
        [self stopSocketReconnect];
        
        // 断开连接
        if (self.gcdSocket.isConnected) {
            [Logger info:@"无法连接外网，断开"];
            [self.gcdSocket disconnectAfterReadingAndWriting];
        }
        
        [self updateConnectState:LingIMSocketConnectStateDisconnected];
    });
}

#pragma mark - Reconnect
- (void)scheduleReconnectIfNeeded {
    // 当前连接状态为已连接或者未连接，取消连接
    if (self.connectState == LingIMSocketConnectStateConnected ||
        self.connectState == LingIMSocketConnectStateConnecting) {
        return;
    }
    [self startingSocketReconnect];
}

- (void)startingSocketReconnect {
    // 如果不能重连，禁止重连，不再走重连方法
    if (!self.isCanReconnect) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.internalQueue, ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        
        // 无网直接取消连接
        if (!self.isCanConnectNet) return;
        
        // 当前连接状态为已连接或者正在连接，取消重连
        if (self.connectState == LingIMSocketConnectStateConnected ||
            self.connectState == LingIMSocketConnectStateConnecting) {
            CIMLog(@"当前状态为%@，跳过重连",
                   self.connectState == LingIMSocketConnectStateConnecting ? @"正在连接" : @"已连接");
            return;
        }
        
        // 增加重连次数
        self.reconnectCount++;
        [Logger info:[NSString stringWithFormat:@"[socket连接] 开始重连... 第%ld次", (long)self.reconnectCount]];

        // 开启了节点竞速，告知业务层进行竞速，然后开启重连机制
        [SOCKETMANAGERTOOL cimDisconnect];
        
        // 延迟重连，避免立即重连
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), self.internalQueue, ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (self && self.connectState == LingIMSocketConnectStateDisconnected) {
                // 检查是否有最优节点可用
                if ([self hasOptimalServerAvailable]) {
                    [Logger info:@"[socket连接] 检测到当前有最优节点可用"];
                    
                    [self connectWithOptimalServer];
                } else {
                    [Logger info:@"[socket连接] IMSocket没有最优节点，使用原有连接逻辑"];
                    
                    [self startSocketConnect];
                }
            }
        });
    });
}

#pragma mark - Socket连接状态维护 State

/// 当前socket连接状态
- (BOOL)currentSocketConnectStatus {
    return self.connectState == LingIMSocketConnectStateConnected;
}

/// 是否交换ecdh key成功
- (BOOL)isExchangeEcdhKeySuccess {
    return self.isECDHCompleted;
}

/// 更新socket连接状态
/// - Parameter state: 当前sock连接状态
- (void)updateConnectState:(LingIMSocketConnectState)state {
    if (_connectState == state) return;
    _connectState = state;
}

#pragma mark - <<<<<<业务>>>>>>
#pragma mark - 配置socket用户信息(此方法在用户名、密码输入后调用)
- (void)configureSocketUser:(NoaIMSocketUserOptions *)userOptions {
    if (!userOptions) {
        return;
    }
    [Logger info:[NSString stringWithFormat:@"[socket连接] 设置了用户 userId = %@, token = %@", userOptions.userID, userOptions.userToken]];
    
    BOOL isUserChange = NO;
    NSString *newUserId = userOptions.userID ? userOptions.userID : @"";
    NSString *newUserToken = userOptions.userToken ? userOptions.userToken : @"";
    
    if (![_socketUserID isEqualToString:newUserId] || ![_socketUserToken isEqualToString:newUserToken]) {
        [Logger info:[NSString stringWithFormat:@"[socket连接] configureSocketUser:(LingIMSocketUserOptions *)userOptions 用户id、用户token出现差异，当前连接的userID = %@，token = %@", newUserId, newUserToken]];
        
        isUserChange = YES;
        _socketUserID = newUserId;
        _socketUserToken = newUserToken;
    }
    
    if (!isUserChange) {
        return;
    }
    
    // 设置成功用户信息后，发送用户信息认证(认证内部有条件判断，此处无需判断)
    [self authSocketUser];
}

#pragma mark - 配置socket网络信息
- (void)configureSocketHost:(NoaIMSocketHostOptions *)hostOptions {
    if (!hostOptions) {
        return;
    }
    
    if (!self.isCanReconnect) {
        self.isCanReconnect = YES;
    }
    
    [Logger info:[NSString stringWithFormat:@"[socket连接] 设置了socket地址 host = %@, port = %ld", hostOptions.socketHost, hostOptions.socketPort]];
    
    BOOL isNeedCreateNewConnect = NO;
    NSString *newHost = hostOptions.socketHost ? hostOptions.socketHost : @"";
    NSInteger newPort = hostOptions.socketPort;
    
    if (![_socketHost isEqualToString:newHost] || _socketPort != newPort) {
        [Logger info:[NSString stringWithFormat:@"[socket连接] !!!!!!!!!!! configSocketHost:(LingIMSocketHostOptions *)hostOptions user:(LingIMSocketUserOptions *)userOptions 地址与端口号出现差异 当前连接的ip = %@,端口号 = %ld, 新的ip = %@，新的端口号 = %ld", _socketHost, _socketPort, newHost, newPort]];
        
        isNeedCreateNewConnect = YES;
        _socketHost = newHost;
        _socketPort = newPort;
    }
    
    _socketOrgName = hostOptions.socketOrgName;
    if (!isNeedCreateNewConnect && self.connectState != LingIMSocketConnectStateDisconnected) {
        // 为什么连接的ip端口号，且忽略未连接状态:因为企业号配置页面，需要断开socket连接，并且不能重连
        if ([self currentSocketConnectStatus]) {
            // 已连接,且ip与端口号一致,直接通知上层连接成功
            [Logger info:@"[企业号竞速] 企业号竞速成功，通知连接成功"];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"socketECDHDidConnectSuccese" object:nil];
        }else {
            [Logger error:[NSString stringWithFormat:@"[企业号竞速] 正在连接中,且ip与端口号一致,暂不处理，等待连接回调发送通知，当前连接状态:%ld, 是否支持重连:%@", (long)self.connectState, self.isCanReconnect ? @"支持" : @"禁止"]];
        }
        return;
    }
    
    if ([self currentSocketConnectStatus]) {
        [Logger info:@"[socket连接] configSocketHost:(LingIMSocketHostOptions *)hostOptions user:(LingIMSocketUserOptions *)userOptions 当前已连接，但是地址与端口号出现差异，需要先断开后连接\n正在断开中"];
        
        // 如果当前socket已经连接成功，直接断开连接，通过disconnect触发diddisconnect回调，然后重新竞速连接
        [self disconnectSocket];
        
    }
    [Logger info:@"[socket连接] configSocketHost:(LingIMSocketHostOptions *)hostOptions user:(LingIMSocketUserOptions *)userOptions 已断开，正在连接"];
    
    // 当前socket已断开，直接连接
    [self startSocketConnect];
}

/// 恢复是否是重连reConnect状态为初始状态
- (void)configSetIsReconenctStatus {
    _isReconnect = NO;
}

#pragma mark - 鉴权socket用户
- (void)authSocketUser {
    [Logger info:@"开始发送用户鉴权信息..."];
    
    if (!self.isECDHCompleted) {
        [Logger error:@"[用户鉴权] 用户鉴权信息未发送，原因:ecdh密钥交换未成功"];
        return;
    }
    
    if (!self.novDecryptorManager.shareKey || self.novDecryptorManager.shareKey.length == 0) {
        [Logger error:@"[用户鉴权] 用户鉴权信息未发送，原因: shareKey未生成"];
        return;
    }
    
    if (!_socketUserID || _socketUserID.length == 0) {
        [Logger error:@"[用户鉴权] 用户信息鉴权未发送，原因:用户id异常"];
        return;
    }
    
    if (!_socketUserToken || _socketUserToken.length == 0) {
        [Logger error:@"[用户鉴权] 用户信息鉴权未发送，原因:用户Token异常"];
        return;
    }
    
    if (!_socketOrgName || _socketOrgName.length == 0) {
        [Logger error:@"[用户鉴权] 用户信息鉴权未发送，原因:_socketOrgName异常"];
        return;
    }
    
    IMAuthMessage *authMessage = [[IMAuthMessage alloc] init];
    authMessage.userId = _socketUserID;//用户ID
    authMessage.token = _socketUserToken;//用户token
    authMessage.orgName = _socketOrgName;//用户租户标识
    authMessage.msgId = [[NoaIMManagerTool sharedManager] getMessageID];//变化的UUID
    authMessage.loginIp = [[NoaIMManagerTool sharedManager] getDevicePublicNetworkIP];//ip地址
    authMessage.deviceType = @"IOS";//设备平台
    authMessage.deviceUuid = [FCUUID uuidForDevice];//固定不变的UUID
    authMessage.platform = @"iOS";
    authMessage.versionNumber = [NoaIMDeviceTool appVersion];//客户端版本号
    
    IMMessage *message = [[IMMessage alloc] init];
    message.dataType = IMMessage_DataType_ImauthMessage;
    message.authMessage = authMessage;
    
    [self sendSocketMessage:message tag:LingIMMessageTag];
    [Logger info:[NSString stringWithFormat:@"[用户鉴权] 发送了用户鉴权信息，等待服务器鉴权响应，userId: %@，token:%@, orgName:%@，msgId:%@，loginIp:%@，deviceType:%@，deviceUuid:%@", authMessage.userId, authMessage.token, authMessage.orgName, authMessage.msgId, authMessage.loginIp, authMessage.deviceType, authMessage.deviceUuid]];
}

#pragma mark - 发送socket消息
- (void)sendSocketMessage:(id)message tag:(NSInteger)messageTag{
    [self sendSocketMessage:message timeOut:LingIMMessageTimeout tag:messageTag];
}

- (void)sendSocketMessage:(id)message
                  timeOut:(NSInteger)timeOut
                      tag:(NSInteger)messageTag {
    if ([message isKindOfClass:[IMMessage class]]) {
        IMMessage *imMsg = (IMMessage *)message;
        if (!self.isECDHCompleted) {
            [Logger error:@"[socket] 消息未发送，原因:ecdh密钥交换未成功"];
            // TODO: 避免对发送的聊天消息进行拦截，导致无法超时
            [SOCKETMANAGERTOOL sendMessageDealWith:imMsg];
            return;
        }
        
        if (!self.novDecryptorManager.shareKey || self.novDecryptorManager.shareKey.length == 0) {
            [Logger error:@"[socket] 消息未发送，原因: shareKey未生成"];
            // TODO: 避免对发送的聊天消息进行拦截，导致无法超时
            [SOCKETMANAGERTOOL sendMessageDealWith:imMsg];
            return;
        }
        
        if (!SOCKETMANAGERTOOL.isAuth) {
            if (imMsg.dataType == IMMessage_DataType_ImchatMessage && imMsg.chatMessage.mType != IMChatMessage_MessageType_HaveReadMessage) {
                // TODO: auth未成功时，聊天消息无法发送，需要对发送的聊天消息进行拦截
                [SOCKETMANAGERTOOL sendMessageDealWith:message];
                return;
            }
        }
        
        //消息转换二进制流
        IMMessage *sendMessage = (IMMessage *)message;
        [Logger verbose:[NSString stringWithFormat:@"[socket] 发送消息中。。。 message = %@", sendMessage]];
        
        // 使用增强帧协议格式进行加密
        NSData *frameData = [self.novDecryptorManager buildEncryptedMessageFrameWithData:[sendMessage delimitedData]];
        if (!frameData) {
            [Logger error:@"[socket] ❌ 消息加密失败，无法发送"];
            return;
        }
        
        // TODO: 确保 writeData 在主队列（delegateQueue）调用 原因：GCDAsyncSocket 的 delegateQueue 是主队列，所有操作应在同一队列
        if ([NSThread isMainThread]) {
            // 已在主线程，直接发送
            [self.gcdSocket writeData:frameData withTimeout:timeOut tag:messageTag];
        } else {
            // 不在主线程，调度到主队列
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.gcdSocket writeData:frameData withTimeout:timeOut tag:messageTag];
            });
        }
        
        //对发送的消息进行超时监听处理
        [SOCKETMANAGERTOOL sendMessageDealWith:sendMessage];
        
    }else {
        [Logger error:@"[socket] ❌ 消息格式错误，发送失败"];
    }
}


#pragma mark - 开始心跳机制(用户鉴权成功后开始)❤️❤️❤️❤️❤️❤️
- (void)startSocketHeartbeat {
    CIMWeakSelf
    
    [_heartTimerLock lock];
    
    if (_heartTimer) {
        CIMLog(@"⚠️ 心跳定时器已存在，跳过创建");
        [_heartTimerLock unlock];
        return;
    }
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    if (!queue) {
        CIMLog(@"❌ 无法获取全局队列");
        [_heartTimerLock unlock];
        return;
    }
    
    @try {
        _heartTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        if (!_heartTimer) {
            CIMLog(@"❌ 心跳定时器创建失败");
            [_heartTimerLock unlock];
            return;
        }
        
        // 设置事件处理
        dispatch_source_set_event_handler(_heartTimer, ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) {
                CIMLog(@"⚠️ 心跳定时器回调时对象已释放");
                return;
            }
            
            if (!self->_heartTimer) {
                CIMLog(@"⚠️ 心跳定时器已失效");
                return;
            }
            
            @try {
                // 执行心跳
                [self sendSocketPingMessage];
                
                // 每次执行后立即更新下次执行时间
                [self updateNextHeartbeatTime];
                
            } @catch (NSException *exception) {
                CIMLog(@"❌ 心跳处理异常: %@", exception);
                [self stopSocketHeartbeat];
            }
        });
        
        // 启动定时器，初始延迟为0（立即执行）
        dispatch_source_set_timer(_heartTimer,
                                  DISPATCH_TIME_NOW,
                                  DISPATCH_TIME_FOREVER,
                                  0);
        
        dispatch_resume(_heartTimer);
        CIMLog(@"✅ 心跳定时器启动成功，立即执行第一次心跳");
        
    } @catch (NSException *exception) {
        CIMLog(@"❌ 心跳定时器创建异常: %@", exception);
        if (_heartTimer) {
            dispatch_source_cancel(_heartTimer);
            _heartTimer = nil;
        }
        [_heartTimerLock unlock];
        return;
    }
    
    [_heartTimerLock unlock];
}

// 修改后的方法：每次执行后更新下次时间
- (void)updateNextHeartbeatTime {
    [_heartTimerLock lock];
    
    // 保存本地副本，防止多线程竞态条件
    dispatch_source_t localTimer = _heartTimer;
    if (!localTimer) {
        CIMLog(@"⚠️ 心跳定时器不存在，无法更新时间");
        [_heartTimerLock unlock];
        return;
    }
    
    @try {
        // 计算下次随机间隔
        int min = (int)(30 * 0.85);  // 51s
        int max = (int)(30 * 1.25);  // 75s
        
        NSTimeInterval randomInterval = min + arc4random_uniform(max - min + 1);
        
        // 从当前时间开始计算下次执行时间
        dispatch_time_t nextTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(randomInterval * NSEC_PER_SEC));
        
        // 使用本地副本更新定时器，防止竞态
        dispatch_source_set_timer(localTimer,
                                  nextTime,
                                  DISPATCH_TIME_FOREVER,
                                  0);
        
#ifdef DEBUG
        CIMLog(@"下次心跳将在 %.0f 秒后执行", randomInterval);
#endif
        
    } @catch (NSException *exception) {
        CIMLog(@"❌ 更新心跳时间异常: %@", exception);
        // 异常情况下使用默认间隔，仍使用本地副本
        dispatch_time_t defaultTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC));
        dispatch_source_set_timer(localTimer, defaultTime, DISPATCH_TIME_FOREVER, 0);
    }
    
    [_heartTimerLock unlock];
}

#pragma mark - 发送心跳消息❤️❤️❤️❤️❤️❤️
- (void)sendSocketPingMessage {
    if (!self.isECDHCompleted) {
        CIMLog(@"心跳消息未发送，原因:ecdh密钥交换未成功");
        return;
    }
    
    if (!self.novDecryptorManager.shareKey || self.novDecryptorManager.shareKey.length == 0) {
        CIMLog(@"心跳消息未发送，原因: shareKey未生成");
        return;
    }
    
    if (self.connectState != LingIMSocketConnectStateConnected) return;
    
    if (_heartNoPongCount >= LingIMHeartFailureCount) {
        
        //如果服务器长时间不响应心跳，则应执行重连机制
        [self disconnectSocket];
        
        CIMLog(@"==========startingSocketReconnect");
        
        //重连机制(此处不需要给网络监听时间)
        [self startingSocketReconnect];
        
        [SOCKETMANAGERTOOL cimConnectFailWithError:nil];
        
        return;
    }
    
    //自增一次
    _heartNoPongCount++;
    
    //配置Ping消息
    IMPingMessage *pingMessage = [[IMPingMessage alloc] init];
    pingMessage.userId = _socketUserID.length == 0 ? @"" : _socketUserID;
    pingMessage.msgId = [[NoaIMManagerTool sharedManager] getMessageID];
    //配置消息
    IMMessage *message = [[IMMessage alloc] init];
    message.dataType = IMMessage_DataType_ImpingMessage;
    message.pingMessage = pingMessage;
    int randomNumber = 10 + arc4random_uniform(991);
    //发送心跳消息
    [self sendSocketMessage:message tag:randomNumber];
    
    CIMLog(@"发送Ping消息");
}

#pragma mark - 停止心跳机制❤️❤️❤️❤️❤️❤️
- (void)stopSocketHeartbeat {
    [_heartTimerLock lock];
    if (_heartTimer) {
        dispatch_source_cancel(_heartTimer);
        _heartTimer = nil;
        CIMLog(@"✅ 心跳定时器已停止");
    }
    [_heartTimerLock unlock];
}

#pragma mark - 重置未收到Pong响应次数❤️❤️❤️❤️❤️❤️
- (void)resetSocketHeartNoPongCount {
    _heartNoPongCount = 0;
}

/// 清理接收缓冲区
- (void)cleanupReceiveBuffers {
    // 清理主接收缓冲区
    if (_receiveData.length > 0) {
        CIMLog(@"[重连清理] 清理主接收缓冲区，原长度:%lu字节", (unsigned long)_receiveData.length);
        [_receiveData setLength:0];
    }
    
    // 清理帧缓冲区
    if (_frameBuffer.length > 0) {
        CIMLog(@"[重连清理] 清理帧缓冲区，原长度:%lu字节", (unsigned long)_frameBuffer.length);
        [_frameBuffer setLength:0];
    }
}

#pragma mark - 停止重连机制🔗🔗🔗🔗🔗🔗
- (void)stopSocketReconnect {
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.internalQueue, ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        
        //取消所有的延迟调用
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        self.reconnectCount = 0;
    });
}

#pragma mark - 处理接收到的数据信息
- (void)dealReceiveData:(int32_t)headLength contentLength:(int32_t)contentLength {
    // 检查范围是否越界
    if (headLength + contentLength > _receiveData.length) {
        CIMLog(@"数据越界");
        return;
    }
    //本次解析data的范围
    NSRange range = NSMakeRange(0, headLength + contentLength);
    //本次解析的data
    NSData *data = [_receiveData subdataWithRange:range];
    
    GPBCodedInputStream *inputStream = [GPBCodedInputStream streamWithData:data];
    
    NSError *error;
    IMMessage *obj = [IMMessage parseDelimitedFromCodedInputStream:inputStream extensionRegistry:nil error:&error];
    
    if (!error){
        //保存解析正确的模型对象
        if (obj) {
            CIMLog(@"[TCP请求追踪] 📨 成功解析消息，类型:%d", obj.dataType);
            [SOCKETMANAGERTOOL receiveMessageDealWith:obj];
        }
        //移出已经解析过的data - 增加防越界判断
        if (range.location + range.length <= _receiveData.length) {
            [_receiveData replaceBytesInRange:range withBytes:NULL length:0];
        }
    } else {
        //移出已经解析过的data - 增加防越界判断
        if (range.location + range.length <= _receiveData.length) {
            [_receiveData replaceBytesInRange:range withBytes:NULL length:0];
        }
        CIMLog(@"[TCP请求追踪] ❌ 消息解析失败: %@", error);
        return;
    }

    
    if (_receiveData.length < 1) return;
    
    //对于粘包情况下被合并的多条消息，循环递归直至解析完所有消息
    headLength = 0;
    contentLength = [[NoaIMManagerTool sharedManager] getMessageContentLenght:_receiveData withHeaderLength:&headLength];
    
    
    //实际包不足解析，继续接收下一个包
    if (headLength + contentLength > _receiveData.length) return;
    
    
    //继续解析下一条
    [self dealReceiveData:headLength contentLength:contentLength];
}

#pragma mark - GET
- (GCDAsyncSocket *)gcdSocket {
    if (!_gcdSocket) {
        _gcdSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        _gcdSocket.IPv4Enabled = YES;
        _gcdSocket.IPv6Enabled = YES;
        _gcdSocket.IPv4PreferredOverIPv6 = NO;
    }
    return _gcdSocket;
}

#pragma mark - 网络质量检测相关方法

/// 检查是否有最优节点可用
- (BOOL)hasOptimalServerAvailable {
    // 检查代理对象是否存在
    if (!self.hasOptimalServerAvailableBlock) {
        return NO;
    }
    return self.hasOptimalServerAvailableBlock();
}

/// 获取最优服务器节点信息
- (NSDictionary *)getOptimalServerInfo {
    if (!self.getOptimalServerInfoBlock) {
        return nil;
    }
    // 如果没有实现hasOptimalServerAvailable方法，则通过getOptimalServerInfo来判断
    NSDictionary *serverInfo = self.getOptimalServerInfoBlock();
    return serverInfo;
}

/// 使用最优节点进行连接
- (void)connectWithOptimalServer {
    NSDictionary *serverInfo = [self getOptimalServerInfo];
    if (!serverInfo) {
        [Logger info:@"[网络检测] 没有可用的最优节点，使用原有连接逻辑"];
        [self startSocketConnect];
        return;
    }
    
    NSString *ip = serverInfo[@"ip"];
    NSNumber *portNumber = serverInfo[@"port"];
    
    if (!ip || ip.length == 0 || !portNumber || portNumber.integerValue <= 0) {
        [Logger info:@"[网络检测] 最优节点信息无效，使用原有连接逻辑"];
        [self startSocketConnect];
        return;
    }
    
    NSInteger port = portNumber.integerValue;
    [Logger info:[NSString stringWithFormat:@"[网络检测] 使用最优节点连接:ip = %@, port = %ld", ip, (long)port]];
    
    // 更新socket连接信息
    self.socketHost = ip;
    self.socketPort = port;

    // 开始连接
    [self startSocketConnect];
}

#pragma mark - 销毁
- (void)dealloc {
    [self stopSocketHeartbeat];
    [self stopSocketReconnect];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - <GCDAsyncSocketDelegate>
//socket连接成功的回调
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    [Logger info:[NSString stringWithFormat:@"[socket] 收到连接成功回调(建立socket连接)，地址：%@端口：%u", host, port]];

    // 延迟一点时间确保连接完全建立
    if (kEncryptionEnabled) {
        if (self.isKeyExchangeInProgress) {
            return;
        }
        self.isKeyExchangeInProgress = YES;
        [Logger info:@"[socket] socket连接成功，准备启动ECDH密钥交换"];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kInitialDelayAfterConnect * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            // 连接成功后，开始读取数据
            [self.gcdSocket readDataWithTimeout:-1 tag:0];
            
            // 启动ECDH密钥交换超时定时器
            [self startKeyExchangeTimer];
            
            // 启动ECDH密钥交换
            [self startKeyExchangeProcess];
        });
    }
}

//socket连接失败的回调
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    if (err) {
        [Logger info:[NSString stringWithFormat:@"[socket] 断开了连接，错误码:%ld，原因:%@", (long)err.code, err]];
        
        [self sentryUploadWithEventObj:@{
            @"event" : @"socket连接",
            @"error" : [NSString stringWithFormat:@"socketDidDisconnect回调断开了连接，原因:%@", err],
            @"host" : self.socketHost ? self.socketHost : @"",
            @"port" : @(self.socketPort)
        } errorCode:@""];
        
    }else {
        [Logger info:@"[socket] 断开了连接，原因:客户端主动断开"];
        
        [self sentryUploadWithEventObj:@{
            @"event" : @"socket连接",
            @"error" : @"socketDidDisconnect断开了连接，原因:客户端主动断开",
            @"host" : self.socketHost ? self.socketHost : @"",
            @"port" : @(self.socketPort)
        } errorCode:@""];
    }
    
    [Logger error:@"[企业号竞速] socketDidDisconnect断开连接"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"socketECDHDidConnectFailure" object:nil];
    
    // 更新连接状态
    [self updateConnectState:LingIMSocketConnectStateDisconnected];
    
    // 清理相关状态
    [self clearKeyExchangeInfo];
    
    // 停止ECDH密钥交换超时定时器
    [self stopKeyExchangeTimer];
    
    // 清理缓存数据
    [self cleanupReceiveBuffers];
    
    // 停止心跳和重连机制
    [self stopSocketHeartbeat];
    [self stopSocketReconnect];
    
    // 通知上层连接断开了
    [SOCKETMANAGERTOOL cimConnectFailWithError:err];
    
    // 重连机制(给网络监听一点时间)
    [self startingSocketReconnect];
}

//socket接收到数据
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    CIMLog(@"[TCP请求追踪] socket:接收到数据，数据标识:%ld，数据长度:%lu字节", tag, (unsigned long)data.length);
    
    // 数据有效性检查
    if (!data || data.length == 0) {
        CIMLog(@"[TCP请求追踪] ⚠️ 接收到空数据，继续读取");
        [sock readDataWithTimeout:-1 tag:0];
        return;
    }
    
    // 如果需要支持ecdh且当前未完成，则不处理其他数据
    if (!self.isECDHCompleted && kEncryptionEnabled) {
        // 此时没有拿到服务器公钥，则不处理其他数据，但要发送心跳保活
        [self startSocketHeartbeat];
        BOOL isGetServerPublicKeySuccess = [self.novDecryptorManager parseServerPublicKeyMessageSync:data];
        if (isGetServerPublicKeySuccess) {
            [Logger info:@"[Socket-ECDH] 获取服务器公钥成功，开始生成共享密钥..."];
            
            BOOL isGetShareKeySuccess = [self.novDecryptorManager generateSharedSecret];
            if (isGetShareKeySuccess) {
                [Logger info:@"[Socket-ECDH] 生成共享密钥成功！ECDH密钥交换完成"];
                
                // 标记ECDH完成↓
                self.isKeyExchangeInProgress = NO;
                self.isECDHCompleted = YES;
                
                // 停止ECDH密钥交换超时定时器
                [self stopKeyExchangeTimer];
                // 标记ECDH完成↑
                
                // 标记链接成功(为什么不在didConnectToHost方法中调用呢？因为连接成功，不代表真正的链接成功，只有ecdh交换密钥后，才是真正的链接成功)
                // 进入已连接状态↓
                [self updateConnectState:LingIMSocketConnectStateConnected];
                
                if (self.isReconnect) {
                    // 如果是重连成功，走重连成功的逻辑
                    [SOCKETMANAGERTOOL cimReConnectSuccess];
                }
                
                // 连接成功的代理回调
                [SOCKETMANAGERTOOL cimConnectSuccess];
                
                if (!self.isReconnect) {
                    self.isReconnect = YES;
                }
                
                // 重置重连次数
                self.reconnectCount = 0;
                
                //3.停止重连机制(如果当前有的话)
                [self stopSocketReconnect];
                // 进入已连接状态↑
                
                // 发送用户鉴权信息(鉴权成功后，开始心跳机制)
                [self authSocketUser];
                
                // 发送缓存接口(仅限短连接转长连接的)
                [SOCKETMANAGERTOOL sendAllCacheRequest];
                
                [Logger info:@"[企业号竞速] ECDH交换,通知连接成功"];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"socketECDHDidConnectSuccese" object:nil];
                
                //持续获取消息，需要调用此方法(因为socket就是这么设计的)
                [_gcdSocket readDataWithTimeout:-1 tag:0];
                return;
            }else {
                [Logger error:@"[Socket-ECDH] 生成共享密钥失败，开始断开重连..."];
                
                [self sentryUploadWithEventObj:@{
                    @"event" : @"socket连接 - ECDH",
                    @"error" : @"生成共享密钥失败，开始断开重连...",
                    @"host" : self.socketHost ? self.socketHost : @"",
                    @"port" : @(self.socketPort)
                } errorCode:@""];
                
                [self handleKeyExchangeFailure];
                return;
            }
        }else {
            [Logger error:@"[Socket-ECDH] 获取服务器公钥失败，开始断开重连..."];
            
            [self sentryUploadWithEventObj:@{
                @"event" : @"socket连接 - ECDH",
                @"error" : @"获取服务器公钥失败，开始断开重连...",
                @"host" : self.socketHost ? self.socketHost : @"",
                @"port" : @(self.socketPort)
            } errorCode:@""];
            
            [self handleKeyExchangeFailure];
            return;
        }
    }
    
    [self processEnhancedFrameProtocolData:data];
    
    // 持续获取消息，需要调用此方法(因为socket就是这么设计的)
    [sock readDataWithTimeout:-1 tag:0];
}

#pragma mark - 增强帧协议数据处理

/// 处理协议数据
/// @param data 接收到的原始数据
- (void)processEnhancedFrameProtocolData:(NSData *)data {
    if (!data || data.length == 0) {
        CIMLog(@"[帧协议] ❌ 接收数据为空");
        return;
    }
    
    // 将新数据添加到缓冲区
    [self.frameBuffer appendData:data];
    CIMLog(@"[帧协议] 📥 数据已添加到缓冲区，当前长度:%lu字节", (unsigned long)self.frameBuffer.length);
    
    // 循环处理缓冲区中的数据
    [self processFrameBuffer];
}

/// 处理帧缓冲区中的数据
- (void)processFrameBuffer {
    while (self.frameBuffer.length >= MESSAGE_FRAME_HEADER_SIZE) {
        // 查找消息头
        NSUInteger headerPosition = [self findMessageFrameHeader];
        
        if (headerPosition == NSNotFound) {
            // 未找到有效的消息头，逐字节移动查找
            if (self.frameBuffer.length > 1) {
                // 移除第一个字节，继续查找
                [self.frameBuffer replaceBytesInRange:NSMakeRange(0, 1) withBytes:NULL length:0];
                CIMLog(@"🔄 未找到有效消息头，移除1字节继续查找，剩余%lu字节", (unsigned long)self.frameBuffer.length);
                // 继续循环处理
                continue;
            } else {
                // 缓冲区只剩1字节或为空，无法继续查找
                CIMLog(@"🔄 缓冲区数据不足，等待更多数据");
                break;
            }
        }
        
        // 如果消息头不在开头，丢弃消息头之前的数据
        if (headerPosition > 0) {
            NSData *validData = [self.frameBuffer subdataWithRange:NSMakeRange(headerPosition, self.frameBuffer.length - headerPosition)];
            // ✅ 改进：使用 replaceBytesInRange 代替 setLength:0 + appendData，避免中间状态
            if (validData && validData.length > 0) {
                [self.frameBuffer replaceBytesInRange:NSMakeRange(0, headerPosition) withBytes:NULL length:0];
                CIMLog(@"🔄 消息头不在开头，丢弃前%lu字节数据", (unsigned long)headerPosition);
            } else {
                // 如果没有有效数据，直接清空
                [self.frameBuffer setLength:0];
                CIMLog(@"⚠️ 移除无效数据后缓冲区为空");
                break;
            }
        }
        
        // 尝试解析完整的消息帧
        NSData *completeFrame = [self extractCompleteFrame];
        if (completeFrame) {
            // 成功提取到完整帧，进行解密处理
            [self decryptAndProcessFrame:completeFrame];
        } else {
            // 数据不完整，等待更多数据
            CIMLog(@"🔄 消息数据不完整，等待更多数据中....");
            break;
        }
    }
    
    // 添加退出循环的日志
    if (self.frameBuffer.length < MESSAGE_FRAME_HEADER_SIZE) {
        CIMLog(@"⚠️ 缓冲区数据不足，退出处理");
    }
}

/// 查找消息帧头位置
/// @return 消息帧头的位置，如果未找到返回NSNotFound
- (NSUInteger)findMessageFrameHeader {
    if (self.frameBuffer.length < MESSAGE_FRAME_HEADER_SIZE) {
        return NSNotFound;
    }
    
    // 检查 frameBuffer.bytes 是否为 NULL
    const uint8_t *bytes = (const uint8_t *)self.frameBuffer.bytes;
    if (!bytes) {
        CIMLog(@"❌ [帧协议] frameBuffer.bytes 为 NULL，length=%lu", (unsigned long)self.frameBuffer.length);
        return NSNotFound;
    }
    
    NSUInteger dataLength = self.frameBuffer.length;
    
    // 获取期望的帧头标识（AES密钥的前8字节）- 使用安全方法
    NSData *expectedFrameIdentifier = [self.novDecryptorManager getFrameIdentifier];
    if (!expectedFrameIdentifier) {
        CIMLog(@"❌ 无法获取帧标识符，shareKey未准备好");
        return NSNotFound;
    }
    
    // 检查 expectedFrameIdentifier.bytes 是否为 NULL
    const uint8_t *expectedBytes = (const uint8_t *)expectedFrameIdentifier.bytes;
    if (!expectedBytes || expectedFrameIdentifier.length < 8) {
        CIMLog(@"❌ [帧协议] expectedFrameIdentifier.bytes 为 NULL 或长度不足，length=%lu", (unsigned long)expectedFrameIdentifier.length);
        return NSNotFound;
    }
    
    // 搜索帧头标识
    for (NSUInteger i = 0; i <= dataLength - MESSAGE_FRAME_HEADER_SIZE; i++) {
        // 比较帧头标识（前8字节）
        BOOL isHeaderMatch = YES;
        for (NSUInteger j = 0; j < 8; j++) {
            if (bytes[i + j] != expectedBytes[j]) {
                isHeaderMatch = NO;
                break;
            }
        }
        
        if (isHeaderMatch) {
            // 验证消息体长度字段的合理性
            uint32_t messageBodyLength = CFSwapInt32BigToHost(*(uint32_t *)(bytes + i + 8));
            if (messageBodyLength > 0) { // 合理的消息体长度范围
                CIMLog(@"✅ 找到有效消息头，位置:%lu，消息体长度:%u", (unsigned long)i, messageBodyLength);
                return i;
            }
        }
    }
    
    CIMLog(@"❌ 未找到有效消息头， %@", self.frameBuffer);
    return NSNotFound;
}

/// 提取完整的消息帧
/// @return 完整的消息帧数据，如果数据不完整返回nil
- (NSData *)extractCompleteFrame {
    if (self.frameBuffer.length < MESSAGE_FRAME_HEADER_SIZE) {
        return nil;
    }
    
    // 检查 frameBuffer.bytes 是否为 NULL
    const uint8_t *bytes = (const uint8_t *)self.frameBuffer.bytes;
    if (!bytes) {
        CIMLog(@"❌ [帧协议] extractCompleteFrame: frameBuffer.bytes 为 NULL，length=%lu", (unsigned long)self.frameBuffer.length);
        return nil;
    }
    
    // 读取消息体长度
    uint32_t messageBodyLength = CFSwapInt32BigToHost(*(uint32_t *)(bytes + 8));
    
    // 计算完整帧的长度：消息头 + 消息体 + 扰乱数据
    // 扰乱数据长度 = 总数据长度 - 消息头长度 - 消息体长度
    NSUInteger totalFrameLength = MESSAGE_FRAME_HEADER_SIZE + messageBodyLength;
    
    // 检查是否有足够的数据
    if (self.frameBuffer.length < totalFrameLength) {
        CIMLog(@"⏳ 数据不完整，需要%lu字节，当前有%lu字节",
               (unsigned long)totalFrameLength, (unsigned long)self.frameBuffer.length);
        return nil;
    }
    
    // 提取完整帧数据
    NSData *completeFrame = [self.frameBuffer subdataWithRange:NSMakeRange(0, totalFrameLength)];
    
    // 从缓冲区中移除已处理的数据
    [self.frameBuffer replaceBytesInRange:NSMakeRange(0, totalFrameLength) withBytes:NULL length:0];
    
    CIMLog(@"📦 提取完整帧，长度:%lu字节", (unsigned long)completeFrame.length);
    return completeFrame;
}

/// 解密并处理消息帧
/// @param frameData 完整的消息帧数据
- (void)decryptAndProcessFrame:(NSData *)frameData {
    if (!frameData || frameData.length == 0) {
        CIMLog(@"❌ 消息帧数据为空");
        return;
    }
    
    CIMLog(@"🔓 开始解密消息帧，长度:%lu字节", (unsigned long)frameData.length);
    
    // 使用增强帧协议解密
    NSData *decryptedData = [self.novDecryptorManager parseEnhancedFrameProtocolMessage:frameData];
    
    if (decryptedData) {
        CIMLog(@"✅ 消息解密成功，解密后长度:%lu字节", (unsigned long)decryptedData.length);
        
        // 将解密后的数据添加到接收缓冲区进行处理
        [self appendToReceiveBuffer:decryptedData];
        
        // 处理接收缓冲区中的数据
        [self processReceiveBuffer];
    } else {
        CIMLog(@"❌ 消息解密失败，忽略当前帧");
        // 解密失败时，继续处理缓冲区中的下一个消息
        [self processFrameBuffer];
    }
}

#pragma mark - 接收缓冲区管理

- (void)appendToReceiveBuffer:(NSData *)data {
    if (!data || data.length == 0) {
        return;
    }
    
    [_receiveData appendData:data];
    CIMLog(@"[TCP请求追踪] 📥 数据已添加到接收缓冲区，当前缓冲区大小:%lu字节", (unsigned long)_receiveData.length);
}

- (void)processReceiveBuffer {
    if (_receiveData.length < 1) {
        return;
    }
    
    // 循环处理缓冲区中的所有完整消息
    while (_receiveData.length > 0) {
        // 获取消息头长度
        int32_t headLength = 0;
        int32_t contentLength = [[NoaIMManagerTool sharedManager] getMessageContentLenght:_receiveData withHeaderLength:&headLength];
        
        // 检查数据完整性
        if (contentLength < 1 || headLength < 0) {
            CIMLog(@"[TCP请求追踪] ⚠️ 消息头解析失败，清空缓冲区");
            [_receiveData setLength:0];
            break;
        }
        
        // 检查是否有完整的消息
        if (headLength + contentLength > _receiveData.length) {
            CIMLog(@"[TCP请求追踪] ⏳ 数据包不完整，等待更多数据。需要:%d字节，当前有:%lu字节",
                   headLength + contentLength, (unsigned long)_receiveData.length);
            break;
        }
        
        // 处理完整的消息
        [self dealReceiveData:headLength contentLength:contentLength];
    }
}

#pragma mark - 密钥交换方法

- (void)startKeyExchangeProcess {
    [Logger info:[NSString stringWithFormat:@"[Socket-ECDH] startKeyExchangeProcess 开始 [当前线程: %@]", [NSThread isMainThread] ? @"主线程" : @"后台线程"]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [Logger info:@"[Socket-ECDH] 开始ECDH密钥交换流程 [后台队列]"];
        
        [self.novDecryptorManager generateKeyPairWithComplete:^(SecKeyRef  _Nonnull publicKey, SecKeyRef  _Nonnull privateKey) {
            if (!publicKey || !privateKey) {
                [Logger error:@"[Socket-ECDH] ❌ 生成密钥对失败，立即断开重连"];
                
                [self sentryUploadWithEventObj:@{
                    @"event" : @"socket连接 - ECDH",
                    @"error" : @"生成密钥对失败，立即断开重连",
                    @"host" : self.socketHost ? self.socketHost : @"",
                    @"port" : @(self.socketPort)
                } errorCode:@""];
                
                [self handleKeyExchangeFailure];
                return;
            }
            
            [Logger info:@"[Socket-ECDH] 密钥对生成成功 [后台队列]"];
            
            NSData *publicKeyBase64Data = [self.novDecryptorManager secKeyRefToData:publicKey];
            NSData *sendData = [self.novDecryptorManager buildServerPublicKeyRequestMessage:publicKeyBase64Data];
            
            [Logger info:[NSString stringWithFormat:@"[Socket-ECDH] 准备切换到主队列发送数据 (公钥大小: %lu bytes)", (unsigned long)sendData.length]];
            
            // TODO: writeData 调度回主队列（GCDAsyncSocket 的 delegateQueue） 原因：GCDAsyncSocket 要求所有操作在 delegateQueue 上调用，避免竞态条件
            dispatch_async(dispatch_get_main_queue(), ^{
                [Logger info:@"[Socket-ECDH] 已切换到主队列，检查连接状态..."];
                
                // 再次检查socket状态，确保连接有效
                if (self.gcdSocket && self.gcdSocket.isConnected) {
                    [Logger info:@"[Socket-ECDH] Socket已连接，发送公钥到服务器 [主队列]"];
                    [self.gcdSocket writeData:sendData withTimeout:-1 tag:0];
                    [Logger info:@"[Socket-ECDH] writeData 调用完成，等待服务器响应..."];
                } else {
                    [Logger error:[NSString stringWithFormat:@"[Socket-ECDH] Socket未连接(isConnected=%@)，无法发送公钥，立即断开重连",
                                   self.gcdSocket.isConnected ? @"YES" : @"NO"]];
                    [self handleKeyExchangeFailure];
                }
            });
        }];
    });
}

#pragma mark - ECDH密钥交换超时处理

/// 启动ECDH密钥交换超时定时器
- (void)startKeyExchangeTimer {
    [self stopKeyExchangeTimer]; // 先停止之前的定时器
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    self.keyExchangeTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    
    if (self.keyExchangeTimer) {
        dispatch_source_set_timer(self.keyExchangeTimer,
                                  dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kKeyExchangeTimeout * NSEC_PER_SEC)),
                                  DISPATCH_TIME_FOREVER,
                                  0);
        
        __weak typeof(self) weakSelf = self;
        dispatch_source_set_event_handler(self.keyExchangeTimer, ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;
            [Logger error:[NSString stringWithFormat:@"[Socket-ECDH] 密钥交换超时(%.1f秒)，立即断开重连", kKeyExchangeTimeout]];
            
            [self handleKeyExchangeFailure];
        });
        
        dispatch_resume(self.keyExchangeTimer);
        [Logger info:[NSString stringWithFormat:@"[Socket-ECDH] 密钥交换超时定时器启动，超时时间:%.1f秒", kKeyExchangeTimeout]];
    }
}

/// 停止ECDH密钥交换超时定时器
- (void)stopKeyExchangeTimer {
    if (self.keyExchangeTimer) {
        dispatch_source_cancel(self.keyExchangeTimer);
        self.keyExchangeTimer = nil;
        [Logger info:@"[Socket-ECDH] 停止密钥交换超时定时器"];
    }
}

/// 处理ECDH密钥交换失败
- (void)handleKeyExchangeFailure {
    [Logger error:@"[Socket-ECDH] 密钥交换失败，立即断开连接并重连"];
    
    [self sentryUploadWithEventObj:@{
        @"event" : @"socket连接 - ECDH",
        @"error" : @"密钥交换失败，立即断开连接并重连",
        @"host" : self.socketHost ? self.socketHost : @"",
        @"port" : @(self.socketPort)
    } errorCode:@""];
    
    // 停止ECDH密钥交换超时定时器
    [self stopKeyExchangeTimer];
    
    // 重置ECDH相关状态
    [self clearKeyExchangeInfo];
    
    // 清除缓存数据
    [self cleanupReceiveBuffers];
    
    // 强制断开连接
    [self disconnectSocket];
}

/// 重置ECDH相关状态
- (void)clearKeyExchangeInfo {
    self.isKeyExchangeInProgress = NO;
    self.isECDHCompleted = NO;
    self.novDecryptorManager.shareKey = nil;
    self.novDecryptorManager.serverPublicKeyData = nil;
    SOCKETMANAGERTOOL.isAuth = NO;
}

// MARK: SENTRY
- (void)sentryUploadWithEventObj:(id)eventObj
                       errorCode:(NSString *)errorCode {
    NSError *error = nil;
    NSString *eventStr = @"";
    if ([eventObj isKindOfClass:[NSDictionary class]] ||
        [eventObj isKindOfClass:[NSArray class]]) {
        // 转换为 JSON 字符串
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:eventObj
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:&error];
        if (jsonData && !error) {
            eventStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
    }else if ([eventObj isKindOfClass:[NSString class]]) {
        eventStr = eventObj;
    }else {
        return;
    }
    
    if (eventStr.length == 0) {
        return;
    }
    
    SentryEvent *event = [[SentryEvent alloc] init];
    SentryMessage *message = [[SentryMessage alloc] initWithFormatted:eventStr];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:errorCode forKey:@"errorCode"];
    if (self.socketUserID && self.socketUserID.length > 0) {
        [dict setValue:self.socketUserID forKey:@"userId"];
    }
    
    if (IMSDKManager.currentLiceseId && IMSDKManager.currentLiceseId.length > 0) {
        [dict setValue:IMSDKManager.currentLiceseId forKey:@"liceseId"];
    }
    
    if (IMSDKManager.myUserNickname && IMSDKManager.myUserNickname.length > 0) {
        [dict setValue:IMSDKManager.myUserNickname forKey:@"nickName"];
    }
    
    [dict setValue:[FCUUID uuidForDevice] forKey:@"deviceId"];
    
    [dict setValue:[self transSecondToTimeStr] forKey:@"errorTime"];
    event.message = message;
    
    //socket连接 --- 类型固定
    //event_socketConnect
    NSString *transaction = @"event_socketConnect";
    event.transaction = transaction;
    
    event.tags = dict;
    [SentrySDK captureEvent:event];
}

//毫秒转换成： 03:23
- (NSString *)transSecondToTimeStr {
    NSDate *date = [NSDate date];
    NSInteger time = [date timeIntervalSince1970];
    //时
    NSString *str_hour = [NSString stringWithFormat:@"%02ld", time / 3600];
    //分
    NSString *str_minute = [NSString stringWithFormat:@"%02ld", (time % 3600) / 60];
    //秒
    NSString *str_second = [NSString stringWithFormat:@"%02ld", time % 60];

    NSString *format_time = @"";
    if (![str_hour isEqualToString:@"00"]) {
        format_time = [NSString stringWithFormat:@"%@:%@:%@", str_hour, str_minute, str_second];
    } else {
        format_time = [NSString stringWithFormat:@"%@:%@",str_minute, str_second];
    }
    
    return format_time;
}


@end
