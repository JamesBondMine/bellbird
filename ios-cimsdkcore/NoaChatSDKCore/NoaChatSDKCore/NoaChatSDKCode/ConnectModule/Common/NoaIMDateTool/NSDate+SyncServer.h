//
//  NSDate+SyncServer.h
//  DateDemo
//
//  Created by mac on 2023/8/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDate (SyncServer)

//获取默认系统时间作为服务器返回时间的默认值
+ (void)getDefaultServerTimeFromSystem;

//获取服务端返回的时间戳(毫秒级)
+ (void)getMillisecondTimeFromServerWith:(NSURLResponse * __nullable)response;
//获取同步的服务器时间戳(毫秒级)
+ (long long)getSyncMillisecondTimeFromServer;
//获取校准后的服务器毫秒级时间戳(毫秒级)
+ (long long)getCurrentServerMillisecondTime;
//获取当前设备时间戳(毫秒级)
+(long long)getCurrentTimeIntervalWithSecond;
//UTC时间字符串
+ (NSString *)UTCDateTimeStr;
@end

NS_ASSUME_NONNULL_END
