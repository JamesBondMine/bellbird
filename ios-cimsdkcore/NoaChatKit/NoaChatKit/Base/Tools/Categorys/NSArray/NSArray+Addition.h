//
//  NSArray+Addition.h
//  NoaIMChatService
//
//  Created by mac on 2022/7/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSArray (Addition)
- (id)objectAtIndexSafe:(NSUInteger)index;
@end


@interface NSMutableArray (Addition)
- (void)addObjectIfNotNil:(id)anObject;
- (void)insertObjectIfNotNil:(id)anObject atIndex:(NSInteger)index;
- (NSArray *)objectsTop:(NSUInteger)aTopNumber;
    
- (NSArray *)reverse;

- (void)removeObjectAtIndexSafe:(NSUInteger)index;

+ (NSMutableArray *)searchCountryArea:(NSString *)name;

//多选-对已选择的消息按照sendTime进行排序
+ (NSArray *)sortMultiSelectedMessageArr:(NSMutableArray *)array;

@end
NS_ASSUME_NONNULL_END
