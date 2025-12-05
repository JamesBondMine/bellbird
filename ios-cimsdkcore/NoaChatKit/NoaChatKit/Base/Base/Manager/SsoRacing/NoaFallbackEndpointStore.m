//
//  NoaFallbackEndpointStore.m
//  NoaChatKit
//

#import "NoaFallbackEndpointStore.h"

static NSString *const kFallbackDomesticUrlsKey = @"ZIM_Fallback_Domestic_URLs";
static NSString *const kFallbackOverseasUrlsKey = @"ZIM_Fallback_Overseas_URLs";

@implementation NoaFallbackEndpointStore

+ (instancetype)shared {
    static NoaFallbackEndpointStore *s;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s = [[self alloc] init];
        [s loadFromDefaults];
    });
    return s;
}

- (void)loadFromDefaults {
    NSArray *dom = [[NSUserDefaults standardUserDefaults] objectForKey:kFallbackDomesticUrlsKey];
    NSArray *over = [[NSUserDefaults standardUserDefaults] objectForKey:kFallbackOverseasUrlsKey];
    if (![dom isKindOfClass:[NSArray class]] || ((NSArray *)dom).count == 0) {
        NSString *domesticUrlStr = kFallbackDomesticUrl;
        NSArray *domesticUrlArr = [domesticUrlStr componentsSeparatedByString:@","];
        dom = domesticUrlArr;
        [[NSUserDefaults standardUserDefaults] setObject:dom forKey:kFallbackDomesticUrlsKey];
    }
    if (![over isKindOfClass:[NSArray class]] || ((NSArray *)over).count == 0) {
        NSString *overseasUrlStr = kFallbackOverseasUrl;
        NSArray *overseasUrlArr = [overseasUrlStr componentsSeparatedByString:@","];
        over = overseasUrlArr;
        [[NSUserDefaults standardUserDefaults] setObject:over forKey:kFallbackOverseasUrlsKey];
    }
    self.domesticUrls = [dom copy];
    self.overseasUrls = [over copy];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)saveToDefaults {
    [[NSUserDefaults standardUserDefaults] setObject:self.domesticUrls ?: @[] forKey:kFallbackDomesticUrlsKey];
    [[NSUserDefaults standardUserDefaults] setObject:self.overseasUrls ?: @[] forKey:kFallbackOverseasUrlsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)updateIfDifferentDomestic:(NSArray<NSString *> *)domestic
                         overseas:(NSArray<NSString *> *)overseas {
    BOOL changed = NO;
    if (domestic.count > 0 && ![domestic isEqualToArray:self.domesticUrls]) {
        self.domesticUrls = [domestic copy];
        changed = YES;
    }
    if (overseas.count > 0 && ![overseas isEqualToArray:self.overseasUrls]) {
        self.overseasUrls = [overseas copy];
        changed = YES;
    }
    if (changed) {
        [self saveToDefaults];
    }
}

@end


