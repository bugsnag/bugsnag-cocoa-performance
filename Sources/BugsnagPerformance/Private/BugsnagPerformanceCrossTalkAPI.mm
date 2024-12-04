//
//  BugsnagPerformanceCrossTalkAPI.mm
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 10.05.24.
//  Copyright © 2024 Bugsnag. All rights reserved.
//

#import "BugsnagPerformanceCrossTalkAPI.h"
#import "Utils.h"
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

/**
 * Start a span with a given name and span options
 *
 * Options is an NSDictionary containing the following keys:
 * startTime: an NSNumber containing the start time as a unix nanosecond timestamp
 * makeCurrentContext: an NSNumber with a value of 0 or 1
 * firstClass: an NSNumber with a value of 0 or 1
 * parentContext: an NSDictionary with keys 'id' and 'traceId' as NSString values
 */
- (BugsnagPerformanceSpan * _Nullable)startSpanV1:(NSString * _Nonnull)name options:(NSDictionary * _Nullable)optionsIn {
    auto tracer = self.tracer;
    if (tracer == nullptr) {
        return nil;
    }
    
    auto options = SpanOptions();
    
    if (optionsIn != nil) {
        NSNumber *startTimeUnixNanos = optionsIn[@"startTime"];
        if (startTimeUnixNanos != nil) {
            NSDate *startTime = [NSDate dateWithTimeIntervalSince1970:([startTimeUnixNanos doubleValue] / NSEC_PER_SEC)];
            options.startTime = dateToAbsoluteTime(startTime);
        }
        
        NSNumber *makeCurrentContext = optionsIn[@"makeCurrentContext"];
        if (makeCurrentContext != nil) {
            options.makeCurrentContext = [makeCurrentContext boolValue];
        }
        
        NSNumber *firstClassOpt = optionsIn[@"firstClass"];
        if (firstClassOpt != nil) {
            BSGFirstClass isFirstClass = BSGFirstClass([firstClassOpt intValue]);
        }
        
        NSDictionary *parentContextOpt =optionsIn[@"parentContext"];
        if (parentContextOpt != nil) {
            NSString *parentSpanId = parentContextOpt[@"id"];
            NSString *parentTraceId = parentContextOpt[@"traceId"];

            uint64_t spanId = hexStringToUInt64(parentSpanId);
            uint64_t traceIdHi = hexStringToUInt64([parentTraceId substringToIndex:16]);
            uint64_t traceIdLo = hexStringToUInt64([parentTraceId substringFromIndex:16]);

            options.parentContext = [[BugsnagPerformanceSpanContext alloc] initWithTraceIdHi:traceIdHi
                    traceIdLo:traceIdLo spanId:spanId];
        }
    }
    
    auto span = tracer->startSpan(name, options, BSGFirstClassUnset);
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
