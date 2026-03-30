//
//  EarlyConfiguration.m
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 02.05.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import "EarlyConfiguration.h"
#import "Utils.h"

using namespace bugsnag;

@implementation BSGEarlyConfiguration

+ (NSDictionary * _Nullable)bsg_loadConfigFromInfoDictionary:(NSDictionary *)infoDictionary {
    if (infoDictionary == nil) {
        return nil;
    }
    return BSGSelectedBugsnagDict(infoDictionary);
}

+ (NSDictionary * _Nullable)bsg_loadConfigWithBundle:(NSBundle *)bundle {
    if (bundle == nil) {
        return nil;
    }
    return [self bsg_loadConfigFromInfoDictionary:[bundle infoDictionary]];
}

- (instancetype) initWithBundleDictionary:(NSDictionary *)dict earlyPhaseStartTime:(CFAbsoluteTime)startTime {
    if ((self = [super init])) {
        _earlyPhaseStartTime = startTime;
        // Use centralized helper to pick a Bugsnag dict and then read the 'performance' settings.
        NSDictionary *selected = BSGSelectedBugsnagDict(dict);
        id disableSwizzling = BSGDynamicCast<NSDictionary>(selected)[@"performance"][@"disableSwizzling"];
        if (![disableSwizzling boolValue]) {
            _enableSwizzling = YES;
        }
        id swizzleViewLoadPreMain = BSGDynamicCast<NSDictionary>(selected)[@"performance"][@"swizzleViewLoadPreMain"];
        _swizzleViewLoadPreMain = swizzleViewLoadPreMain != nil && [swizzleViewLoadPreMain boolValue];

#if defined(DEBUG) && DEBUG
        _isDevelopment = YES;
#else
        _isDevelopment = NO;
#endif
    }

    return self;
}

- (instancetype) initWithEarlyPhaseStartTime:(CFAbsoluteTime)startTime {
    NSString *infoPath = [NSBundle.mainBundle pathForResource:@"Info" ofType:@"plist"];
    NSMutableDictionary *infoDict = [[NSDictionary dictionaryWithContentsOfFile: infoPath] mutableCopy];
    if (infoDict == nil) {
        BSGLogWarning(@"Could not load Info.plist. Using defaults for early configuration");
        infoDict = [NSMutableDictionary new];
    }
    for (NSString *key in [[[NSProcessInfo processInfo] environment] allKeys]) {
        infoDict[key] = [[NSProcessInfo processInfo] environment][key];
    }
    return [self initWithBundleDictionary:infoDict earlyPhaseStartTime:startTime];
}

@end
