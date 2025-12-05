//
//  NSArray+Addition.m
//  NoaIMChatService
//
//  Created by mac on 2022/7/8.
//

#import "NSArray+Addition.h"
#import "FMDB.h"
#import "NoaMessageModel.h"

@implementation NSArray (Addition)
- (id)objectAtIndexSafe:(NSUInteger)index{
    if (index < self.count){
        return self[index];
    }
    
    return nil;
}
@end


@implementation NSMutableArray (Addition)
    
-(void)addObjectIfNotNil:(id)anObject
    {
        if (anObject)
        {
            [self addObject:anObject];
        }
    }
    
-(NSArray *)objectsTop:(NSUInteger)aTopNumber {
    NSUInteger number = MIN(aTopNumber, self.count);
    
    if (number > 0) {
        NSMutableArray *arr = [NSMutableArray arrayWithCapacity:number];
        for (int i = 0; i < number; i++) {
            [arr addObject:self[i]];
        }
        return arr;
    }
    
    return nil;
}
    
- (NSArray *)reverse {
    if ([self count] == 0)
    return self;
    
    NSUInteger i = 0;
    NSUInteger j = [self count] - 1;
    while (i < j) {
        [self exchangeObjectAtIndex:i
                  withObjectAtIndex:j];
        
        i++;
        j--;
    }
    
    return self;
}
    
-(void)insertObjectIfNotNil:(id)anObject atIndex:(NSInteger)index{
    if (anObject) {
        [self insertObject:anObject atIndex:index];
    }
}

- (void)removeObjectAtIndexSafe:(NSUInteger)index{
    if (index < self.count) {
        [self removeObjectAtIndex:index];
    }
}

+ (NSMutableArray *)searchCountryArea:(NSString *)name {
    NSMutableArray *resultArr = [NSMutableArray array];
    NSString *sql= [NSString stringWithFormat:@"select * from SMS_country where (zh like '%%%@%%' or en like '%%%@%%' or es like '%%%@%%' or prefix like '%%%@%%' or emojiLogo like '%%%@%%') order by countryPinyin asc",name,name,name,name,name];
    NSString *dbPath = [[NSBundle mainBundle] pathForResource:@"noa_constant" ofType:@"db"];
    FMDatabase *db = [[FMDatabase alloc] initWithPath:dbPath];
    if ([db open]) {
        FMResultSet *rs = [db executeQuery:sql];
        while ([rs next]) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setObjectSafe:[rs objectForColumn:@"id"] forKey:@"id"];
            [dict setObjectSafe:[rs objectForColumn:@"zh"] forKey:@"zh-Hans"];
            [dict setObjectSafe:[rs objectForColumn:@"big5"] forKey:@"zh-Hant"];
            [dict setObjectSafe:[rs objectForColumn:@"en"] forKey:@"en"];
            [dict setObjectSafe:[rs objectForColumn:@"es"] forKey:@"es"];
            [dict setObjectSafe:[rs objectForColumn:@"ar"] forKey:@"ar"];
            [dict setObjectSafe:[rs objectForColumn:@"bn"] forKey:@"bn"];
            [dict setObjectSafe:[rs objectForColumn:@"fa"] forKey:@"fa"];
            [dict setObjectSafe:[rs objectForColumn:@"fr"] forKey:@"fr"];
            [dict setObjectSafe:[rs objectForColumn:@"hi"] forKey:@"hi"];
            [dict setObjectSafe:[rs objectForColumn:@"ky"] forKey:@"ky"];
            [dict setObjectSafe:[rs objectForColumn:@"ru"] forKey:@"ru"];
            [dict setObjectSafe:[rs objectForColumn:@"tr"] forKey:@"tr"];
            [dict setObjectSafe:[rs objectForColumn:@"uz"] forKey:@"uz"];
            [dict setObjectSafe:[rs objectForColumn:@"pt_BR"] forKey:@"pt-BR"];
            [dict setObjectSafe:[rs objectForColumn:@"in_id"] forKey:@"in_id"];
            [dict setObjectSafe:[rs objectForColumn:@"vi"] forKey:@"vi"];
            [dict setObjectSafe:[rs objectForColumn:@"ko"] forKey:@"ko"];
            [dict setObjectSafe:[rs objectForColumn:@"prefix"] forKey:@"prefix"];
            [dict setObjectSafe:[rs objectForColumn:@"price"] forKey:@"price"];
            [dict setObjectSafe:[rs objectForColumn:@"emojiLogo"] forKey:@"emojiLogo"];
            [resultArr addObject:dict];
        }
        [db close];
    }
    
    return resultArr;
}

//多选-对已选择的消息按照sendTime进行排序
+ (NSArray *)sortMultiSelectedMessageArr:(NSMutableArray *)array {
    
    // 创建 sendtime 的排序描述符
    NSSortDescriptor *sendTimeDescriptor = [[NSSortDescriptor alloc] initWithKey:@"message.sendTime" ascending:YES];

    // 创建 sendid 的排序描述符
    NSSortDescriptor *sendIdDescriptor = [[NSSortDescriptor alloc] initWithKey:@"message.serviceMsgID" ascending:YES];

    // 将排序描述符放入数组中，按照数组顺序依次进行排序
    NSArray *sortDescriptors = @[sendTimeDescriptor, sendIdDescriptor];

    // 对数组进行排序
    NSArray *sortedArray = [array sortedArrayUsingDescriptors:sortDescriptors];
    
    return sortedArray;
}
@end
