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

typedef BOOL (^ BugsnagPerformanceSpanEndCallback)(BugsnagPerformanceSpan *span);

OBJC_EXPORT
@interface BugsnagPerformanceConfiguration : NSObject

- (instancetype)initWithApiKey:(NSString *)apiKey NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)loadConfig;

- (BOOL) validate:(NSError * __autoreleasing _Nullable *)error NS_SWIFT_NAME(validate());

/**
 * Add a callback that get called whenever a span ends.
 * If any of the registered callbacks returns false, the span is discarded.
 */
- (void) addOnSpanEndCallback:(BugsnagPerformanceSpanEndCallback) callback;

@property (nonatomic) NSString *apiKey;

@property (nonatomic) NSURL *_Nullable endpoint;

@property (nonatomic) BOOL autoInstrumentAppStarts;

@property (nonatomic) BOOL autoInstrumentViewControllers;

@property (nonatomic) BOOL autoInstrumentNetworkRequests;

/**
 *  The version of the application
 */
@property (copy, nullable, nonatomic) NSString *appVersion;

/**
 *  The app's bundleVersion
 */
@property (copy, nullable, nonatomic) NSString *bundleVersion;

/**
 *  The app's serviceName
 */
@property (copy, nullable, nonatomic) NSString *serviceName;

@property (nullable, nonatomic) BugsnagPerformanceViewControllerInstrumentationCallback viewControllerInstrumentationCallback;

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
