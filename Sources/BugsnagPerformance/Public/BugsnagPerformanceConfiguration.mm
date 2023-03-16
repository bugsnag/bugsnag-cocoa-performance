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

- (instancetype)initWithApiKey:(NSString *)apiKey {
    if ((self = [super init])) {
        _apiKey = [apiKey copy];
        _endpoint = nsurlWithString(defaultEndpoint, nil);
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
    return [[BugsnagPerformanceConfiguration alloc] initWithApiKey:apiKey];
}

- (BOOL) validate:(NSError * __autoreleasing _Nullable *)error {
    NSError *__autoreleasing _Nullable dummyError;
    if (error == nil) {
        error = &dummyError;
    }
    if (self.apiKey.length == 0) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:
                        @"No Bugsnag API key has been provided" userInfo:nil];
    }
    if (![self.endpoint.scheme hasPrefix:@"http"]) {
        *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:@{
            NSLocalizedDescriptionKey: @"Invalid configuration",
            NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:@"Invalid URL supplied for endpoint: \"%@\"", self.endpoint],
        }];
        return NO;
    }

    if (![self isValidApiKey:self.apiKey]) {
        *error = [NSError errorWithDomain:BugsnagPerformanceConfigurationErrorDomain
                                     code:BugsnagPerformanceConfigurationBadApiKey
                                 userInfo:@{
            NSLocalizedDescriptionKey: @"Invalid configuration",
            NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:@"Invalid API key: \"%@\"", self.apiKey],
        }];
        return NO;
    }

    *error = nil;
    return YES;
}

- (BOOL)isValidApiKey:(NSString *)apiKey {
    static const int BSGApiKeyLength = 32;
    NSCharacterSet *chars = [[NSCharacterSet
        characterSetWithCharactersInString:@"0123456789ABCDEF"] invertedSet];

    BOOL isHex = (NSNotFound == [[apiKey uppercaseString] rangeOfCharacterFromSet:chars].location);

    return isHex && [apiKey length] == BSGApiKeyLength;
}

@end
