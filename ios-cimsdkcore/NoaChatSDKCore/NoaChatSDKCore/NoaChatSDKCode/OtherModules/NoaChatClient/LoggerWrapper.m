//
//  LoggerWrapper.m
//  NoaChatSDKCore
//
//  Created by phl on 2025/1/27.
//

#import "LoggerWrapper.h"
#import <LocalLogLib/LocalLogLib-Swift.h>

void LoggerInfo(NSString * _Nonnull message) {
    [Logger info:message];
}

void LoggerError(NSString * _Nonnull message) {
    [Logger error:message];
}

void LoggerWarn(NSString * _Nonnull message) {
    [Logger warn:message];
}

void LoggerDebug(NSString * _Nonnull message) {
    [Logger debug:message];
}

void LoggerVerbose(NSString * _Nonnull message) {
    [Logger verbose:message];
}
