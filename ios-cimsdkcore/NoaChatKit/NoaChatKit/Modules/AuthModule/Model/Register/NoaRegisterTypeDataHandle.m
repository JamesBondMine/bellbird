//
//  NoaRegisterTypeModel.m
//  NoaChatKit
//
//  Created by phl on 2025/11/11.
//

#import "NoaRegisterTypeDataHandle.h"
#import "NoaRegisterTypeModel.h"

@interface NoaRegisterTypeDataHandle ()

/// 手机注册 - 区号
@property (nonatomic, copy, readwrite) NSString *areaCode;

/// 支持的注册方式
@property (nonatomic, strong, readwrite) NSArray *supportRegisterWay;

/// 支持的注册方式
@property (nonatomic, strong, readwrite) NSMutableArray <NoaRegisterTypeModel *>* registerTypeModelArr;

@end

@implementation NoaRegisterTypeDataHandle

// MARK: set/get
- (NSArray *)supportRegisterWay {
    if (!_supportRegisterWay) {
        _supportRegisterWay = [NSArray new];
    }
    return _supportRegisterWay;
}

- (NSMutableArray<NoaRegisterTypeModel *> *)registerTypeModelArr {
    if (!_registerTypeModelArr) {
        _registerTypeModelArr = [NSMutableArray new];
    }
    return _registerTypeModelArr;
}

- (RACSubject *)jumpRegisterDetailSubject {
    if (!_jumpRegisterDetailSubject) {
        _jumpRegisterDetailSubject = [RACSubject subject];
    }
    return _jumpRegisterDetailSubject;
}

- (instancetype)initWithRegisterWay:(NSArray *)supportRegisterWay
                           AreaCode:(NSString *)areaCode {
    self = [super init];
    if (self) {
        self.supportRegisterWay = supportRegisterWay;
        self.areaCode = areaCode;
        [self handleDataSource];
    }
    return self;
}

- (void)handleDataSource {
    NSMutableArray *dataSource = [NSMutableArray new];
    [self.supportRegisterWay enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NoaRegisterTypeModel *registerTypeModel = [NoaRegisterTypeModel new];
        ZLoginAndRegisterTypeMenu loginTypeMenu = [obj intValue];
        registerTypeModel.loginTypeMenu = loginTypeMenu;
        switch (loginTypeMenu) {
            case ZLoginTypeMenuAccountPassword:
                registerTypeModel.title = LanguageToolMatch(@"账号注册");
                registerTypeModel.subTitle = LanguageToolMatch(@"通过账号和密码注册");
                registerTypeModel.iconName = @"register_way_account";
                break;
            case ZLoginTypeMenuPhoneNumber:
                registerTypeModel.title = LanguageToolMatch(@"手机号注册");
                registerTypeModel.subTitle = LanguageToolMatch(@"通过手机号和验证码注册");
                registerTypeModel.iconName = @"register_way_phone";
                break;
            case ZLoginTypeMenuEmail:
                registerTypeModel.title = LanguageToolMatch(@"邮箱注册");
                registerTypeModel.subTitle = LanguageToolMatch(@"通过邮箱和验证码注册");
                registerTypeModel.iconName = @"register_way_email";
                break;
            default:
                break;
        }
        [dataSource addObject:registerTypeModel];
    }];
    
    self.registerTypeModelArr = dataSource;
}

- (NSInteger)getRegisterTypeCount {
    return self.registerTypeModelArr.count;
}

- (NoaRegisterTypeModel *)getRegisterTypeModelWithIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = indexPath.row;
    if (self.registerTypeModelArr.count > row) {
        return self.registerTypeModelArr[row];
    }
    return nil;
}

@end
