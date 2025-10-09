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
    }

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
