//
//  BugsnagPerformanceCrossTalkAPI.mm
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 10.05.24.
//  Copyright © 2024 Bugsnag. All rights reserved.
//

#import "BugsnagPerformanceCrossTalkAPI.h"
#import <objc/runtime.h>

@interface BugsnagPerformanceCrossTalkAPI ()
@property(readwrite, nonatomic) BugsnagPerformanceConfiguration *configuration;
@end

@implementation BugsnagPerformanceCrossTalkAPI

#pragma mark Exposed API

/**
 * Return the current trace and span IDs as strings in a 2-entry array, or return nil if no current span exists.
 *
 * array[0] is an NSString containing the trace ID
 * array[1] is an NSString containing the span ID
 */
- (NSArray * _Nullable)getCurrentTraceAndSpanIdV1 {
    auto spanStackingHandler = self.spanStackingHandler;
    if (spanStackingHandler == nullptr) {
        return nil;
    }
    auto span = spanStackingHandler->currentSpan();
    if (span == nil) {
        return nil;
    }
    return @[
        [NSString stringWithFormat:@"%llx%llx", span.traceId.hi, span.traceId.lo],
        [NSString stringWithFormat:@"%llx", span.spanId]
    ];
}

/**
 * Return the final configuration that was provided to [BugsnagPerformance start], or return nil if start has not been called.
 */
- (BugsnagPerformanceConfiguration * _Nullable)getConfigurationV1 {
    return self.configuration;
}

- (BugsnagPerformanceSpan * _Nullable)startSpanV1:(NSString * _Nonnull)name options:(BugsnagPerformanceSpanOptions *)optionsIn {
    auto tracer = self.tracer;
    if (tracer == nullptr) {
        return nil;
    }
    
    auto options = SpanOptions(optionsIn);
    auto span = tracer->startCustomSpan(name, options);
    return span;
}

#pragma mark BSGPhasedStartup

- (void)earlyConfigure:(BSGEarlyConfiguration *)config {}

- (void)earlySetup {}

- (void)configure:(BugsnagPerformanceConfiguration *)config {
    self.configuration = config;
}

- (void)start {}

- (void)preStartSetup {}

#pragma mark Internal Functionality

static NSString *BSGUserInfoKeyMapped = @"mapped";
static NSString *BSGUserInfoValueMappedYes = @"YES";
static NSString *BSGUserInfoValueMappedNo = @"NO";

/**
 * Map a named API to a method with the specified selector.
 * If an error occurs, the user info dictionary of the error will contain a field "mapped".
 * If "mapped" is "YES", then the selector has been mapped to a null implementation (does nothing, returns nil).
 * If "mapped" is "NO", then no mapping has occurred, and the method doesn't exist (alling it will result in no such selector).
 */
+ (NSError *)mapAPINamed:(NSString * _Nonnull)apiName toSelector:(SEL)toSelector {
    NSError *err = nil;
    // By default, we map to a "do nothing" implementation in case we don't find a real one.
    SEL fromSelector = @selector(internal_doNothing);

    // Note: ALWAYS ALWAYS ALWAYS check every single API mapping with a unit test!!!
    if ([apiName isEqualToString:@"getCurrentTraceAndSpanIdV1"]) {
        fromSelector = @selector(getCurrentTraceAndSpanIdV1);
    } else if ([apiName isEqualToString:@"getConfigurationV1"]) {
        fromSelector = @selector(getConfigurationV1);
    } else if ([apiName isEqualToString:@"startSpanV1"]) {
        fromSelector = @selector(startSpanV1:options:);
    } else {
        err = [NSError errorWithDomain:@"com.bugsnag.BugsnagCocoaPerformance"
                                  code:0
                              userInfo:@{
            NSLocalizedDescriptionKey:[NSString stringWithFormat:@"No such API: %@", apiName],
            BSGUserInfoKeyMapped:BSGUserInfoValueMappedYes
        }];
    }

    Method method = class_getInstanceMethod(self.class, fromSelector);
    if (method == nil) {
        return [NSError errorWithDomain:@"com.bugsnag.BugsnagCocoaPerformance"
                                  code:0
                              userInfo:@{
            NSLocalizedDescriptionKey:[NSString stringWithFormat:
                                       @"class_getInstanceMethod (while mapping api %@): Failed to find instance method %@ in class %@",
                                       apiName,
                                       NSStringFromSelector(fromSelector),
                                       self.class],
            BSGUserInfoKeyMapped:BSGUserInfoValueMappedNo
        }];
    }

    IMP imp = method_getImplementation(method);
    if (imp == nil) {
        return [NSError errorWithDomain:@"com.bugsnag.BugsnagCocoaPerformance"
                                  code:0
                              userInfo:@{
            NSLocalizedDescriptionKey:[NSString stringWithFormat:
                                       @"method_getImplementation (while mapping api %@): Failed to find implementation of instance method %@ in class %@",
                                       apiName,
                                       NSStringFromSelector(fromSelector),
                                       self.class],
            BSGUserInfoKeyMapped:BSGUserInfoValueMappedNo
        }];
    }

    const char* encoding = method_getTypeEncoding(method);
    if (encoding == nil) {
        return [NSError errorWithDomain:@"com.bugsnag.BugsnagCocoaPerformance"
                                  code:0
                              userInfo:@{
            NSLocalizedDescriptionKey:[NSString stringWithFormat:
                                       @"method_getTypeEncoding (while mapping api %@): Failed to find signature of instance method %@ in class %@",
                                       apiName,
                                       NSStringFromSelector(fromSelector),
                                       self.class],
            BSGUserInfoKeyMapped:BSGUserInfoValueMappedNo
        }];
    }

    if (!class_addMethod(self.class, toSelector, imp, encoding)) {
        return [NSError errorWithDomain:@"com.bugsnag.BugsnagCocoaPerformance"
                                  code:0
                              userInfo:@{
            NSLocalizedDescriptionKey:[NSString stringWithFormat:
                                       @"class_addMethod (while mapping api %@): Failed to add instance method %@ to class %@",
                                       apiName,
                                       NSStringFromSelector(fromSelector),
                                       self.class],
            BSGUserInfoKeyMapped:BSGUserInfoValueMappedNo
        }];
    }

    return err;
}

- (void * _Nullable)internal_doNothing {
    return NULL;
}

+ (instancetype) sharedInstance {
    static id sharedInstance;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ sharedInstance = [[self alloc] init]; });
    return sharedInstance;
}

@end
