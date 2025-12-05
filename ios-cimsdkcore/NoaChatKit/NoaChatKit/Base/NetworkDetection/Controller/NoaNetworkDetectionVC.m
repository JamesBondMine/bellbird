//
//  NoaNetworkDetectionVC.m
//  NoaChatKit
//
//  Created by phl on 2025/10/15.
//  TODO: 网络检测页面

#import "NoaNetworkDetectionVC.h"
#import "NoaNetworkDetectionHandle.h"
#import "NoaNetworkDetectionView.h"

@interface NoaNetworkDetectionVC ()

@property (nonatomic, strong) NoaNetworkDetectionHandle *dataHandle;

@property (nonatomic, strong) NoaNetworkDetectionView *networkDetectionView;

@end

@implementation NoaNetworkDetectionVC

- (void)dealloc {
    CIMLog(@"%@ dealloc", [self class]);
}

// MARK: set/get
- (NoaNetworkDetectionHandle *)dataHandle {
    if (!_dataHandle) {
        _dataHandle = [[NoaNetworkDetectionHandle alloc] initWithCurrentSsoNumber:self.currentSsoNumber];
    }
    return _dataHandle;
}

- (NoaNetworkDetectionView *)networkDetectionView {
    if (!_networkDetectionView) {
        _networkDetectionView = [[NoaNetworkDetectionView alloc] initWithFrame:CGRectZero dataHandle:self.dataHandle];
    }
    return _networkDetectionView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configNavUI];
    [self setupUI];
}

// MARK: UI
/// 界面布局
- (void)configNavUI {
    self.navTitleStr = LanguageToolMatch(@"网络检测");
}

- (void)setupUI {
    [self.view addSubview:self.networkDetectionView];
    [self.networkDetectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.view);
        make.top.equalTo(self.navView.mas_bottom);
        make.bottom.equalTo(self.view);
    }];
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
