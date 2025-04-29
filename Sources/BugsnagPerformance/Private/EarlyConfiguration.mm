//
//  EarlyConfiguration.m
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 02.05.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import "EarlyConfiguration.h"
#import "Utils.h"

@implementation BSGEarlyConfiguration

- (instancetype) initWithBundleDictionary:(NSDictionary *)dict {
    if ((self = [super init])) {
        if (![[dict valueForKeyPath:@"bugsnag.performance.disableSwizzling"] boolValue]) {
            _enableSwizzling = YES;
        }
        id swizzleViewLoadPreMain = [dict valueForKeyPath:@"bugsnag.performance.swizzleViewLoadPreMain"];
        _swizzleViewLoadPreMain = swizzleViewLoadPreMain != nil && [swizzleViewLoadPreMain boolValue];
        _appWasLaunchedPreWarmed = [NSProcessInfo.processInfo.environment[@"ActivePrewarm"] isEqualToString:@"1"];
        _instrumentLoadView = [[dict valueForKeyPath:@"bugsnag.performance.swizzling.viewLoad.instrumentLoadView"] ?: @(YES) boolValue];
        _instrumentViewDidLoad = [[dict valueForKeyPath:@"bugsnag.performance.swizzling.viewLoad.instrumentViewDidLoad"] ?: @(YES) boolValue];
        _instrumentViewWillAppear = [[dict valueForKeyPath:@"bugsnag.performance.swizzling.viewLoad.instrumentViewWillAppear"] ?: @(YES) boolValue];
        _instrumentViewDidAppear = [[dict valueForKeyPath:@"bugsnag.performance.swizzling.viewLoad.instrumentViewDidAppear"] ?: @(YES)  boolValue];
        _instrumentViewWillLayoutSubviews = [[dict valueForKeyPath:@"bugsnag.performance.swizzling.viewLoad.instrumentViewWillLayoutSubviews"] ?: @(YES) boolValue];
        _instrumentViewDidLayoutSubviews = [[dict valueForKeyPath:@"bugsnag.performance.swizzling.viewLoad.instrumentViewDidLayoutSubviews"] ?: @(YES) boolValue];
        _instrumentNetwork = [[dict valueForKeyPath:@"bugsnag.performance.swizzling.instrumentNetwork"] ?: @(YES) boolValue];
    }

    BSGLogDebug(@"BSGEarlyConfiguration.enableSwizzling = %d", self.enableSwizzling);
    BSGLogDebug(@"BSGEarlyConfiguration.swizzleViewLoadPreMain = %d", self.swizzleViewLoadPreMain);
    BSGLogDebug(@"BSGEarlyConfiguration.appWasLaunchedPreWarmed = %d", self.appWasLaunchedPreWarmed);

    return self;
}

- (instancetype) init {
    NSString *infoPath = [NSBundle.mainBundle pathForResource:@"Info" ofType:@"plist"];
    NSMutableDictionary *infoDict = [[NSDictionary dictionaryWithContentsOfFile: infoPath] mutableCopy];
    if (infoDict == nil) {
        BSGLogWarning(@"Could not load Info.plist. Using defaults for early configuration");
        infoDict = [NSMutableDictionary new];
    }
    for (NSString *key in [[[NSProcessInfo processInfo] environment] allKeys]) {
        infoDict[key] = [[NSProcessInfo processInfo] environment][key];
    }
    return [self initWithBundleDictionary:infoDict];
}

@end
