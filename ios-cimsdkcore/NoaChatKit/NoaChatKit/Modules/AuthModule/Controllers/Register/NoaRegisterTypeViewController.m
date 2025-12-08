//
//  NoaRegisterTypeViewController.m
//  NoaKit
//
//  Created by Mac on 2023/3/27.
//

#import "NoaRegisterTypeViewController.h"
#import "NoaRegisterTypeDataHandle.h"
#import "NoaRegisterTypeView.h"


#import "NoaRegisterViewController.h"
#import "NoaRegisterTypeModel.h"

@interface NoaRegisterTypeViewController ()

/// 注册数据处理
@property (nonatomic, strong) NoaRegisterTypeDataHandle *registerTypeDataHandle;

/// 注册类型选择
@property (nonatomic, strong) NoaRegisterTypeView *registerTypeView;

@property (nonatomic, strong)NSMutableArray *currentWaysArr;

@end

@implementation NoaRegisterTypeViewController

// MARK: dealloc
- (void)dealloc {
    CIMLog(@"%@ dealloc", [self class]);
}

// MARK: set/get
- (NoaRegisterTypeDataHandle *)registerTypeDataHandle {
    if (!_registerTypeDataHandle) {
        _registerTypeDataHandle = [[NoaRegisterTypeDataHandle alloc] initWithRegisterWay:self.registerWayArr
                                                                              AreaCode:self.areaCode];
    }
    return _registerTypeDataHandle;
}

- (NoaRegisterTypeView *)registerTypeView {
    if (!_registerTypeView) {
        _registerTypeView = [[NoaRegisterTypeView alloc] initWithFrame:CGRectZero
                                                          DataHandle:self.registerTypeDataHandle];
    }
    return _registerTypeView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navTitleLabel.text = LanguageToolMatch(@"选择注册方式");
    [self setupUI];
    [self processData];
}

- (void)setupUI {
    [self.view addSubview:self.registerTypeView];
    [self.registerTypeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.navView.mas_bottom).offset(0);
        make.leading.trailing.bottom.equalTo(self.view);
    }];
}

- (void)processData {
    @weakify(self)
    [self.registerTypeDataHandle.jumpRegisterDetailSubject subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        NoaRegisterTypeModel *registerTypeModel = x;
        NoaRegisterViewController *registerVC = [[NoaRegisterViewController alloc] init];
        registerVC.areaCode = self.areaCode;
        registerVC.currentRegisterWay = registerTypeModel.loginTypeMenu;
        if (registerTypeModel.loginTypeMenu == self.unusedAccountTypeMenu) {
            // 注册方式与未使用账号注册方式一致，传递到注册页面
            registerVC.unusedAccount = self.unusedAccountStr;
        }else {
            registerVC.unusedAccount = @"";
        }
        [self.navigationController pushViewController:registerVC animated:YES];
    }];
}

@end
