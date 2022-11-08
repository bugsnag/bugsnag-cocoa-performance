//
//  BugsnagPerformanceConfiguration.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import <BugsnagPerformance/BugsnagPerformanceConfiguration.h>

#import "../Private/Utils.h"

@implementation BugsnagPerformanceConfiguration

- (instancetype)initWithApiKey:(NSString *)apiKey {
    if ((self = [super init])) {
        _apiKey = [apiKey copy];
        _endpoint = @"https://127.0.0.0";
        _autoInstrumentAppStarts = YES;
        _autoInstrumentViewControllers = YES;
        _autoInstrumentNetwork = YES;
#if defined(DEBUG) && DEBUG
        _releaseStage = @"development";
#else
        _releaseStage = @"production";
#endif
        _samplingProbability = 1.0;
    }
    return self;
}

+ (instancetype)loadConfig {
    auto dict = BSGDynamicCast<NSDictionary>(NSBundle.mainBundle.infoDictionary[@"bugsnag"]);
    auto apiKey = BSGDynamicCast<NSString>(dict[@"apiKey"]);
    auto config = [[BugsnagPerformanceConfiguration alloc] initWithApiKey:apiKey];
    return config;
}

@end
