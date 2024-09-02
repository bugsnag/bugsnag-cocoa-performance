//
//  BugsnagPerformanceConfiguration.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import "../Private/BugsnagPerformanceConfiguration+Private.h"

#import "../Private/Utils.h"
#import "../Private/ObjCUtils.h"

using namespace bugsnag;

@implementation BugsnagPerformanceConfiguration

- (instancetype)initWithApiKey:(NSString *)apiKey {
    if ((self = [super init])) {
        _internal = [BSGInternalConfiguration new];
        _apiKey = [apiKey copy];
        _endpoint = nsurlWithString([NSString stringWithFormat: @"https://%@.otlp.bugsnag.com/v1/traces", apiKey], nil);
        _autoInstrumentAppStarts = YES;
        _autoInstrumentViewControllers = YES;
        _autoInstrumentNetworkRequests = YES;
        _onSpanEndCallbacks = [NSMutableArray array];
#if defined(DEBUG) && DEBUG
        _releaseStage = @"development";
#else
        _releaseStage = @"production";
#endif
    }
    return self;
}

+ (instancetype)loadConfig {
    return [self loadConfigWithInfoDictionary:NSBundle.mainBundle.infoDictionary];
}

+ (instancetype)loadConfigWithInfoDictionary:(NSDictionary * _Nullable)infoDictionary {
    __block auto bugsnagConfiguration = BSGDynamicCast<NSDictionary>(infoDictionary[@"bugsnag"]);
    __block auto bugsnagPerformanceConfiguration = BSGDynamicCast<NSDictionary>(bugsnagConfiguration[@"performance"]);
    NSString *(^getSharedConfigValue)(NSString *) = ^NSString *(NSString *property) {
        return BSGDynamicCast<NSString>(bugsnagPerformanceConfiguration[property] ?: bugsnagConfiguration[property]);
    };
    NSArray<NSString *> *(^getSharedConfigArray)(NSString *) = ^NSArray<NSString *> *(NSString *property) {
        return BSGDynamicCast<NSArray<NSString *>>(bugsnagPerformanceConfiguration[property] ?: bugsnagConfiguration[property]);
    };
    auto apiKey = getSharedConfigValue(@"apiKey");
    auto appVersion = getSharedConfigValue(@"appVersion");
    auto bundleVersion = getSharedConfigValue(@"bundleVersion");
    auto releaseStage = getSharedConfigValue(@"releaseStage");
    auto enabledReleaseStages = getSharedConfigArray(@"enabledReleaseStages");
    
    auto serviceName = BSGDynamicCast<NSString>(bugsnagPerformanceConfiguration[@"service.name"]);
    auto endpoint = BSGDynamicCast<NSString>(bugsnagPerformanceConfiguration[@"endpoint"]);
    auto autoInstrumentAppStarts = BSGDynamicCast<NSNumber>(bugsnagPerformanceConfiguration[@"autoInstrumentAppStarts"]);
    auto autoInstrumentViewControllers = BSGDynamicCast<NSNumber>(bugsnagPerformanceConfiguration[@"autoInstrumentViewControllers"]);
    auto autoInstrumentNetworkRequests = BSGDynamicCast<NSNumber>(bugsnagPerformanceConfiguration[@"autoInstrumentNetworkRequests"]);
    auto samplingProbability = BSGDynamicCast<NSNumber>(bugsnagPerformanceConfiguration[@"samplingProbability"]);
    auto configuration = [[BugsnagPerformanceConfiguration alloc] initWithApiKey:apiKey];
    if (appVersion) {
        configuration.appVersion = appVersion;
    }
    if (bundleVersion) {
        configuration.bundleVersion = bundleVersion;
    }
    if (releaseStage) {
        configuration.releaseStage = releaseStage;
    }
    configuration.enabledReleaseStages = [NSSet setWithArray: enabledReleaseStages ?: @[]];
    if (serviceName) {
        configuration.serviceName = serviceName;
    }
    if (endpoint) {
        configuration.endpoint = [[NSURL alloc] initWithString: endpoint];
    }
    if (autoInstrumentAppStarts != nil) {
        configuration.autoInstrumentAppStarts = [autoInstrumentAppStarts boolValue];
    }
    if (autoInstrumentViewControllers != nil) {
        configuration.autoInstrumentViewControllers = [autoInstrumentViewControllers boolValue];
    }
    if (autoInstrumentNetworkRequests != nil) {
        configuration.autoInstrumentNetworkRequests = [autoInstrumentNetworkRequests boolValue];
    }
    if (samplingProbability != nil) {
        configuration.samplingProbability = samplingProbability;
    }
    return configuration;
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

- (BOOL)shouldSendReports {
    return self.enabledReleaseStages.count == 0 ||
           [self.enabledReleaseStages containsObject:self.releaseStage ?: @""];
}

- (void) addOnSpanEndCallback:(BugsnagPerformanceSpanEndCallback) callback {
    [self.onSpanEndCallbacks addObject:callback];
}

@end

@implementation BSGInternalConfiguration

- (instancetype)init {
    if ((self = [super init])) {
        _autoTriggerExportOnBatchSize = 100;

        _performWorkInterval = 30;

        _maxRetryAge = 24 * 60 * 60;

        _probabilityValueExpiresAfterSeconds = 24 * 3600;
        _probabilityRequestsPauseForSeconds = 30;

        _initialSamplingProbability = 1.0;

        _maxPackageContentLength = 1000000;

        // This gives time for the app to finish loading so that we can receive
        // any important notifications before the first work cycle is started.
        // It also gives time for us to receive our initial P value from the server.
        _initialRecurringWorkDelay = 1.0;
    }
    return self;
}

@end
