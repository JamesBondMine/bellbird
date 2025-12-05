//
//  NoaSsoSetViewController.m
//  NoaKit
//
//  Created by Mac on 2022/9/1.
//

#import "NoaSsoSetViewController.h"
#import "NoaSsoHelpView.h"
#import "NoaToolManager.h"
#import "NoaInputTextView.h"
#import "NoaQRcodeScanViewController.h"
#import "AppUseTipView.h"//用户协议弹窗
#import "NoaFileOssInfoModel.h"
#import "NoaLanguageSetViewController.h"//多语言
#import "NoaNetSetViewController.h"
#import "NoaAlertTipView.h"
#import "NoaRaceCheckErrorViewController.h"
#import <CocoaAsyncSocket/GCDAsyncUdpSocket.h>
#import "NoaNetworkDetectionVC.h"

// 企业号输入、IP/域名
#import "NoaSsoAccountManagerView.h"

@interface NoaSsoSetViewController () <GCDAsyncUdpSocketDelegate>

/// 用户协议弹窗
@property (nonatomic, strong) AppUseTipView *viewTip;

/// udp工具，主要申请本地网络权限
@property (nonatomic, strong) GCDAsyncUdpSocket *udpSocket;

// 重新声明 blurView 为子类类型，覆盖父类的声明
@property (nonatomic, strong, readwrite) NoaSsoAccountManagerView *blurView;

/// 是否已经处理过本次竞速的错误提示（确保一次用户操作只显示一次错误）
@property (nonatomic, assign) BOOL hasHandledRacingError;

@end

@implementation NoaSsoSetViewController


// MARK: dealloc
- (void)dealloc {
    CIMLog(@"%@ dealloc", [self class]);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// 显式合成 blurView 属性，确保可以访问 _blurView 实例变量
@synthesize blurView = _blurView;

// MARK: set/get
- (NoaSsoAccountManagerView *)blurView {
    if (!_blurView) {
        _blurView = [[NoaSsoAccountManagerView alloc] initWithFrame:CGRectZero IsPopWindows:self.isPopWindows];
    }
    return _blurView;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (_viewTip && _viewTip.isHidden) {
        _viewTip.hidden = NO;
    }
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (_viewTip && !_viewTip.isHidden) {
        _viewTip.hidden = YES;
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    //检查app是否允许使用网络
    [self configNetWorkAuthority];
    
    // 断开连接，禁止重连-直到竞速成功
    [IMSDKManager toolDisconnectNoReconnect];
    
    // 取消网络质量检测(进入到企业号页面，用户需要输入企业号，故不需要网络质量检测 --- 需要用户在tcp竞速成功后，使用最新节点进行质量检测 --- 解决在用户输入企业号过程中，网络质量检测导致的节点切换问题)
    [[NoaUrlHostManager shareManager] stopNetworkQualityDetection];

    [self setupSsoSetUI];
    [self processData];

    //竞速/直连 完成后，接收结果
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(netWorkNodeRacingAndIpDomainConectResult:) name:@"AppSsoRacingAndIpDomainConectResultNotification" object:nil];
    
    //用户协议提示框
    [self showAppUserAgreement];
}

- (void)configNetWorkAuthority {
    BOOL isFirstUseApp = [[MMKV defaultMMKV] getBoolForKey:@"isFirstUseApp"];
    if (isFirstUseApp == NO) {
        //允许访问网络弹窗
        [NSString getDevicePublicNetworkIP];
        //允许访问本地网络弹窗
        [self requestLocalNetworkPermission];
        [[MMKV defaultMMKV] setBool:YES forKey:@"isFirstUseApp"];
    }
}

- (void)setupSsoSetUI {
    // 展示左上角的网络检测、系统语言，隐藏设置企业号
    [self showNetworkDetectionAndSystemLanguageButton:YES];
    [self showSsoAccountSetButton:NO];
    
    self.topTitleLabel.text = LanguageToolMatch(@"企业号登录");
    self.topSubTitleLabel.text = LanguageToolMatch(@"请输入您企业专属的企业号或IP/域名");
    [self.view addSubview:self.topTitleLabel];
    [self.view addSubview:self.topSubTitleLabel];
    
    [self.topTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.navView.mas_bottom).offset(34.5);
        make.leading.equalTo(@23);
        make.trailing.equalTo(self.view).offset(-23);
        make.height.equalTo(@37);
    }];
    
    [self.topSubTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.topTitleLabel.mas_bottom).offset(12);
        make.leading.equalTo(self.topTitleLabel);
        make.trailing.equalTo(self.view).offset(-23);
        make.height.equalTo(@12);
    }];
    
    // 展示版本号
    [self showAppVersion];
}

- (void)processData {
    @weakify(self)
    self.blurView.clickLoginBtnAction = ^(ZSsoTypeMenu ssoType, NSString * _Nonnull ssoText) {
        @strongify(self)
        if (ssoType == ZSsoTypeMenuCompanyId) {
            if (ssoText.length == 0) {
                [HUD showMessage:LanguageToolMatch(@"企业号错误") inView:self.view];
                return;
            }
            
            [HUD showActivityMessage:@""];
            //请求 检查接口，节点竞速
            [self saveUserInputCompanyIdSSoInfo:ssoText];
        }else if (ssoType == ZSsoTypeMenuIPAndDomain) {
            if (ssoText.length == 0) {
                [HUD showMessage:LanguageToolMatch(@"域名错误") inView:self.view];
                return;
            }

            [HUD showActivityMessage:@""];
            [self saveUserInputIPAndDomainSSoInfo:ssoText];
        }else {
            // 未知类型
        }
    };
    
    self.blurView.clickHelpBtnAction = ^{
        @strongify(self)
        NoaSsoHelpView *helpView = [[NoaSsoHelpView alloc] init];
        [self.view addSubview:helpView];
        [helpView show];
    };
    
    self.blurView.clickNetworkDetectionBtnAction = ^(NSString * _Nonnull ssoText) {
        @strongify(self)
        NoaNetworkDetectionVC *vc = [NoaNetworkDetectionVC new];
        vc.currentSsoNumber = ssoText;
        [self.navigationController pushViewController:vc animated:YES];
    };
    
    self.blurView.clickScanBtnAction = ^{
        @strongify(self)
        //企业号 扫一扫
        NoaQRcodeScanViewController *vc = [[NoaQRcodeScanViewController alloc] init];
        vc.isRacing = YES;
        [self.navigationController pushViewController:vc animated:YES];
        [vc setQRcodeSacnLicenseBlock:^(NSString * _Nonnull liceseId, NSString * _Nonnull ipDomainPort) {
            @strongify(self)
            //扫码后结果处理
            [self qrcodeScanResultHandlerWithLiceseId:liceseId ipDomainPort:ipDomainPort];
        }];
        [vc setQRcodeSacnNavBlock:^(IMServerListResponseBody * _Nonnull model, NSString *appKey) {
            @strongify(self)
            if ([NoaSsoInfoModel isConfigSSO]) {
                NoaSsoInfoModel *infoModel = [NoaSsoInfoModel getSSOInfo];
                infoModel.liceseId = appKey;
                [infoModel saveSSOInfo];
            } else {
                NoaSsoInfoModel *infoModel = [NoaSsoInfoModel new];
                infoModel.liceseId = appKey;
                [infoModel saveSSOInfo];
            }
            
            // 修改信息
            [self.blurView scanQrcodeChangeSsoType:ZSsoTypeMenuCompanyId SsoInfo:appKey];
            
            // 竞速导航
            ZHostTool.isReloadRacing = NO;
            [ZHostTool QRcodeSacnNav:model];
        }];
    };
}

#pragma mark - 扫一扫
- (void)qrcodeScanResultHandlerWithLiceseId:(NSString *)liceseId ipDomainPort:(NSString *)ipDomainPort {
    NSString *liceseIdStr = [NSString isNil:liceseId] ? @"" : liceseId;
    NSString *ipDomainPortStr = [NSString isNil:ipDomainPort] ? @"" : ipDomainPort;
    
    if (liceseIdStr.length > 0) {
        // 修改信息
        [self.blurView scanQrcodeChangeSsoType:ZSsoTypeMenuCompanyId SsoInfo:liceseIdStr];
        [HUD showActivityMessage:@""];
        [self saveUserInputCompanyIdSSoInfo:liceseIdStr];
        return;
    }
    
    if (ipDomainPortStr.length > 0) {
        // 修改信息
        [self.blurView scanQrcodeChangeSsoType:ZSsoTypeMenuIPAndDomain SsoInfo:liceseIdStr];
        [HUD showActivityMessage:@""];
        [self saveUserInputIPAndDomainSSoInfo:ipDomainPortStr];
    }
}

#pragma mark - Action
//输入的是企业号，走SSO竞速
- (void)saveUserInputCompanyIdSSoInfo:(NSString *)liceseId {
    // 重置错误处理标志，表示开始新的竞速流程
    self.hasHandledRacingError = NO;
    
    //需要先设置，不然该接口没有host,请求不通
    NoaSsoInfoModel *tempSsoModel = [NoaSsoInfoModel getSSOInfo];
    if (!tempSsoModel) {
        tempSsoModel = [[NoaSsoInfoModel alloc] init];
    }
    tempSsoModel.liceseId = liceseId;
    tempSsoModel.ipDomainPortStr = @"";
    [tempSsoModel saveSSOInfo];
    [[MMKV defaultMMKV] removeValueForKey:[NSString stringWithFormat:@"%@%@",CONNECT_LOCAL_CACHE,liceseId]];
    [NoaSsoInfoModel clearSSOInfoWithLiceseId:liceseId];
    
    [ZTOOL doAsync:^{
        //节点竞速
        ZHostTool.isReloadRacing = NO;
        [ZHostTool startHostNodeRace];
    } completion:^{
    }];
    
}

//输入的是 IP/域名 请求SystemSetting信息
- (void)saveUserInputIPAndDomainSSoInfo:(NSString *)ipDomainPortStr {
    // 重置错误处理标志，表示开始新的竞速流程
    self.hasHandledRacingError = NO;
    
    //去除用户可能输入的 http:// 或者 https://
    NSString *resultIpDomain = [ipDomainPortStr stringByReplacingOccurrencesOfString:@"http://" withString:@""];
    resultIpDomain = [resultIpDomain stringByReplacingOccurrencesOfString:@"https://" withString:@""];
    //需要先设置，不然该接口没有host,请求不通
    NoaSsoInfoModel *tempSsoModel = [NoaSsoInfoModel getSSOInfo];
    if (!tempSsoModel) {
        tempSsoModel = [[NoaSsoInfoModel alloc] init];
    }
    tempSsoModel.liceseId = @"";
    tempSsoModel.ipDomainPortStr = resultIpDomain;
    [tempSsoModel saveSSOInfo];
    
    [ZTOOL doAsync:^{
        //请求SystemSetting接口
        ZHostTool.isReloadRacing = NO;
        [ZHostTool startHostNodeRace];
    } completion:^{
    }];
}

#pragma mark - Notification
//SSO竞速结果 或者 IP/Domain直连 结果，通过Notificaiton进行结果传递
- (void)netWorkNodeRacingAndIpDomainConectResult:(NSNotification *)notification {
    @weakify(self)
    
    NoaSsoInfoModel *tempSsoModel = [NoaSsoInfoModel getSSOInfo];
    if (!tempSsoModel) {
        tempSsoModel = [[NoaSsoInfoModel alloc] init];
    }
    
    NSDictionary *dict = notification.userInfo;
    ZNetRacingStep step = [[dict objectForKey:@"step"] integerValue];
    NSInteger code = [[dict objectForKey:@"code"] integerValue];
    BOOL result = [[dict objectForKey:@"result"] boolValue];
    NSString *errorCode = [dict objectForKeySafe:@"errorCode"];
    
    if (result) {
        // 竞速成功，重置错误处理标志
        self.hasHandledRacingError = NO;
        
        tempSsoModel.lastLiceseId = tempSsoModel.liceseId;
        tempSsoModel.lastIPDomainPortStr = tempSsoModel.ipDomainPortStr;
        [tempSsoModel saveSSOInfo];
        if (self.isReset) {
            //重新设置lecseId，竞速完成后
            [ZTOOL doInMain:^{
                //Login & Register
                [ZTOOL setupLoginUI];
            }];
        } else {
            //竞速成功
            if (self.isRoot) {
                [ZTOOL doInMain:^{
                    //Login & Register
                    [ZTOOL setupLoginUI];
                }];
            } else {
                [ZTOOL doInMain:^{
                    @strongify(self)
                    [self.navigationController popViewControllerAnimated:YES];
                    if (self.configSsoInfoFinish) {
                        self.configSsoInfoFinish();
                    }
                }];
            }
        }
    } else {
        //竞速失败
        // 确保一次用户操作（saveUserInputCompanyIdSSoInfo 或 saveUserInputIPAndDomainSSoInfo）只显示一次错误提示
        if (self.hasHandledRacingError) {
            return;
        }
        // 标记已处理，防止后续通知重复显示
        self.hasHandledRacingError = YES;
        
        tempSsoModel.liceseId = tempSsoModel.lastLiceseId;
        tempSsoModel.ipDomainPortStr = tempSsoModel.lastIPDomainPortStr;
        [tempSsoModel saveSSOInfo];
        
        switch (step) {
            case ZNetRacingStepOss:
            {
                NSString *lastTwo = errorCode.length >= 2 ? [errorCode substringFromIndex:errorCode.length - 2] : errorCode;
                if ([lastTwo isEqualToString:@"01"]) {
                    [self showErrorMessageWithMessage:[NSString stringWithFormat:@"%@%@",LanguageToolMatch(@"获取企业号配置失败"),errorCode] errorCode:errorCode];
                } else {
                    //OSS
                    if (code == 100000) {
                        [self showErrorMessageWithMessage:[NSString stringWithFormat:@"%@%@",LanguageToolMatch(@"服务器连接失败 ，请联系管理员"),errorCode] errorCode:errorCode];
                    } else {
                        if (code == 404 || code == 403) {
                            //不存在时：阿里云返回404，亚马逊返回403
                            [self showErrorMessageWithMessage:[NSString stringWithFormat:@"%@%@",LanguageToolMatch(@"获取企业号配置失败"),errorCode] errorCode:errorCode];
                        } else {
                            [self showErrorMessageWithMessage:[NSString stringWithFormat:@"%@%@",LanguageToolMatch(@"服务器连接失败"),errorCode] errorCode:errorCode];
                        }
                    }
                }
                
            }
                break;
            case ZNetRacingStepHttp:
            {
                //Http
                [self showErrorMessageWithMessage:[NSString stringWithFormat:@"%@%@",LanguageToolMatch(@"获取配置失败"),errorCode] errorCode:errorCode];
            }
                break;
            case ZNetRacingStepTcp:
            {
                //Tcp
                [self showErrorMessageWithMessage:[NSString stringWithFormat:@"%@%@",LanguageToolMatch(@"IM连接失败"),errorCode] errorCode:errorCode];
            }
                break;
            case ZNetIpDomainStepHttp:
            {
                //IP/Domain Http
                [self showErrorMessageWithMessage:[NSString stringWithFormat:@"%@%@",LanguageToolMatch(@"获取配置失败"),errorCode] errorCode:errorCode];
            }
                break;
            case ZNetIpDomainStepTcp:
            {
                //IP/Domain Tcp
                [self showErrorMessageWithMessage:[NSString stringWithFormat:@"%@%@",LanguageToolMatch(@"IM连接失败"),errorCode] errorCode:errorCode];
            }
                break;
            default:
                break;
        }
    }
}
- (void)sentryUploadWithErrorMessage:(NSString *)errorMessage errorCode:(NSString *)errorCode {
    [ZTOOL sentryUploadWithString:errorMessage sentryUploadType:ZSentryUploadTypeEnterprise errorCode:errorCode];
}

/// 显示错误消息
- (void)showErrorMessageWithMessage:(NSString *)message errorCode:(NSString *)errorCode {
    @weakify(self)
    [ZTOOL doInMain:^{
        @strongify(self)
        // showMessage 内部已经会调用 hideHUD，所以不需要提前调用
        [HUD showMessage:message inView:self.view];
        [self sentryUploadWithErrorMessage:message errorCode:errorCode];
    }];
}


#pragma mark - 用户协议提示框
- (void)showAppUserAgreement {
    BOOL agreeAgreement = [[MMKV defaultMMKV] getBoolForKey:@"AgreeUserAgreement"];
    if (!agreeAgreement) {
        _viewTip = [AppUseTipView new];
        [_viewTip showAppUserAgreement];
    }
}

#pragma mark - 允许访问本地网络弹窗
- (void)requestLocalNetworkPermission {
    self.udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];

    NSError *error = nil;
    if (![self.udpSocket bindToPort:12345 error:&error]) {
        NSLog(@"Error binding: %@", error);
        return;
    }
    if (![self.udpSocket beginReceiving:&error]) {
        NSLog(@"Error receiving: %@", error);
        return;
    }

    NSString *message = @"Hello, local network!";
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    [self.udpSocket sendData:data toHost:@"255.255.255.255" port:12345 withTimeout:-1 tag:0];
}

#pragma mark - GCDAsyncUdpSocketDelegate
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag {
    NSLog(@"Data sent");
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error {
    NSLog(@"Did not send data: %@", error);
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext {
    NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"Received: %@", message);
}
  
@end
