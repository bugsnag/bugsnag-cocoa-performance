//
//  BugsnagPerformanceConfiguration.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import <BugsnagPerformance/BugsnagPerformanceErrors.h>
#import <BugsnagPerformance/BugsnagPerformanceNetworkRequestInfo.h>
#import <BugsnagPerformance/BugsnagPerformanceSpan.h>

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef BOOL (^ BugsnagPerformanceViewControllerInstrumentationCallback)(UIViewController *viewController);

typedef void (^ BugsnagPerformanceSpanStartCallback)(BugsnagPerformanceSpan *span);

typedef BOOL (^ BugsnagPerformanceSpanEndCallback)(BugsnagPerformanceSpan *span);

OBJC_EXPORT
@interface BugsnagPerformanceEnabledMetrics : NSObject

@property(nonatomic) BOOL rendering; // (default NO)
@property(nonatomic) BOOL cpu;       // (default NO)
@property(nonatomic) BOOL memory;    // (default NO)

- (instancetype) clone;

@end

OBJC_EXPORT
@interface BugsnagPerformanceConfiguration : NSObject

- (instancetype)initWithApiKey:(NSString *)apiKey NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)loadConfig;

- (BOOL) validate:(NSError * __autoreleasing _Nullable *)error NS_SWIFT_NAME(validate());

/**
 * Add a callback that gets called whenever a span is started.
 * This callback can be used to setup the span before it is
 * used (such as setting attributes). These callbacks are considered to be "inside" the span, so
 * any time taken to run the callback is counted towards the span's duration.
 *
 */
- (void) addOnSpanStartCallback:(BugsnagPerformanceSpanStartCallback) callback;

/**
 * Add a callback that gets called whenever a span ends.
 * If any of the registered callbacks returns false, the span is discarded.
 */
- (void) addOnSpanEndCallback:(BugsnagPerformanceSpanEndCallback) callback;

@property (nonatomic) NSString *apiKey;

@property (nonatomic) NSURL *_Nullable endpoint;

@property (nonatomic) BOOL autoInstrumentAppStarts;

@property (nonatomic) BOOL autoInstrumentViewControllers;

@property (nonatomic) BOOL autoInstrumentNetworkRequests;

@property (nonatomic) BOOL autoInstrumentRendering DEPRECATED_ATTRIBUTE;

@property(nonatomic,strong) BugsnagPerformanceEnabledMetrics *enabledMetrics;

/**
 *  The version of the application
 */
@property (copy, nullable, nonatomic) NSString *appVersion;

/**
 *  The app's bundleVersion
 */
@property (copy, nullable, nonatomic) NSString *bundleVersion;

/**
 *  The app's name
 */
@property (copy, nullable, nonatomic) NSString *serviceName;

/**
 *  Fixed sampling probability
 */
@property (nonatomic, nullable) NSNumber *samplingProbability;

@property (nullable, nonatomic) BugsnagPerformanceViewControllerInstrumentationCallback viewControllerInstrumentationCallback;

/**
 * Maximum length of attribute string values in characters. Any characters in excess of
 * this are discarded, and a warning message will be appended to the string value.
 *
 * Default: 1024
 * Range: 1 - 10000
 */
@property (nonatomic) NSUInteger attributeStringValueLimit;

/**
 * Maximum number of elements in an array. Any elements in excess of this are discarded.
 *
 * Default: 1000
 * Range: 1 - 10000
 */
@property (nonatomic) NSUInteger attributeArrayLengthLimit;

/**
 * Maximum number of attributes allowed in a single span.
 *
 * Default: 128
 * Range: 1 - 1000
 */
@property (nonatomic) NSUInteger attributeCountLimit;

@end

@interface BugsnagPerformanceConfiguration (/* App metadata */)

/**
 *  The release stage of the application, such as production, development, beta
 *  et cetera
 */
@property (copy, nonatomic) NSString *releaseStage;

/**
 *  Release stages which are allowed to notify Bugsnag
 */
@property (copy, nullable, nonatomic) NSSet<NSString *> *enabledReleaseStages;

/**
 * Callback used to control how network request spans are created.
 */
@property(nullable, nonatomic) BugsnagPerformanceNetworkRequestCallback networkRequestCallback;

/**
 * Any network request URLs that match one of these regular expressions will have the "traceparent" header injected.
 */
@property (copy, nullable, nonatomic) NSSet<NSRegularExpression *> *tracePropagationUrls;

@end

NS_ASSUME_NONNULL_END
