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

#define MIN_ATTRIBUTE_ARRAY_LENGTH_LIMIT 1
#define MAX_ATTRIBUTE_ARRAY_LENGTH_LIMIT 10000
#define DEFAULT_ATTRIBUTE_ARRAY_LENGTH_LIMIT 1000

#define MIN_ATTRIBUTE_STRING_VALUE_LIMIT 1
#define MAX_ATTRIBUTE_STRING_VALUE_LIMIT 10000
#define DEFAULT_ATTRIBUTE_STRING_VALUE_LIMIT 1024

#define MIN_ATTRIBUTE_COUNT_LIMIT 1
#define MAX_ATTRIBUTE_COUNT_LIMIT 1000
#define DEFAULT_ATTRIBUTE_COUNT_LIMIT 128

#define DEFAULT_URL_FORMAT @"https://%@.otlp.bugsnag.com/v1/traces"

@implementation BugsnagPerformanceEnabledMetrics

+ (instancetype) withAllEnabled {
    return [[BugsnagPerformanceEnabledMetrics alloc] initWithRendering:YES cpu:YES memory:YES];
}

- (instancetype) initWithRendering:(BOOL)rendering
                               cpu:(BOOL)cpu
                            memory:(BOOL)memory {
    if ((self = [super init])) {
        _rendering = rendering;
        _cpu = cpu;
        _memory = memory;
    }
    return self;
}

- (instancetype) init {
    return [self initWithRendering:NO cpu:NO memory:NO];
}

- (instancetype) clone {
    return [[BugsnagPerformanceEnabledMetrics alloc] initWithRendering:self.rendering
                                                                   cpu:self.cpu
                                                                memory:self.memory];
}

@end

@interface BugsnagPerformanceConfiguration ()
@property (nonatomic) BOOL didSetCustomEndpoint;
@end

@implementation BugsnagPerformanceConfiguration

- (instancetype)initWithApiKey:(NSString *)apiKey {
    if ((self = [super init])) {
        _internal = [BSGInternalConfiguration new];
        _apiKey = [apiKey copy];
        _endpoint = nsurlWithString([NSString stringWithFormat: DEFAULT_URL_FORMAT, apiKey], nil);
        _autoInstrumentAppStarts = YES;
        _autoInstrumentViewControllers = YES;
        _autoInstrumentNetworkRequests = YES;
        _enabledMetrics = [BugsnagPerformanceEnabledMetrics new];
        _onSpanEndCallbacks = [NSMutableArray array];
        _attributeArrayLengthLimit = DEFAULT_ATTRIBUTE_ARRAY_LENGTH_LIMIT;
        _attributeStringValueLimit = DEFAULT_ATTRIBUTE_STRING_VALUE_LIMIT;
        _attributeCountLimit = DEFAULT_ATTRIBUTE_COUNT_LIMIT;
        _didSetCustomEndpoint = NO;
#if defined(DEBUG) && DEBUG
        _releaseStage = @"development";
#else
        _releaseStage = @"production";
#endif
    }
    return self;
}

- (void)setAutoInstrumentRendering:(BOOL)autoInstrumentRendering {
    self.enabledMetrics.rendering = autoInstrumentRendering;
}

- (BOOL)autoInstrumentRendering {
    return self.enabledMetrics.rendering;
}

static inline NSUInteger minMaxDefault(NSUInteger value, NSUInteger min, NSUInteger max, NSUInteger def) {
    if(value < min) {
        return def;
    }
    if(value > max) {
        return max;
    }
    return value;
}

- (void) setAttributeArrayLengthLimit:(NSUInteger)limit {
    _attributeArrayLengthLimit = minMaxDefault(limit,
                                               MIN_ATTRIBUTE_ARRAY_LENGTH_LIMIT,
                                               MAX_ATTRIBUTE_ARRAY_LENGTH_LIMIT,
                                               DEFAULT_ATTRIBUTE_ARRAY_LENGTH_LIMIT);
}

- (void) setAttributeStringValueLimit:(NSUInteger)limit {
    _attributeStringValueLimit = minMaxDefault(limit,
                                               MIN_ATTRIBUTE_STRING_VALUE_LIMIT,
                                               MAX_ATTRIBUTE_STRING_VALUE_LIMIT,
                                               DEFAULT_ATTRIBUTE_STRING_VALUE_LIMIT);
}

- (void) setAttributeCountLimit:(NSUInteger)limit {
    _attributeCountLimit = minMaxDefault(limit,
                                         MIN_ATTRIBUTE_COUNT_LIMIT,
                                         MAX_ATTRIBUTE_COUNT_LIMIT,
                                         DEFAULT_ATTRIBUTE_COUNT_LIMIT);
}

- (void)setApiKey:(NSString *)apiKey {
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
    _apiKey = apiKey;
    if (!_didSetCustomEndpoint) {
        _endpoint = nsurlWithString([NSString stringWithFormat: DEFAULT_URL_FORMAT, apiKey], nil);
    }
}

- (void)setEndpoint:(NSURL *)endpoint {
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
    _endpoint = endpoint;
    _didSetCustomEndpoint = YES;
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

    auto serviceName = BSGDynamicCast<NSString>(bugsnagPerformanceConfiguration[@"serviceName"]);
    auto endpoint = BSGDynamicCast<NSString>(bugsnagPerformanceConfiguration[@"endpoint"]);
    auto tracePropagationUrls = BSGDynamicCast<NSArray<NSString *>>(bugsnagPerformanceConfiguration[@"tracePropagationUrls"]);
    auto autoInstrumentAppStarts = BSGDynamicCast<NSNumber>(bugsnagPerformanceConfiguration[@"autoInstrumentAppStarts"]);
    auto autoInstrumentViewControllers = BSGDynamicCast<NSNumber>(bugsnagPerformanceConfiguration[@"autoInstrumentViewControllers"]);
    auto autoInstrumentNetworkRequests = BSGDynamicCast<NSNumber>(bugsnagPerformanceConfiguration[@"autoInstrumentNetworkRequests"]);
    auto autoInstrumentRendering = BSGDynamicCast<NSNumber>(bugsnagPerformanceConfiguration[@"autoInstrumentRendering"]);
    auto samplingProbability = BSGDynamicCast<NSNumber>(bugsnagPerformanceConfiguration[@"samplingProbability"]);
    auto attributeArrayLengthLimit = BSGDynamicCast<NSNumber>(bugsnagPerformanceConfiguration[@"attributeArrayLengthLimit"]);
    auto attributeStringValueLimit = BSGDynamicCast<NSNumber>(bugsnagPerformanceConfiguration[@"attributeStringValueLimit"]);
    auto attributeCountLimit = BSGDynamicCast<NSNumber>(bugsnagPerformanceConfiguration[@"attributeCountLimit"]);
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
    if (tracePropagationUrls) {
        NSMutableSet<NSRegularExpression *> *exprs = [NSMutableSet setWithCapacity:tracePropagationUrls.count];
        for (NSString *pattern: tracePropagationUrls) {
            NSRegularExpression *expr = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
            if (expr != nil) {
                [exprs addObject:expr];
            }
        }
        [configuration setTracePropagationUrls:exprs];
    }
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
    if (autoInstrumentRendering != nil) {
        configuration.enabledMetrics.rendering = [autoInstrumentRendering boolValue];
    }
    if (samplingProbability != nil) {
        configuration.samplingProbability = samplingProbability;
    }
    if (attributeArrayLengthLimit != nil) {
        configuration.attributeArrayLengthLimit = attributeArrayLengthLimit.unsignedLongValue;
    }
    if (attributeStringValueLimit != nil) {
        configuration.attributeStringValueLimit = attributeStringValueLimit.unsignedLongValue;
    }
    if (attributeCountLimit != nil) {
        configuration.attributeCountLimit = attributeCountLimit.unsignedLongValue;
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
