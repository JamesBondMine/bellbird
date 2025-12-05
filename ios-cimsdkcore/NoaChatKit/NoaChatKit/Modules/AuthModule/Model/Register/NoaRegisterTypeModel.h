//
//  NoaRegisterTypeModel.h
//  NoaChatKit
//
//  Created by phl on 2025/11/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NoaRegisterTypeModel : NSObject

@property (nonatomic, copy) NSString *title;

@property (nonatomic, copy) NSString *subTitle;

@property (nonatomic, copy) NSString *iconName;

@property (nonatomic, assign) ZLoginAndRegisterTypeMenu loginTypeMenu;

@end

NS_ASSUME_NONNULL_END
