//
//  NoaRegisterTypeModel.h
//  NoaChatKit
//
//  Created by phl on 2025/11/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class NoaRegisterTypeModel;

@interface NoaRegisterTypeDataHandle : NSObject

/// 初始化方法
/// - Parameters:
///   - supportRegisterWay: 支持的注册方法
///   - areaCode: 手机号码对应区号
- (instancetype)initWithRegisterWay:(NSArray *)supportRegisterWay
                           AreaCode:(NSString *)areaCode;

/// 获取有几种注册方式
- (NSInteger)getRegisterTypeCount;

/// 通过位置获取ZRegisterTypeModel
/// - Parameter indexPath: 位置
- (NoaRegisterTypeModel *)getRegisterTypeModelWithIndexPath:(NSIndexPath *)indexPath;

/// 跳转注册详情
@property (nonatomic, strong) RACSubject *jumpRegisterDetailSubject;

@end

NS_ASSUME_NONNULL_END
