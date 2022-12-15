//
//  BugsnagPerformanceConfiguration.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import <BugsnagPerformance/BugsnagPerformanceConfiguration.h>

#import "../Private/Utils.h"

using namespace bugsnag;

@implementation BugsnagPerformanceConfiguration

static NSURL *urlWithString(NSString * _Nonnull str) {
    auto url = [NSURL URLWithString:str];
    if (url == nil) {
        [NSException raise:@"Invalid configuration" format:@"Invalid URL: \"%@\"", str];
    }
    return url;
}

- (instancetype)initWithApiKey:(NSString *)apiKey {
    if ((self = [super init])) {
        _apiKey = [apiKey copy];
        _endpoint = urlWithString(@"https://otlp.bugsnag.com/v1/traces");
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

- (void) validate {
    if (![self.endpoint.scheme hasPrefix:@"http"]) {
        [NSException raise:@"Invalid configuration" format:@"Invalid URL supplied for endpoint: \"%@\"", self.endpoint];
    }
}

@end
