//
//  NoaLanguageManager.m
//  NoaKit
//
//  Created by Mac on 2022/12/28.
//

#import "NoaLanguageManager.h"
#import "NoaToolManager.h"
#import "FMDB.h"

static dispatch_once_t onceToken;

@interface NoaLanguageManager()

@property (nonatomic, strong) FMDatabase *db;

@end

@implementation NoaLanguageManager

#pragma mark - 单例的实现
+ (instancetype)shareManager{
    static NoaLanguageManager *_manager = nil;
    dispatch_once(&onceToken, ^{
        //不能再使用alloc方法
        //因为已经重写了allocWithZone方法，所以这里要调用父类的分配空间的方法
        _manager = [[super allocWithZone:NULL] init];
    });
    return _manager;
}
// 防止外部调用alloc 或者 new
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [NoaLanguageManager shareManager];
}

// 防止外部调用copy
- (id)copyWithZone:(nullable NSZone *)zone {
    return [NoaLanguageManager shareManager];
}

// 防止外部调用mutableCopy
- (id)mutableCopyWithZone:(nullable NSZone *)zone {
    return [NoaLanguageManager shareManager];
}
#pragma mark - 单例一般不需要清空，但是在执行某些功能的时候，防止数据清空不及时可以清空一下
- (void)clearManager{
    onceToken = 0;
}
//是否需要RTL布局
-(BOOL)isRTL{
    if([self.currentLanguage.languageName_zn isEqualToString:@"阿拉伯语"] ||
       [self.currentLanguage.languageName_zn isEqualToString:@"波斯语"]){
        return YES;
    }else{
        return NO;
    }
}
//初始化
- (void)initLanguageSetting {
    //默认展示多语言
    _isLanguageSetting = YES;
    _languageList = nil;
    _currentLanguage = nil;
    [self currentLanguage];
    
    [ZTOOL RTLConfig];
}

//获取App本地化语言设置信息(以App设置里为第一判断条件，以系统语音为第二判断条件)
- (NSString *)matchLocalLanguage:(NSString *)originalStr {
    NSString * languageAbbr;
    
    //印尼语 缩写 id 为关键字，改为 in_id, 只在读取 本地 语音文件时 使用 id 其余地方 均使用 in_id
    if([self.currentLanguage.languageAbbr isEqualToString:@"in_id"]){
        languageAbbr = @"id";
    }else{
        languageAbbr = self.currentLanguage.languageAbbr;
    }
    return [self matchLocalLanguage:originalStr languageAbbr:languageAbbr];
}

- (NSString *)matchLocalLanguage:(NSString *)originalStr languageAbbr:(NSString *)languageAbbr {
    NSString *path = [[NSBundle mainBundle] pathForResource:languageAbbr ofType:@"lproj"];
    NSString * word = [[NSBundle bundleWithPath:path] localizedStringForKey:originalStr value:nil table:nil];
    if(word){
        return word;
    }else{
        return originalStr;
    }
}


//根据当前语言类型返回隐私政策/用户协议对应的语言类型参数
- (NSString *)matchAgreementAndPolicyWithLocalLanguage {
    return self.currentLanguage.languageCode;
}

//根据后台返回的code码，返回对应翻译后的提示文字内容
- (NSString *)matchTranslateMessageFromCode:(NSInteger)errorCode errorMsg:(NSString *)errorMsg  {
    //获取errorCode和errorMsg对应的plist表内容
    NSString *netResultCodePath = [[NSBundle mainBundle] pathForResource:@"NoaNetResultCode" ofType:@"plist"];
    NSDictionary *NetResultCodeDic = [NSDictionary dictionaryWithContentsOfFile:netResultCodePath];
    
    NSString *keyStr = [NSString stringWithFormat:@"%ld", (long)errorCode];
    NSString *vauleStr;
    if ([NetResultCodeDic.allKeys containsObject:keyStr]) {
        vauleStr = [NetResultCodeDic objectForKeySafe:keyStr];
    } else {
        vauleStr = @"操作失败";
    }
    
    return LanguageToolMatch(vauleStr);
}

//通过获取当前设备的语种code匹配群公告翻译后的译文里的语种code
- (NSString *)languageCodeFromDevieInfo {
    if([self.currentLanguage.languageName_zn isEqualToString:@"系统语言"]) {
        NSString *languageCode = @"";
        NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
        NSArray  *array = [language componentsSeparatedByString:@"-"];
        if (array.count == 1) {
            languageCode = language;
        } else if (array.count == 2) {
            languageCode = [NSString stringWithFormat:@"%@", array[0]];
        } else if (array.count == 3) {
            languageCode = [NSString stringWithFormat:@"%@-%@", array[0], array[1]];
        } else {
            languageCode = language;
        }
        //从本地数据库里查找对应的MapLanguageCode
        NSString *dbPath = [[NSBundle mainBundle] pathForResource:@"noa_constant" ofType:@"db"];
        self.db = [[FMDatabase alloc] initWithPath:dbPath];
        if ([self.db open]) {
            //根据当前的语言，选择不同的国家名称展示
            NSString *sql =  [NSString stringWithFormat:@"SELECT mapCode FROM language WHERE languageTag = '%@'", languageCode];
            FMResultSet *rs = [self.db executeQuery:sql];//查询数据库
            // 处理查询结果
            while ([rs next]) {
                NSString *mapCode = [rs stringForColumn:@"mapCode"];
                if (mapCode.length <= 0) {
                    return @"en";
                } else {
                    return mapCode;
                }
            }
        }
        return @"en";
    } else {
        return self.currentLanguage.languageMapCode;
    }
}

- (NoaLanguageInfo *)currentLanguage{
    if (_currentLanguage == nil) {
        NSString * type = [[MMKV defaultMMKV] getStringForKey:Z_LANGUAGE_SELECTES_TYPE];
        if (type == nil) {
            //未设置语言情况下 默认 走跟随系统语音
            _currentLanguage = self.languageList.firstObject;
        }
        //从本地语音 列表中 获取语言信息
        for (NoaLanguageInfo * languageInfo in self.languageList) {
            if([languageInfo.languageName_zn isEqualToString:type]){
                _currentLanguage = languageInfo;
                break;
            }
        }
        if(_currentLanguage == nil){
            //如果找不到匹配的类型 默认显示英文
            _currentLanguage = self.languageList[3];
        }
        //配置第一个 跟跟随系统信息的配置
        NoaLanguageInfo * configInfo = self.languageList.firstObject;
        NoaLanguageInfo * languageInfo;
        if(_currentLanguage == configInfo){
            //如果用户 选择跟随系统配置 则 根据系统配置 获取 语音对象 配置 第一项
            NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
            NSArray  *array = [language componentsSeparatedByString:@"-"];
            NSString *systemLanguage = @"";
            if (array.count > 2) {
                systemLanguage = [NSString stringWithFormat:@"%@-%@", array[0], array[1]];
            } else {
                systemLanguage = [NSString stringWithFormat:@"%@", array[0]];
            }
            for (NoaLanguageInfo * info in self.languageList) {
                if([info.languageAbbr isEqualToString:systemLanguage]){
                    languageInfo = info;
                    break;
                }
            }
            if(languageInfo == nil){
                languageInfo = self.languageList[3];
            }
        }else{
            //如果用户 选择特定语言 则 特定语音对象 配置 第一项
            languageInfo = self.currentLanguage;
        }
        //config
        configInfo.languageAbbr = languageInfo.languageAbbr;
        configInfo.languageCode = languageInfo.languageCode;
        configInfo.languageName = [self matchLocalLanguage:configInfo.languageName_zn languageAbbr:languageInfo.languageAbbr];
        
    }
    return _currentLanguage;
}


-(NSArray<NoaLanguageInfo *> *)languageList{
    if (_languageList == nil) {
        
        NoaLanguageInfo * info0 = [NoaLanguageInfo new];
        info0.languageName_zn = @"系统语言";
        
        NoaLanguageInfo * info1 = [NoaLanguageInfo new];
        info1.languageName = @"简体中文";
        info1.languageAbbr = @"zh-Hans";
        info1.languageMapCode = @"zh";
        info1.languageName_zn = @"简体中文";
        info1.languageCode = @"1";
        
        NoaLanguageInfo * info2 = [NoaLanguageInfo new];
        info2.languageName = @"繁體中文";
        info2.languageAbbr = @"zh-Hant";
        info2.languageMapCode = @"cht";
        info2.languageName_zn = @"繁体中文";
        info2.languageCode = @"2";
        
        NoaLanguageInfo * info3 = [NoaLanguageInfo new];
        info3.languageName = @"English";
        info3.languageAbbr = @"en";
        info3.languageMapCode = @"en";
        info3.languageName_zn = @"英语";
        info3.languageCode = @"3";
        
        NoaLanguageInfo * info4 = [NoaLanguageInfo new];
        info4.languageName = @"Русский";
        info4.languageAbbr = @"ru";
        info4.languageMapCode = @"ru";
        info4.languageName_zn = @"俄语";
        info4.languageCode = @"4";
        
        NoaLanguageInfo * info5 = [NoaLanguageInfo new];
        info5.languageName = [NSString stringWithFormat:@"%@",@"عربي"];
        info5.languageAbbr = @"ar";
        info5.languageMapCode = @"ar";
        info5.languageName_zn = @"阿拉伯语";
        info5.languageCode = @"5";
        
        NoaLanguageInfo * info6 = [NoaLanguageInfo new];
        info6.languageName = @"Français";
        info6.languageAbbr = @"fr";
        info6.languageMapCode = @"fr";
        info6.languageName_zn = @"法语";
        info6.languageCode = @"6";
        
        NoaLanguageInfo * info7 = [NoaLanguageInfo new];
        info7.languageName = @"Кыргызча";
        info7.languageAbbr = @"ky";
        info7.languageMapCode = @"ky";
        info7.languageName_zn = @"吉尔吉斯语";
        info7.languageCode = @"7";
        
        NoaLanguageInfo * info8 = [NoaLanguageInfo new];
        info8.languageName = @"Oʻzbek tili";
        info8.languageAbbr = @"uz";
        info8.languageMapCode = @"uz";
        info8.languageName_zn = @"乌兹别克语";
        info8.languageCode = @"8";
        
        NoaLanguageInfo * info9 = [NoaLanguageInfo new];
        info9.languageName = [NSString stringWithFormat:@"%@",@"فارسی"];
        info9.languageAbbr = @"fa";
        info9.languageMapCode = @"fa";
        info9.languageName_zn = @"波斯语";
        info9.languageCode = @"9";
        
        NoaLanguageInfo * info10 = [NoaLanguageInfo new];
        info10.languageName = @"हिंदी";
        info10.languageAbbr = @"hi";
        info10.languageMapCode = @"hi";
        info10.languageName_zn = @"印地语";
        info10.languageCode = @"10";
        
        NoaLanguageInfo * info11 = [NoaLanguageInfo new];
        info11.languageName = @"español";
        info11.languageAbbr = @"es";
        info11.languageMapCode = @"es";
        info11.languageName_zn = @"西班牙语";
        info11.languageCode = @"11";
        
        NoaLanguageInfo * info12 = [NoaLanguageInfo new];
        info12.languageName = @"Türkçe";
        info12.languageAbbr = @"tr";
        info12.languageMapCode = @"tr";
        info12.languageName_zn = @"土耳其语";
        info12.languageCode = @"12";
        
        NoaLanguageInfo * info13 = [NoaLanguageInfo new];
        info13.languageName = @"বাংলা";
        info13.languageAbbr = @"bn";
        info13.languageMapCode = @"bn";
        info13.languageName_zn = @"孟加拉语";
        info13.languageCode = @"13";
        
        NoaLanguageInfo * info14 = [NoaLanguageInfo new];
        info14.languageName = @"bahasa Indonesia";
        info14.languageAbbr = @"in_id";
        info14.languageMapCode = @"id";
        info14.languageName_zn = @"印尼语";
        info14.languageCode = @"14";
        
        NoaLanguageInfo * info15 = [NoaLanguageInfo new];
        info15.languageName = @"Português (Brasil)";
        info15.languageAbbr = @"pt-BR";
        info15.languageMapCode = @"pt";
        info15.languageName_zn = @"葡萄牙语(巴西)";
        info15.languageCode = @"15";
        
        NoaLanguageInfo * info16 = [NoaLanguageInfo new];
        info16.languageName = @"Việt nam";
        info16.languageAbbr = @"vi";
        info16.languageMapCode = @"vi";
        info16.languageName_zn = @"越南语";
        info16.languageCode = @"16";
        
        NoaLanguageInfo * info17 = [NoaLanguageInfo new];
        info17.languageName = @"한국어";
        info17.languageAbbr = @"ko";
        info17.languageMapCode = @"ko";
        info17.languageName_zn = @"韩语";
        info17.languageCode = @"17";
        
        _languageList = @[info0,
                          info1,
                          info2,
                          info3,
                          info4,
                          info5,
                          info6,
                          info7,
                          info8,
                          info9,
                          info10,
                          info11,
                          info12,
                          info13,
                          info14,
                          info15,
                          info16,
                          info17];
    }
    return _languageList;
}

@end
