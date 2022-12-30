//
//  BugsnagPerformanceConfiguration.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import <BugsnagPerformance/BugsnagPerformanceConfiguration.h>

#import "../Private/Utils.h"
#import "../Private/ObjCUtils.h"

using namespace bugsnag;

static NSString *defaultEndpoint = @"https://otlp.bugsnag.com/v1/traces";

@implementation BugsnagPerformanceConfiguration

- (instancetype)initWithApiKey:(NSString *)apiKey error:(NSError * __autoreleasing _Nullable *)error {
    if (error != nil) {
        *error = nil;
    }
    if ((self = [super init])) {
        _apiKey = [apiKey copy];
        auto endpoint = nsurlWithString(defaultEndpoint, error);
        if (endpoint == nil) {
            NSLog(@"Initialization error: %@", *error);
            return nil;
        }
        _endpoint = endpoint;
        _autoInstrumentAppStarts = YES;
        _autoInstrumentViewControllers = YES;
        _autoInstrumentNetwork = YES;
#if defined(DEBUG) && DEBUG
        _releaseStage = @"development";
#else
        _releaseStage = @"production";
#endif
        _samplingProbability = 1.0;

        if (![self validate:error]) {
            return nil;
        }
    }
    return self;
}

+ (instancetype)loadConfig:(NSError * __autoreleasing _Nullable *)error {
    auto dict = BSGDynamicCast<NSDictionary>(NSBundle.mainBundle.infoDictionary[@"bugsnag"]);
    auto apiKey = BSGDynamicCast<NSString>(dict[@"apiKey"]);
    auto config = [[BugsnagPerformanceConfiguration alloc] initWithApiKey:apiKey error:error];
    return config;
}

- (BOOL) validate:(NSError * __autoreleasing _Nullable *)error {
    if (![self.endpoint.scheme hasPrefix:@"http"]) {
        *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:@{
            NSLocalizedDescriptionKey: @"Invalid configuration",
            NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:@"Invalid URL supplied for endpoint: \"%@\"", self.endpoint],
        }];
        return NO;
    }

    return YES;
}

@end
