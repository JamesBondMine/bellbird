//
//  IOSTcpRaceManager.m
//  NoaKit
//
//  Created by mac on 2025/1/15.
//

#import "IOSTcpRaceManager.h"
#import <CommonCrypto/CommonCrypto.h>
#import <CommonCrypto/CommonDigest.h>
#import <arpa/inet.h>
#import <netinet/in.h>
#import <sys/socket.h>
#import <sys/types.h>
#import <netdb.h>
#import <unistd.h>
#import <fcntl.h>
#import "InitializationErrorTypes.h"
#import "LXChatEncrypt.h"
#import "NoaProxySettings.h"
#import "NoaToolManager.h"
#import "AesEncryptUtils.h"
static const NSTimeInterval kSocketTimeout = 2.5; // 2.5秒超时，保证每次拨测有结果且总体可控

@interface IOSTcpRaceManager ()

@property (nonatomic, copy) NSString *appId;
@property (nonatomic, assign) int appType;
@property (nonatomic, strong) NoaUrlHostModel *bucket;
@property (nonatomic, assign) BOOL useProxy;
@property (nonatomic, assign) int sockfd;
@property (nonatomic, assign) BOOL isCancelled;
@property (nonatomic, copy) NSString *publicIp;
@end

@implementation IOSTcpRaceManager

#pragma mark - 初始化

- (instancetype)initWithAppId:(NSString *)appId
                      appType:(int)appType
                       bucket:(NoaUrlHostModel *)bucket
                     useProxy:(BOOL)useProxy
                     publicIp:(NSString *)publicIp{
    self = [super init];
    if (self) {
        _appId = [appId copy];
        _appType = appType;
        _bucket = bucket;
        _useProxy = useProxy;
        _sockfd = -1;
        _isCancelled = NO;
        _publicIp = publicIp;
    }
    return self;
}

#pragma mark - Public Methods

- (void)executeWithSuccess:(void(^)(IMServerListResponseBody *serverResponse))success
                   failure:(void(^)(NSError *error))failure {
    
    // 1️⃣ 检查任务是否已取消
    if (self.isCancelled) {
        if (failure) {
            NSError *error = [self createErrorWithType:[InitializationErrorTypes OSS_FAILURE]
                                               message:@"任务已被取消"
                                             errorCode:@"-999999"
            ];
            failure(error);
        }
        return;
    }
    // 3️⃣ 构造 AuthMessage
    NavMessage *authMessage = nil;
    @try {
        authMessage = [self createAuthMessageWithClientIP:self.publicIp];
        NSLog(@"🔐 创建Auth消息成功: appId=%@, timestamp=%lld, clientIP=%@", self.appId, authMessage.auth.timestamp, self.publicIp);
    } @catch (NSException *ex) {
        NSLog(@"❌ 构造 AuthMessage 失败: %@", ex.reason);
        if (failure) {
            NSError *error = [self createErrorWithType:[InitializationErrorTypes OSS_FAILURE]
                                               message:[NSString stringWithFormat:@"构造 AuthMessage 失败: %@", ex.reason]
                                             errorCode:@"-999999"
            ];
            failure(error);
        }
        return;
    }
    
    if (![self establishConnection]) {
        NSLog(@"❌ 建立TCP连接失败: %@", self.bucket.urlString);
        if (failure) {
            NSError *error = [self createErrorWithType:[InitializationErrorTypes OSS_FAILURE]
                                               message:@"建立TCP连接失败"
                                             errorCode:@"-888888"];
            failure(error);
        }
        return;
    }
    
    NSLog(@"✅ TCP连接建立成功: %@", self.bucket.urlString);
    
    // 5️⃣ 发送 Protobuf Auth 消息
    NavMessage *responseMessage = nil;
    @try {
        NSLog(@"📤 开始发送Protobuf消息...");
        responseMessage = [self sendProtobufMessage:authMessage];
        
        if (!responseMessage) {
            NSLog(@"❌ 发送/接收 Protobuf 失败");
            [self closeSocketQuietly];
            if (failure) {
                NSError *error = [self createErrorWithType:[InitializationErrorTypes OSS_FAILURE]
                                                   message:@"发送/接收 Protobuf 失败"
                                                 errorCode:@"-999999"];
                failure(error);
            }
            return;
        }
        
        NSLog(@"✅ Protobuf消息发送成功，收到响应");
    } @catch (NSException *ex) {
        NSLog(@"❌ 发送/接收 Protobuf 异常: %@", ex.reason);
        [self closeSocketQuietly];
        if (failure) {
            NSError *error = [self createErrorWithType:[InitializationErrorTypes OSS_FAILURE]
                                               message:[NSString stringWithFormat:@"发送/接收 Protobuf 失败: %@", ex.reason]
                                             errorCode:@"-999999"];
            failure(error);
        }
        return;
    } @finally {
        [self closeSocketQuietly];
    }
    
    // 6️⃣ 验证返回类型
    if (responseMessage.dataType != NavMessage_DataType_ImServerListResp) {
        NSLog(@"❌ 返回类型错误: %@, 期望: %@", @(responseMessage.dataType), @(NavMessage_DataType_NavAuthAck));
        if (failure) {
            NSError *error = [self createErrorWithType:[InitializationErrorTypes OSS_FAILURE]
                                               message:[NSString stringWithFormat:@"OssRace 失败, 返回类型不对: %@", @(responseMessage.dataType)]
                                             errorCode:@"-999999"];
            failure(error);
        }
        return;
    }
    
    // 7️⃣ 解析 responseMessage
    IMServerListResponse *serverResponse = responseMessage.imServerListResponse;
    switch (serverResponse.statusCode) {
        case NavDataTypeSuccess:
            if (!serverResponse.responseBody) {
                NSLog(@"❌ 返回数据为空");
                if (failure) {
                    NSError *error = [self createErrorWithType:[InitializationErrorTypes OSS_VOID_FAILURE]
                                                       message:@"OssRace 失败, 返回 body 为空"
                                                     errorCode:[NSString stringWithFormat:@"%d", serverResponse.statusCode]];
                    failure(error);
                }
                return;
            }
            
            // 7. 解密企业号信息
            @try {

                NSData *responseData = [AesEncryptUtils decryptBytes:serverResponse.responseBody secret:[self.appId MD5Encryption]];
                if (responseData && responseData.length > 0) {
                    NSLog(@"✅ 解密成功，数据长度: %lu", (unsigned long)responseData.length);
                    NSError *err = nil;
                    IMServerListResponseBody *body = [IMServerListResponseBody parseFromData:responseData error:&err];
                    success(body);
                }
                
            }
            @catch (NSException *ex) {
                NSLog(@"❌ 解密失败: %@", ex.reason);
                if (failure) {
                    NSError *error = [self createErrorWithType:[InitializationErrorTypes OSS_DECODE_FAILURE]
                                                       message:[NSString stringWithFormat:@"解密失败: %@", ex.reason]
                                                     errorCode:[NSString stringWithFormat:@"%d", serverResponse.statusCode]];
                    failure(error);
                }
            }
            break;
        case NavDataTypeMissing:
            if (failure) {
                NSError *error = [self createErrorWithType:[InitializationErrorTypes OSS_FAILURE]
                                                   message:[NSString stringWithFormat:@"必填字段缺失%@", serverResponse.message]
                                                 errorCode:[NSString stringWithFormat:@"%d", serverResponse.statusCode]];
                failure(error);
            }
            break;
        case NavDataTypeAppIdInvalid:
            if (failure) {
                NSError *error = [self createErrorWithType:[InitializationErrorTypes OSS_NONEXISTENT_FAILURE]
                                                   message:[NSString stringWithFormat:@"无效的应用ID%@", serverResponse.message]
                                                 errorCode:[NSString stringWithFormat:@"%d", serverResponse.statusCode]];
                failure(error);
            }
            break;
        case NavDataTypeRegionInvalid:
            if (failure) {
                NSError *error = [self createErrorWithType:[InitializationErrorTypes OSS_FAILURE]
                                                   message:[NSString stringWithFormat:@"无效的地区%@", serverResponse.message]
                                                 errorCode:[NSString stringWithFormat:@"%d", serverResponse.statusCode]];
                failure(error);
            }
            break;
        case NavDataTypeClientVersionInvalid:
            if (failure) {
                NSError *error = [self createErrorWithType:[InitializationErrorTypes OSS_FAILURE]
                                                   message:[NSString stringWithFormat:@"无效的客户端版本%@", serverResponse.message]
                                                 errorCode:[NSString stringWithFormat:@"%d", serverResponse.statusCode]];
                failure(error);
            }
            break;
        case NavDataTypeServerError:
            if (failure) {
                NSError *error = [self createErrorWithType:[InitializationErrorTypes OSS_FAILURE]
                                                   message:[NSString stringWithFormat:@"服务器内部错误%@", serverResponse.message]
                                                 errorCode:[NSString stringWithFormat:@"%d", serverResponse.statusCode]];
                failure(error);
            }
            break;
        case NavDataTypeNavDataFormatError:
            if (failure) {
                NSError *error = [self createErrorWithType:[InitializationErrorTypes OSS_FAILURE]
                                                   message:[NSString stringWithFormat:@"导航数据格式错误%@", serverResponse.message]
                                                 errorCode:[NSString stringWithFormat:@"%d", serverResponse.statusCode]];
                failure(error);
            }
            break;
        case NavDataTypeJsonParseError:
            if (failure) {
                NSError *error = [self createErrorWithType:[InitializationErrorTypes OSS_FAILURE]
                                                   message:[NSString stringWithFormat:@"JSON解析错误%@", serverResponse.message]
                                                 errorCode:[NSString stringWithFormat:@"%d", serverResponse.statusCode]];
                failure(error);
            }
            break;
        case NavDataTypeEndpointParseError:
            if (failure) {
                NSError *error = [self createErrorWithType:[InitializationErrorTypes OSS_FAILURE]
                                                   message:[NSString stringWithFormat:@"服务器端点解析错误%@", serverResponse.message]
                                                 errorCode:[NSString stringWithFormat:@"%d", serverResponse.statusCode]];
                failure(error);
            }
            break;
            
        default:
            if (failure) {
                NSError *error = [self createErrorWithType:[InitializationErrorTypes OSS_FAILURE]
                                                   message:[NSString stringWithFormat:@"其他错误，错误原因:%@", serverResponse.message]
                                                 errorCode:[NSString stringWithFormat:@"%d", serverResponse.statusCode]];
                failure(error);
            }
            break;
    }

}


- (void)cancel {
    self.isCancelled = YES;
    [self closeSocketQuietly];
}

- (NSString *)getTaskTag {
    return self.bucket.urlString;
}

#pragma mark - 私有方法

// 建立TCP连接
- (BOOL)establishConnection {
    // 分割host和port
    NSArray<NSString *> *hostParts = [self.bucket.urlString componentsSeparatedByString:@":"];
    if (hostParts.count < 2) {
        NSLog(@"❌ URL格式错误: %@", self.bucket.urlString);
        return NO;
    }
    
    NSString *host = hostParts[0];
    int port = [hostParts[1] intValue];
    if (port == 0) {
        port = 8087; // 默认端口
    }
    
    NSLog(@"🔗 准备连接到: %@:%d", host, port);
    
    // 获取代理配置
    NoaProxySettings *proxyConfig = nil;
    if (self.useProxy) {
        if ([ZTOOL getCurrentProxyType] == ProxyTypeSOCKS5) {
            proxyConfig = [[MMKV defaultMMKV] getObjectOfClass:[NoaProxySettings class] forKey:SOCKS_PROXY_KEY];
        }
    }
    
    // 创建Socket连接
    if (proxyConfig && [ZTOOL getCurrentProxyType] == ProxyTypeSOCKS5) {
        NSLog(@"🔗 通过SOCKS5代理连接: %@:%@", proxyConfig.address, proxyConfig.port);
        return [self connectThroughSocks5Proxy:host port:port proxyConfig:proxyConfig];
    } else {
        NSLog(@"🔗 直连模式");
        return [self connectDirectly:host port:port];
    }
}

// 直接连接
- (BOOL)connectDirectly:(NSString *)host port:(int)port {
    int sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock < 0) {
        NSLog(@"❌ 创建socket失败");
        return NO;
    }
    
    struct hostent *he = gethostbyname([host UTF8String]);
    if (!he) {
        NSLog(@"❌ 无法解析主机名: %@", host);
        close(sock);
        return NO;
    }
    
    struct sockaddr_in serverAddr;
    bzero(&serverAddr, sizeof(serverAddr));
    serverAddr.sin_family = AF_INET;
    serverAddr.sin_port = htons(port);
    serverAddr.sin_addr = *((struct in_addr *)he->h_addr);
    
    NSError *connectErr = nil;
    if (![self connectWithTimeout:sock addrPtr:(struct sockaddr *)&serverAddr addrLen:sizeof(serverAddr) timeout:kSocketTimeout outError:&connectErr]) {
        NSLog(@"❌ 连接失败: %@", connectErr.localizedDescription);
        close(sock);
        return NO;
    }
    
    self.sockfd = sock;
    return YES;
}

// 通过SOCKS5代理连接
- (BOOL)connectThroughSocks5Proxy:(NSString *)host port:(int)port proxyConfig:(NoaProxySettings *)proxyConfig {
    int sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock < 0) {
        NSLog(@"❌ 创建socket失败");
        return NO;
    }
    
    // 连接到代理服务器
    struct hostent *proxyHE = gethostbyname([proxyConfig.address UTF8String]);
    if (!proxyHE) {
        NSLog(@"❌ 无法解析代理主机名: %@", proxyConfig.address);
        close(sock);
        return NO;
    }
    
    struct sockaddr_in proxyAddr;
    memset(&proxyAddr, 0, sizeof(proxyAddr));
    proxyAddr.sin_family = AF_INET;
    proxyAddr.sin_port = htons([proxyConfig.port integerValue]);
    memcpy(&proxyAddr.sin_addr, proxyHE->h_addr_list[0], proxyHE->h_length);
    
    NSError *connectErr = nil;
    if (![self connectWithTimeout:sock addrPtr:(struct sockaddr *)&proxyAddr addrLen:sizeof(proxyAddr) timeout:kSocketTimeout outError:&connectErr]) {
        NSLog(@"❌ 连接代理失败: %@", connectErr.localizedDescription);
        close(sock);
        return NO;
    }
    
    // 执行SOCKS5握手
    if (![self performSocks5Handshake:sock host:host port:port username:proxyConfig.username password:proxyConfig.password]) {
        NSLog(@"❌ SOCKS5握手失败");
        close(sock);
        return NO;
    }
    
    self.sockfd = sock;
    return YES;
}

// 非阻塞连接with超时
- (BOOL)connectWithTimeout:(int)sock
                   addrPtr:(struct sockaddr *)addr
                   addrLen:(socklen_t)addrLen
                   timeout:(NSTimeInterval)timeout
                  outError:(NSError **)errParam {
    int origFlags = fcntl(sock, F_GETFL, 0);
    fcntl(sock, F_SETFL, origFlags | O_NONBLOCK);
    
    int res = connect(sock, addr, addrLen);
    if (res == 0) {
        fcntl(sock, F_SETFL, origFlags);
        return YES;
    }
    
    if (errno != EINPROGRESS) {
        if (errParam) {
            *errParam = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:nil];
        }
        fcntl(sock, F_SETFL, origFlags);
        return NO;
    }
    
    fd_set wf;
    FD_ZERO(&wf);
    FD_SET(sock, &wf);
    struct timeval tv = {(long)timeout, 0};
    int sel = select(sock + 1, NULL, &wf, NULL, &tv);
    
    if (sel <= 0) {
        if (errParam) {
            *errParam = [NSError errorWithDomain:NSPOSIXErrorDomain code:(sel == 0 ? ETIMEDOUT : errno) userInfo:nil];
        }
        fcntl(sock, F_SETFL, origFlags);
        return NO;
    }
    
    int soErr = 0;
    socklen_t len = sizeof(soErr);
    if (getsockopt(sock, SOL_SOCKET, SO_ERROR, &soErr, &len) < 0 || soErr) {
        if (errParam) {
            *errParam = [NSError errorWithDomain:NSPOSIXErrorDomain code:(soErr ?: errno) userInfo:nil];
        }
        fcntl(sock, F_SETFL, origFlags);
        return NO;
    }
    
    fcntl(sock, F_SETFL, origFlags);
    return YES;
}

// 执行SOCKS5握手和认证
- (BOOL)performSocks5Handshake:(int)sock host:(NSString *)host port:(int)port username:(NSString *)username password:(NSString *)password {
    // 设置超时
    struct timeval tv = {(long)kSocketTimeout, 0};
    setsockopt(sock, SOL_SOCKET, SO_SNDTIMEO, &tv, sizeof(tv));
    setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));
    
    // 发送初始握手请求
    uint8_t handshake[4];
    handshake[0] = 0x05; // SOCKS 版本 5
    handshake[1] = 0x02; // 支持的方法数量
    handshake[2] = 0x00; // 方法1: 不需要认证
    handshake[3] = 0x02; // 方法2: 用户名/密码认证
    
    ssize_t sent = send(sock, handshake, 4, 0);
    if (sent < 0) {
        return NO;
    }
    
    // 读取代理响应
    uint8_t response[2];
    if (![self readFully:sock buffer:response length:2]) {
        return NO;
    }
    
    if (response[0] != 0x05) {
        return NO;
    }
    
    // 检查选中的方法
    uint8_t selectedMethod = response[1];
    if (selectedMethod == 0x02) { // 需要用户名密码认证
        if (!username || !password) {
            return NO;
        }
        
        // 发送用户名/密码认证
        NSData *userData = [username dataUsingEncoding:NSUTF8StringEncoding];
        NSData *passData = [password dataUsingEncoding:NSUTF8StringEncoding];
        
        NSMutableData *authRequest = [NSMutableData data];
        uint8_t version = 0x01;
        [authRequest appendBytes:&version length:1];
        
        uint8_t userLen = (uint8_t)userData.length;
        [authRequest appendBytes:&userLen length:1];
        [authRequest appendData:userData];
        
        uint8_t passLen = (uint8_t)passData.length;
        [authRequest appendBytes:&passLen length:1];
        [authRequest appendData:passData];
        
        sent = send(sock, authRequest.bytes, authRequest.length, 0);
        if (sent < 0) {
            return NO;
        }
        
        // 读取认证响应
        uint8_t authResponse[2];
        if (![self readFully:sock buffer:authResponse length:2]) {
            return NO;
        }
        
        if (authResponse[0] != 0x01 || authResponse[1] != 0x00) {
            return NO;
        }
    } else if (selectedMethod != 0x00) { // 0x00 表示不需要认证
        return NO;
    }
    
    // 发送连接请求
    NSData *connectRequest = [self buildSocks5ConnectRequest:host port:port];
    sent = send(sock, connectRequest.bytes, connectRequest.length, 0);
    if (sent < 0) {
        return NO;
    }
    
    // 读取连接响应
    uint8_t connectResponse[10];
    if (![self readFully:sock buffer:connectResponse length:4]) {
        return NO;
    }
    
    if (connectResponse[0] != 0x05 || connectResponse[1] != 0x00) {
        return NO;
    }
    
    // 根据地址类型读取剩余响应
    uint8_t addressType = connectResponse[3];
    int bytesToRead = 0;
    
    switch (addressType) {
        case 0x01: // IPv4
            bytesToRead = 6; // 4字节IP + 2字节端口
            break;
        case 0x03: // 域名
            bytesToRead = 1 + connectResponse[4] + 2; // 1字节长度 + 域名 + 2字节端口
            break;
        case 0x04: // IPv6
            bytesToRead = 18; // 16字节IP + 2字节端口
            break;
        default:
            return NO;
    }
    
    // 读取剩余响应
    if (![self readFully:sock buffer:connectResponse + 4 length:bytesToRead]) {
        return NO;
    }
    
    return YES;
}

// 构建SOCKS5连接请求
- (NSData *)buildSocks5ConnectRequest:(NSString *)host port:(int)port {
    NSMutableData *request = [NSMutableData data];
    
    // 基本头部
    uint8_t header[4] = {0x05, 0x01, 0x00, 0x00}; // SOCKS版本, CONNECT命令, 保留, 地址类型
    [request appendBytes:header length:4];
    
    // 尝试解析为IP地址
    struct in_addr addr;
    if (inet_pton(AF_INET, [host UTF8String], &addr) == 1) {
        // IPv4
        uint8_t addressType = 0x01;
        [request replaceBytesInRange:NSMakeRange(3, 1) withBytes:&addressType];
        [request appendBytes:&addr length:4];
    } else {
        // 域名
        uint8_t addressType = 0x03;
        [request replaceBytesInRange:NSMakeRange(3, 1) withBytes:&addressType];
        
        NSData *domainData = [host dataUsingEncoding:NSUTF8StringEncoding];
        uint8_t domainLen = (uint8_t)domainData.length;
        [request appendBytes:&domainLen length:1];
        [request appendData:domainData];
    }
    
    // 端口（大端序）
    uint8_t portBytes[2];
    portBytes[0] = (uint8_t)(port >> 8);
    portBytes[1] = (uint8_t)(port & 0xFF);
    [request appendBytes:portBytes length:2];
    
    return request;
}

// 确保读取指定长度的字节
- (BOOL)readFully:(int)sock buffer:(uint8_t *)buffer length:(int)length {
    int totalRead = 0;
    while (totalRead < length) {
        ssize_t read = recv(sock, buffer + totalRead, length - totalRead, 0);
        if (read <= 0) {
            return NO;
        }
        totalRead += (int)read;
    }
    return YES;
}

// 发送Protobuf消息并接收响应
- (NavMessage *)sendProtobufMessage:(NavMessage *)message {
    if (self.sockfd < 0) {
        @throw [NSException exceptionWithName:@"SocketException" reason:@"socket 未初始化" userInfo:nil];
    }
    
    // 检查是否已取消
    if (self.isCancelled) {
        @throw [NSException exceptionWithName:@"CancelledException" reason:@"任务已被取消" userInfo:nil];
    }
    
    // 设置超时
    struct timeval tv = {(long)kSocketTimeout, 0};
    setsockopt(self.sockfd, SOL_SOCKET, SO_SNDTIMEO, &tv, sizeof(tv));
    setsockopt(self.sockfd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));
    
    // 构建packet
    NSData *body = [message data];
    NSData *hdr = [self encodeVarint32:(uint32_t)body.length];
    NSMutableData *pkt = [NSMutableData dataWithData:hdr];
    [pkt appendData:body];
    
    NSLog(@"📦 准备发送数据包，总长度: %lu字节 (头部: %lu字节, 消息体: %lu字节)",
          (unsigned long)pkt.length, (unsigned long)hdr.length, (unsigned long)body.length);
    
    // 发送
    const uint8_t *p = pkt.bytes;
    size_t total = pkt.length, sent = 0;
    while (sent < total) {
        if (self.isCancelled) {
            @throw [NSException exceptionWithName:@"CancelledException" reason:@"任务已被取消" userInfo:nil];
        }
        
        ssize_t s = send(self.sockfd, p + sent, total - sent, 0);
        if (s <= 0) {
            @throw [NSException exceptionWithName:@"SendException" reason:@"发送 Protobuf 失败" userInfo:nil];
        }
        sent += s;
    }
    
    NSLog(@"✅ 数据发送完成，已发送: %zu字节", sent);
    
    // 读长度
    uint32_t len = 0, shift = 0;
    while (1) {
        if (self.isCancelled) {
            @throw [NSException exceptionWithName:@"CancelledException" reason:@"任务已被取消" userInfo:nil];
        }
        
        uint8_t b = 0;
        ssize_t r = recv(self.sockfd, &b, 1, 0);
        if (r <= 0) {
            @throw [NSException exceptionWithName:@"ReceiveException" reason:@"接收长度失败" userInfo:nil];
        }
        len |= (b & 0x7F) << shift;
        if (!(b & 0x80)) break;
        shift += 7;
        if (shift >= 32) {
            @throw [NSException exceptionWithName:@"DecodeException" reason:@"长度 varint 解码失败" userInfo:nil];
        }
    }
    
    NSLog(@"📏 收到响应长度: %u字节", len);
    
    // 读body
    NSMutableData *d = [NSMutableData dataWithCapacity:len];
    size_t rem = len;
    while (rem > 0) {
        if (self.isCancelled) {
            @throw [NSException exceptionWithName:@"CancelledException" reason:@"任务已被取消" userInfo:nil];
        }
        
        uint8_t buf[4096];
        ssize_t r = recv(self.sockfd, buf, MIN(sizeof(buf), rem), 0);
        if (r <= 0) {
            @throw [NSException exceptionWithName:@"ReceiveException" reason:@"接收内容失败" userInfo:nil];
        }
        [d appendBytes:buf length:r];
        rem -= r;
    }
    
    NSLog(@"✅ 响应数据接收完成，总长度: %lu字节", (unsigned long)d.length);
    
    NSError *perr = nil;
    NavMessage *msg = [NavMessage parseFromData:d error:&perr];
    if (perr || !msg) {
        @throw [NSException exceptionWithName:@"ParseException" reason:[NSString stringWithFormat:@"解析失败:%@", perr.localizedDescription] userInfo:nil];
    }
    return msg;
}

// varint32 编码
- (NSData *)encodeVarint32:(uint32_t)value {
    NSMutableData *data = [NSMutableData data];
    while (YES) {
        if ((value & ~0x7F) == 0) {
            uint8_t byte = (uint8_t)value;
            [data appendBytes:&byte length:1];
            break;
        } else {
            uint8_t byte = (uint8_t)((value & 0x7F) | 0x80);
            [data appendBytes:&byte length:1];
            value >>= 7;
        }
    }
    return data;
}

// 构造Auth消息
- (NavMessage *)createAuthMessageWithClientIP:(NSString *)clientIP {
    long long timestamp = (long long)([NSDate date].timeIntervalSince1970 * 1000);
    NSString *nonce = [NSString stringWithFormat:@"test_nonce_%lld",timestamp];
    NSString *clientVersion = [ZTOOL getCurretnVersion];
    NSString *region = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
    NSString *rawSign = [NSString stringWithFormat:@"%@%d%@%@%@%lld%@", self.appId, self.appType, clientVersion, region, @"ios", timestamp, nonce];
    NSString *encryptedSign = [self encryptWithAES:rawSign];
    
    IMServerListRequest *requestMessage = [IMServerListRequest message];
    requestMessage.appId = self.appId;
    if (DefaultAppType == 0) {
        requestMessage.appType = IMServerListRequest_DataType_Common;
    }else {
        requestMessage.appType = IMServerListRequest_DataType_Independent;
    }
    requestMessage.clientVersion = clientVersion;
    requestMessage.region = region;
    requestMessage.deviceType = @"ios";
    requestMessage.timestamp = timestamp;
    requestMessage.signature = encryptedSign;
    requestMessage.clientIp = clientIP ?: @""; // 填充公网 IP
    requestMessage.sdkVersion = @"1.0";
    requestMessage.nonce = nonce;
    NavMessage *msg = [NavMessage message];
    msg.dataType = NavMessage_DataType_ImServerListReq;
    msg.imServerListRequest = requestMessage;
    
    return msg;
}


// AES加密
- (NSString *)encryptWithAES:(NSString *)plaintext {
    // 1. 生成AES密钥
    NSData *key = [self generateAesKey];
    
    // 2. 生成随机IV
    uint8_t iv[kCCBlockSizeAES128];
    arc4random_buf(iv, kCCBlockSizeAES128);
    
    // 3. 明文转NSData
    NSData *plainData = [plaintext dataUsingEncoding:NSUTF8StringEncoding];
    
    // 4. 为密文分配空间
    size_t outLength = plainData.length + kCCBlockSizeAES128;
    void *outBuffer = malloc(outLength);
    size_t actualOutSize = 0;
    
    // 5. 执行加密
    CCCryptorStatus status = CCCrypt(
                                     kCCEncrypt,
                                     kCCAlgorithmAES128,
                                     kCCOptionPKCS7Padding,
                                     key.bytes,
                                     key.length,
                                     iv,
                                     plainData.bytes,
                                     plainData.length,
                                     outBuffer,
                                     outLength,
                                     &actualOutSize
                                     );
    
    if (status != kCCSuccess) {
        free(outBuffer);
        @throw [NSException exceptionWithName:@"CryptoException" reason:@"AES 加密失败" userInfo:nil];
    }
    
    // 6. 拼接IV + cipherText
    NSData *cipherData = [NSData dataWithBytes:outBuffer length:actualOutSize];
    NSMutableData *combined = [NSMutableData dataWithBytes:iv length:kCCBlockSizeAES128];
    [combined appendData:cipherData];
    
    // 7. Base64编码
    NSString *base64Str = [combined base64EncodedStringWithOptions:0];
    free(outBuffer);
    return base64Str;
}

// 生成AES密钥
- (NSData *)generateAesKey {
    NSString *seed = @"671581_30158023925312512" @"0fc2f1c074fd42b3b13f23234297dc68";
    const char *seedCStr = [seed UTF8String];
    unsigned char shaDigest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(seedCStr, (CC_LONG)strlen(seedCStr), shaDigest);
    return [NSData dataWithBytes:shaDigest length:CC_SHA256_DIGEST_LENGTH];
}

// 关闭Socket
- (void)closeSocketQuietly {
    if (self.sockfd >= 0) {
        close(self.sockfd);
        self.sockfd = -1;
    }
}

// 创建错误
- (NSError *)createErrorWithType:(NSString *)type
                         message:(NSString *)message
                       errorCode:(NSString *)errorCode {
    NSDictionary *userInfo = @{
        NSLocalizedDescriptionKey: message ?: @"Unknown error",
        NSUnderlyingErrorKey: errorCode  ?: @"Unknown error"
    };
    return [NSError errorWithDomain:@"com.fgho.network.race" code:[type integerValue] userInfo:userInfo];
}

@end
