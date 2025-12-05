//
//  NovDecryptorManager.m
//  NoaKit
//
//  Created by mac on 2025/8/30.
//

#import "NovDecryptorManager.h"
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonCrypto.h>
// 宏定义
#import "LingIMMacorHeader.h"

#import "ECDHKeyManager.h"
#import "MessageProtocolHeader.h"

// 密钥交换
#import "ZIMKeyExchange.h"

@interface NovDecryptorManager ()

@end

@implementation NovDecryptorManager

- (void)dealloc {
    if (_privateKey) {
        CFRelease(_privateKey);
    }
    if (_publicKey) {
        CFRelease(_publicKey);
    }
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _privateKey = NULL;
        _publicKey = NULL;
    }
    return self;
}

// 生成新的密钥对
- (void)generateKeyPairWithComplete:(void (^)(SecKeyRef publicKey, SecKeyRef privateKey))complete {
    // 异步生成密钥对
    __weak typeof(self) weakSelf = self;
    [ECDHKeyManager generateKeyPairWithCompletion:^(SecKeyRef publicKey, SecKeyRef privateKey, NSError *error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        
        if (error || !publicKey || !privateKey) {
            NSString *errorMsg = [NSString stringWithFormat:@"客户端密钥对生成失败: %@", error.localizedDescription];
            CIMLog(@"❌ [ECDH客户端] %@", errorMsg);
            if (complete) {
                complete(nil, nil);
            }
            return;
        }
        
        // 使用 SecKeyCopy 来确保引用的正确管理
        if (publicKey) {
            self.publicKey = publicKey;  // 复制公钥引用
            CFRetain(self.publicKey); // 释放原始公钥
        }
        
        if (privateKey) {
            self.privateKey = privateKey;  // 复制私钥引用
            CFRetain(privateKey); // 释放原始私钥
        }
        
        if (complete) {
            complete(self.publicKey, self.privateKey);
        }
        
        CIMLog(@"✅ [ECDH客户端] 客户端密钥对生成成功");
    }];
}

- (NSData *)secKeyRefToData:(SecKeyRef)keyRef {
    if (!keyRef) {
        return nil;
    }
    
    // 获取客户端公钥字节数组
    NSError *error = nil;
    
    // 获取公钥的X.509 DER编码字节数组
    NSData *keyBytes = [ECDHKeyManager getPublicKeyBytes:keyRef error:&error];
    if (error || !keyBytes) {
        CIMLog(@"❌ [ECDH客户端] 获取公钥字节数组失败: %@", error.localizedDescription);
        return nil;
    }
    
    return keyBytes;
}

- (NSData *)buildServerPublicKeyRequestMessage:(NSData *)appPublicKey {
    
    CIMLog(@"🔨 构建获取服务器公钥请求消息");
    // 计算公钥长度
    NSUInteger publicKeyLength = appPublicKey.length;

    CIMLog(@"   - APP公钥长度: %lu字节", publicKeyLength);
    
    NSMutableData *messageData = [NSMutableData data];
    
    // 1. 计算扰乱数据长度
    // 总长度限制：2字节最大值 = 65535（这点无需判断，因为头部4位，密钥91位，扰乱数据:100-1024之间随机）
    // 消息头长度:前4位 0-1:消息总长度 2-3扰乱数据长度
    NSUInteger headerLength = 4;
    
    // 扰乱数据长度范围：100-1024字节
    NSUInteger minObfuscatedLength = 100;
    NSUInteger maxObfuscatedLength = 1024;
    
    // 在100-1024范围内随机选择长度，但不超过可用长度
    NSUInteger obfuscatedLength = minObfuscatedLength + (arc4random_uniform((uint32_t)(maxObfuscatedLength - minObfuscatedLength + 1)));
    
    CIMLog(@"📋 扰乱数据长度计算:");
    CIMLog(@"   - 扰乱数据目标范围: %lu-%lu位", (unsigned long)minObfuscatedLength, (unsigned long)maxObfuscatedLength);
    CIMLog(@"   - 最终扰乱数据长度: %lu位", (unsigned long)obfuscatedLength);
    
    // 2. 计算消息总长度
    // 消息总长度 = 消息头 + 公钥 + 扰乱数据（消息头长度-2的原因：消息总长度占用的0-1不应该算入，因为总长度其实是公钥+扰乱+扰乱数据）
    uint16_t totalMessageLength = (uint16_t)((headerLength - 2) + publicKeyLength + obfuscatedLength);
    
    // 3. 生成扰乱数据
    NSData *obfuscatedData = [self randomDataWithLength:obfuscatedLength];
    if (!obfuscatedData) {
        CIMLog(@"❌ 扰乱数据生成失败");
        return nil;
    }
    
    // 4. 消息总长度 (NSData前两位，0-1位置，大端序)
    uint16_t networkTotalLength = CFSwapInt16HostToBig(totalMessageLength);
    [messageData appendBytes:&networkTotalLength length:2];
    
    CIMLog(@"📋 消息总长度字段: %u字节", totalMessageLength);
    
    // 5. 扰乱数据长度 (NSData占用两位，2-3位置，大端序)
    uint16_t networkObfuscatedLength = CFSwapInt16HostToBig((uint16_t)obfuscatedLength);
    [messageData appendBytes:&networkObfuscatedLength length:2];
    
    // 6. 添加公钥数据
    [messageData appendData:appPublicKey];
    
    // 7. 添加扰乱数据
    [messageData appendData:obfuscatedData];
    
    CIMLog(@"📋 消息构建完成:");
    CIMLog(@"总长度：%@", [messageData subdataWithRange:NSMakeRange(0, 2)]);
    CIMLog(@"扰乱数据长度: %@", [messageData subdataWithRange:NSMakeRange(2, 2)]);
    CIMLog(@"APP公钥: %@", [messageData subdataWithRange:NSMakeRange(4, publicKeyLength)]);
    CIMLog(@"扰乱数据: %@", [messageData subdataWithRange:NSMakeRange(4 + publicKeyLength, obfuscatedLength)]);
    
    CIMLog(@"   - 消息总长度: %u字节", totalMessageLength);
    
    CIMLog(@"✅ 服务器公钥请求消息构建完成");
    
    return [messageData copy];
}

- (BOOL)parseServerPublicKeyMessageSync:(NSData *)messageData {
    
    // 验证最小长度 (2字节总长度 + 2字节扰乱长度)
    if (messageData.length < 4) {
        CIMLog(@"❌ 服务器公钥消息数据长度不足: %lu字节", (unsigned long)messageData.length);
        return false;
    }
    
    const uint8_t *bytes = (const uint8_t *)messageData.bytes;
    NSUInteger offset = 0;
    
    // 解析消息总长度 (NSData前两位，0-1位置)
    // 根据构建方法：totalMessageLength = 2 + publicKeyLength + obfuscatedLength
    uint16_t totalMessageLength = CFSwapInt16BigToHost(*(uint16_t *)(bytes + offset));
    offset += 2;
    
    CIMLog(@"📋 消息总长度: %u字节", totalMessageLength);
    
    // 解析扰乱长度 (NSData占用两位，2-3位置)
    uint16_t obfuscatedLength = CFSwapInt16BigToHost(*(uint16_t *)(bytes + offset));
    offset += 2;
    
    CIMLog(@"📋 扰乱长度: %u字节", obfuscatedLength);
    
    // 计算APP公钥长度
    // 根据构建方法：totalMessageLength = 2 + publicKeyLength + obfuscatedLength
    // 所以：publicKeyLength = totalMessageLength - 2 - obfuscatedLength
    if (totalMessageLength < 2 + obfuscatedLength) {
        CIMLog(@"❌ 消息格式错误，长度计算不正确");
        CIMLog(@"   - 消息总长度: %u字节", totalMessageLength);
        CIMLog(@"   - 扰乱数据长度: %u字节", obfuscatedLength);
        CIMLog(@"   - 需要最小长度: %u字节", 2 + obfuscatedLength);
        return false;
    }
    
    uint16_t appPublicKeyLength = totalMessageLength - 2 - 2 - obfuscatedLength;
    CIMLog(@"📋 计算得出APP公钥长度: %u字节", appPublicKeyLength);
    CIMLog(@"📋 长度分解: 总长度%u = 2 + 2 + 公钥%u + 扰乱数据%u",
           totalMessageLength, appPublicKeyLength, obfuscatedLength);
    
    // 验证数据范围是否有效
    if (offset + appPublicKeyLength > messageData.length) {
        CIMLog(@"❌ 公钥数据范围超出消息数据长度");
        CIMLog(@"   - 当前偏移: %lu字节", (unsigned long)offset);
        CIMLog(@"   - 公钥长度: %u字节", appPublicKeyLength);
        CIMLog(@"   - 需要总长度: %lu字节", (unsigned long)(offset + appPublicKeyLength));
        CIMLog(@"   - 实际数据长度: %lu字节", (unsigned long)messageData.length);
        return false;
    }
    
    // 提取公钥数据
    NSData *publicKeyData = [messageData subdataWithRange:NSMakeRange(offset, appPublicKeyLength)];
//    offset += appPublicKeyLength;
    
//    // 提取扰乱数据
//    NSData *obfuscatedData = [messageData subdataWithRange:NSMakeRange(offset, obfuscatedLength)];
//    offset += obfuscatedLength;
    
    CIMLog(@"📋 公钥数据长度: %lu字节", (unsigned long)publicKeyData.length);
//    CIMLog(@"📋 扰乱数据长度: %lu字节", (unsigned long)obfuscatedData.length);
    if (!publicKeyData) {
        return NO;
    }
    self.serverPublicKeyData = publicKeyData;
    return YES;
}



// 使用私钥和对方的公钥计算共享密钥
- (BOOL)generateSharedSecret {
    if (!self.serverPublicKeyData || !self.privateKey) {
        NSString *errorMsg = @"服务端公钥base64字符串不能为空";
        CIMLog(@"❌ [ECDH解密助手] %@", errorMsg);
        return NO;
    }
    
    // 计算共享密钥
    NSData *sharedSecret = [ZIMKeyExchange performKeyExchange:self.serverPublicKeyData clientKeyPair:self.privateKey];
    
    if (!sharedSecret || sharedSecret.length == 0) {
        CIMLog(@"❌ [ECDH解密助手] 共享密钥计算失败");
        return NO;
    }
    
    CIMLog(@"✅ [ECDH解密助手] 共享密钥生成成功，长度: %lu字节", (unsigned long)sharedSecret.length);
    CIMLog(@"🔐 [ECDH解密助手] 共享密钥hex: %@", [ECDHKeyManager hexStringFromData:sharedSecret]);
    self.shareKey = sharedSecret;
    return YES;
}

/// 获取帧头标识符（shareKey的前8字节）
- (NSData *)getFrameIdentifier {
    // 使用本地副本，防止多线程竞态条件
    NSData *localShareKey = self.shareKey;
    if (!localShareKey || localShareKey.length < 8) {
        CIMLog(@"❌ [ECDH解密助手] shareKey未准备好或长度不足，无法获取帧标识符");
        return nil;
    }
    return [localShareKey subdataWithRange:NSMakeRange(0, 8)];
}

- (NSData *)randomDataWithLength:(NSUInteger)length {
    if (length <= 0) {
        CIMLog(@"%@", @"随机数据长度必须大于0");
    }
    
    // 创建字节数组
    uint8_t *ivBytes = malloc(length);
    if (!ivBytes) {
        CIMLog(@"内存分配失败");
        return nil;
    }
    
    // 使用SecRandomCopyBytes生成密码学安全的随机数
    int result = SecRandomCopyBytes(kSecRandomDefault, length, ivBytes);
    
    if (result != errSecSuccess) {
        free(ivBytes);
        CIMLog(@"随机数生成失败")
        return nil;
    }
    
    // 创建NSData对象
    NSData *ivData = [NSData dataWithBytes:ivBytes length:length];
    free(ivBytes);
    return ivData;
}

- (NSString *)hexStringFromData:(NSData *)data {
    if (!data) return @"";
    
    NSMutableString *hexString = [NSMutableString stringWithCapacity:data.length * 2];
    const unsigned char *bytes = (const unsigned char *)data.bytes;
    
    for (NSUInteger i = 0; i < data.length; i++) {
        [hexString appendFormat:@"%02x", bytes[i]];
    }
    
    return [hexString copy];
}

// 计算 HMAC-SHA256
- (NSData *)hmacEncryptSHA256ForData:(NSData *)data withKey:(NSData *)key {
    unsigned char hmacData[CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, key.bytes, key.length, data.bytes, data.length, hmacData);
    return [NSData dataWithBytes:hmacData length:CC_SHA256_DIGEST_LENGTH];
}

// AES-256-CBC 加密
- (NSData *)AES256EncryptWithData:(NSData *)data key:(NSData *)key iv:(NSData *)iv {
    if (key.length != kCCKeySizeAES256) {
        NSLog(@"Key length should be 256 bits.");
        return nil;
    }

    size_t dataOutAvailable = data.length + kCCBlockSizeAES128;
    void *dataOut = malloc(dataOutAvailable);
    size_t dataOutMoved = 0;

    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt,
                                           kCCAlgorithmAES,
                                           kCCOptionPKCS7Padding,
                                           key.bytes,
                                           kCCKeySizeAES256,
                                           iv.bytes,
                                           data.bytes,
                                           data.length,
                                           dataOut,
                                           dataOutAvailable,
                                           &dataOutMoved);

    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:dataOut length:dataOutMoved freeWhenDone:YES];
    } else {
        free(dataOut);
        NSLog(@"Encryption failed with error code %d", cryptStatus);
        return nil;
    }
}

// AES-256-CBC 解密
- (NSData *)AES256DecryptWithData:(NSData *)data key:(NSData *)key iv:(NSData *)iv {
    if (key.length != kCCKeySizeAES256) {
        NSLog(@"Key length should be 256 bits.");
        return nil;
    }

    size_t dataOutAvailable = data.length;
    void *dataOut = malloc(dataOutAvailable);
    size_t dataOutMoved = 0;

    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt,
                                           kCCAlgorithmAES,
                                           kCCOptionPKCS7Padding,
                                           key.bytes,
                                           kCCKeySizeAES256,
                                           iv.bytes,
                                           data.bytes,
                                           data.length,
                                           dataOut,
                                           dataOutAvailable,
                                           &dataOutMoved);

    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:dataOut length:dataOutMoved freeWhenDone:YES];
    } else {
        free(dataOut);
        NSLog(@"Decryption failed with error code %d", cryptStatus);
        return nil;
    }
}

#pragma mark - 消息帧构建

/// 构建增强帧协议格式的加密消息帧
/// @param data 需要加密的原始数据
/// @return 增强帧协议格式的完整消息帧
- (NSData *)buildEncryptedMessageFrameWithData:(NSData *)data {
    if (!data || data.length == 0) {
        CIMLog(@"[增强帧协议] ❌ 原始数据为空");
        return nil;
    }
    
    // 保存 shareKey 的本地副本，防止多线程竞态条件
    NSData *localShareKey = self.shareKey;
    if (!localShareKey || localShareKey.length < 8) {
        CIMLog(@"[增强帧协议] ❌ AES密钥未准备好");
        return nil;
    }
    
    CIMLog(@"[增强帧协议] 开始构建增强帧协议格式的加密消息帧...");
    
    // 扰乱数据长度范围：0-256字节
    NSUInteger minObfuscatedLength = 0;
    NSUInteger maxObfuscatedLength = 256;
    NSUInteger obfuscatedLength = minObfuscatedLength + (arc4random_uniform((uint32_t)(maxObfuscatedLength - minObfuscatedLength + 1)));
    CIMLog(@"[增强帧协议] 📋 扰乱数据长度计算:");
    CIMLog(@"[增强帧协议]    - 扰乱数据目标范围: %lu-%lu位", (unsigned long)minObfuscatedLength, (unsigned long)maxObfuscatedLength);
    CIMLog(@"[增强帧协议]    - 最终扰乱数据长度: %lu位", (unsigned long)obfuscatedLength);
    
    // 生成扰乱数据
    NSData *obfuscatedData = [self randomDataWithLength:obfuscatedLength];
    if (!obfuscatedData) {
        CIMLog(@"[增强帧协议] ❌ 扰乱数据生成失败");
        return nil;
    }
    
    // 计算iv数据
    NSData *ivData = [self randomDataWithLength:16];
    if (!ivData || ivData.length != 16) {
        CIMLog(@"[增强帧协议] ❌ IV数据生成失败");
        return nil;
    }
    uint32_t ivLength = CFSwapInt32HostToBig((uint32_t)ivData.length);
    
    // 计算需要加密的数据（使用本地副本）
    NSData *encryptedData = [self AES256EncryptWithData:data key:localShareKey iv:ivData];
    if (!encryptedData || encryptedData.length == 0) {
        CIMLog(@"[增强帧协议] ❌ 数据加密失败");
        return nil;
    }
    uint32_t encryptedLength = CFSwapInt32HostToBig((uint32_t)encryptedData.length);
    
    // 计算HMAC数据（使用本地副本）
    NSData *hmacData = [self hmacEncryptSHA256ForData:encryptedData withKey:localShareKey];
    if (!hmacData || hmacData.length == 0) {
        CIMLog(@"[增强帧协议] ❌ HMAC计算失败");
        return nil;
    }
    uint32_t hmacLength = CFSwapInt32HostToBig((uint32_t)hmacData.length);
    
    // 计算消息体长度
    // 消息体长度 = iv长度+iv数据 + hmac长度+hmac数据 + 消息长度+消息数据
    uint32_t messageBodyLength = (uint32_t)(4 + ivData.length + 4 + hmacData.length + 4 + encryptedData.length);
    
    CIMLog(@"[增强帧协议] 📋 消息长度计算:");
    CIMLog(@"[增强帧协议]    - IV长度: %lu字节", (unsigned long)ivData.length);
    CIMLog(@"[增强帧协议]    - HMAC长度: %lu字节", (unsigned long)hmacData.length);
    CIMLog(@"[增强帧协议]    - 加密数据长度: %lu字节", (unsigned long)encryptedData.length);
    CIMLog(@"[增强帧协议]    - 消息体长度: %u字节", messageBodyLength);
    CIMLog(@"[增强帧协议]    - 扰乱数据长度: %lu字节", (unsigned long)obfuscatedData.length);
    
    // 创建增强帧数据
    NSMutableData *enhancedFrameData = [[NSMutableData alloc] initWithCapacity:MESSAGE_FRAME_HEADER_SIZE + messageBodyLength + obfuscatedData.length];
    
    // 创建增强帧协议头
    MessageFrameHeader enhancedHeader;
    memset(&enhancedHeader, 0, sizeof(MessageFrameHeader)); // ✅ 初始化为0，避免野指针
    
    // 设置帧头标识（AES密钥的前8字节）- 使用本地副本防止多线程竞态
    NSData *frameIdentifier = [localShareKey subdataWithRange:NSMakeRange(0, 8)];
    if (!frameIdentifier || frameIdentifier.length < 8 || frameIdentifier.bytes == NULL) {
        CIMLog(@"[增强帧协议] ❌ 帧标识提取失败，localShareKey.length=%lu", (unsigned long)localShareKey.length);
        return nil;
    }
    memcpy(enhancedHeader.frameIdentifier, frameIdentifier.bytes, 8);
    
    // 设置实际数据长度（网络字节序）- 只包含消息体长度，不包含扰乱数据
    enhancedHeader.actualDataLength = CFSwapInt32HostToBig(messageBodyLength);
    
    // 1. 添加增强帧协议头
    [enhancedFrameData appendBytes:&enhancedHeader length:MESSAGE_FRAME_HEADER_SIZE];
    
    // 2. 添加内部消息体：iv长度+iv数据 + hmac长度+hmac数据 + 消息长度+消息数据
    // IV长度 + IV数据
    [enhancedFrameData appendBytes:&ivLength length:4];
    [enhancedFrameData appendData:ivData];
    
    // HMAC长度 + HMAC数据
    [enhancedFrameData appendBytes:&hmacLength length:4];
    [enhancedFrameData appendData:hmacData];
    
    // 加密数据长度 + 加密数据
    [enhancedFrameData appendBytes:&encryptedLength length:4];
    [enhancedFrameData appendData:encryptedData];
    
    // 3. 添加扰乱数据
    [enhancedFrameData appendData:obfuscatedData];
    
    CIMLog(@"[增强帧协议] ✅ 构建增强帧协议消息成功:");
    CIMLog(@"[增强帧协议]    - 帧头标识: %@", [self hexStringFromData:frameIdentifier]);
    CIMLog(@"[增强帧协议]    - 消息体长度: %u字节", messageBodyLength);
    CIMLog(@"[增强帧协议]    - 扰乱数据长度: %lu字节", (unsigned long)obfuscatedData.length);
    CIMLog(@"[增强帧协议]    - 总帧长度: %lu字节", (unsigned long)enhancedFrameData.length);
    
    return [enhancedFrameData copy];
}



/// 解析增强帧协议格式的消息（基于buildEncryptedMessageFrameWithData的加密逻辑）
/// @param enhancedFrameData 增强帧协议格式的数据
/// @return 解密后的原始数据
- (NSData *)parseEnhancedFrameProtocolMessage:(NSData *)enhancedFrameData {
    if (!enhancedFrameData || enhancedFrameData.length < MESSAGE_FRAME_HEADER_SIZE) {
        CIMLog(@"[帧协议] ❌ 消息帧数据无效或长度不足");
        return nil;
    }
    
    // 保存 shareKey 的本地副本，防止多线程竞态条件
    NSData *localShareKey = self.shareKey;
    if (!localShareKey || localShareKey.length < 8) {
        CIMLog(@"[增强帧协议] ❌ AES密钥未准备好");
        return nil;
    }
    
    CIMLog(@"[增强帧协议] 开始解析增强帧协议消息，总长度: %lu字节", (unsigned long)enhancedFrameData.length);
    
    const uint8_t *bytes = (const uint8_t *)enhancedFrameData.bytes;
    NSUInteger offset = 0;
    
    // 1. 解析帧协议头
    MessageFrameHeader *enhancedHeader = (MessageFrameHeader *)(bytes + offset);
    offset += MESSAGE_FRAME_HEADER_SIZE;
    
    // 2. 验证帧头标识（AES密钥的前8字节）- 使用本地副本防止多线程竞态
    NSData *expectedFrameIdentifier = [localShareKey subdataWithRange:NSMakeRange(0, 8)];
    NSData *receivedFrameIdentifier = [NSData dataWithBytes:enhancedHeader->frameIdentifier length:8];
    
    if (![expectedFrameIdentifier isEqualToData:receivedFrameIdentifier]) {
        CIMLog(@"[增强帧协议] ❌ 帧头标识验证失败");
        CIMLog(@"[增强帧协议]    - 期望: %@", [self hexStringFromData:expectedFrameIdentifier]);
        CIMLog(@"[增强帧协议]    - 实际: %@", [self hexStringFromData:receivedFrameIdentifier]);
        return nil;
    }
    
    CIMLog(@"[增强帧协议] ✅ 帧头标识验证成功");
    
    // 3. 解析消息体长度（网络字节序）
    uint32_t messageBodyLength = CFSwapInt32BigToHost(enhancedHeader->actualDataLength);
    
    CIMLog(@"[增强帧协议] 📋 消息体长度: %u字节", messageBodyLength);
    
    // 4. 验证数据长度
    if (messageBodyLength == 0) {
        CIMLog(@"[增强帧协议] ❌ 无效的消息体长度: %u", messageBodyLength);
        return nil;
    }
    
    // 5. 检查是否有足够的数据（消息体 + 扰乱数据）
    NSUInteger remainingDataLength = enhancedFrameData.length - offset;
    if (messageBodyLength > remainingDataLength) {
        CIMLog(@"[增强帧协议] ❌ 数据不完整，需要至少%u字节消息体，剩余%lu字节", 
               messageBodyLength, (unsigned long)remainingDataLength);
        return nil;
    }
    
    // 6. 提取消息体数据
    NSData *messageBodyData = [enhancedFrameData subdataWithRange:NSMakeRange(offset, messageBodyLength)];
    
    CIMLog(@"[增强帧协议] 📋 提取消息体: %lu字节", (unsigned long)messageBodyData.length);
    
    // 7. 直接解析消息体数据，无需处理扰乱数据
    const uint8_t *messageBodyBytes = (const uint8_t *)messageBodyData.bytes;
    NSUInteger messageBodyOffset = 0;
    
    // 7.1 解析IV长度和IV数据
    if (messageBodyOffset + 4 > messageBodyData.length) {
        CIMLog(@"[增强帧协议] ❌ 数据不足，无法读取IV长度");
        return nil;
    }
    
    uint32_t ivLength = CFSwapInt32BigToHost(*(uint32_t *)(messageBodyBytes + messageBodyOffset));
    messageBodyOffset += 4;
    
    if (messageBodyOffset + ivLength > messageBodyData.length) {
        CIMLog(@"[增强帧协议] ❌ 数据不足，无法读取IV数据，需要%u字节，剩余%lu字节", ivLength, (unsigned long)(messageBodyData.length - messageBodyOffset));
        return nil;
    }
    
    NSData *ivData = [messageBodyData subdataWithRange:NSMakeRange(messageBodyOffset, ivLength)];
    messageBodyOffset += ivLength;
    
    CIMLog(@"[增强帧协议] 📋 IV长度: %u字节", ivLength);
    
    // 7.2 解析HMAC长度和HMAC数据
    if (messageBodyOffset + 4 > messageBodyData.length) {
        CIMLog(@"[增强帧协议] ❌ 数据不足，无法读取HMAC长度");
        return nil;
    }
    
    uint32_t hmacLength = CFSwapInt32BigToHost(*(uint32_t *)(messageBodyBytes + messageBodyOffset));
    messageBodyOffset += 4;
    
    if (messageBodyOffset + hmacLength > messageBodyData.length) {
        CIMLog(@"[增强帧协议] ❌ 数据不足，无法读取HMAC数据，需要%u字节，剩余%lu字节", hmacLength, (unsigned long)(messageBodyData.length - messageBodyOffset));
        return nil;
    }
    
    NSData *hmacData = [messageBodyData subdataWithRange:NSMakeRange(messageBodyOffset, hmacLength)];
    messageBodyOffset += hmacLength;
    
    CIMLog(@"[增强帧协议] 📋 HMAC长度: %u字节", hmacLength);
    
    // 7.3 解析加密数据长度和加密数据
    if (messageBodyOffset + 4 > messageBodyData.length) {
        CIMLog(@"[增强帧协议] ❌ 数据不足，无法读取加密数据长度");
        return nil;
    }
    
    uint32_t encryptedLength = CFSwapInt32BigToHost(*(uint32_t *)(messageBodyBytes + messageBodyOffset));
    messageBodyOffset += 4;
    
    if (messageBodyOffset + encryptedLength > messageBodyData.length) {
        CIMLog(@"[增强帧协议] ❌ 数据不足，无法读取加密数据，需要%u字节，剩余%lu字节", encryptedLength, (unsigned long)(messageBodyData.length - messageBodyOffset));
        return nil;
    }
    
    NSData *encryptedData = [messageBodyData subdataWithRange:NSMakeRange(messageBodyOffset, encryptedLength)];
    messageBodyOffset += encryptedLength;
    
    CIMLog(@"[增强帧协议] 📋 加密数据长度: %u字节", encryptedLength);
    
    // 8. 验证HMAC（使用本地副本）
    NSData *calculatedHmac = [self hmacEncryptSHA256ForData:encryptedData withKey:localShareKey];
    if (![calculatedHmac isEqualToData:hmacData]) {
        CIMLog(@"[增强帧协议] ❌ HMAC验证失败");
        CIMLog(@"[增强帧协议]    - 期望HMAC: %@", [self hexStringFromData:hmacData]);
        CIMLog(@"[增强帧协议]    - 计算HMAC: %@", [self hexStringFromData:calculatedHmac]);
        return nil;
    }
    
    CIMLog(@"[增强帧协议] ✅ HMAC验证成功");
    
    // 9. 解密数据（使用本地副本）
    NSData *decryptedData = [self AES256DecryptWithData:encryptedData key:localShareKey iv:ivData];
    if (!decryptedData) {
        CIMLog(@"[增强帧协议] ❌ AES解密失败");
        return nil;
    }
    
    CIMLog(@"[增强帧协议] ✅ 增强帧协议消息解析成功");
    CIMLog(@"[增强帧协议]    - 解密后数据长度: %lu字节", (unsigned long)decryptedData.length);
    
    return decryptedData;
}

@end
