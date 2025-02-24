//
//  BugsnagPerformanceCrossTalkAPI.mm
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 10.05.24.
//  Copyright © 2024 Bugsnag. All rights reserved.
//

#import "BugsnagPerformanceCrossTalkAPI.h"
#import "SpanStackingHandler.h"
#import "Tracer.h"
#import "Utils.h"
#import <objc/runtime.h>

using namespace bugsnag;

typedef void (^AppStartCallback)(BugsnagPerformanceSpan *);
typedef void (^ViewLoadCallback)(BugsnagPerformanceSpan *, UIViewController *);


@interface BugsnagPerformanceCrossTalkAPI ()

// Declare the things your API class needs here

@property(nonatomic) std::shared_ptr<SpanStackingHandler> spanStackingHandler;
@property(nonatomic) std::shared_ptr<Tracer> tracer;
@property(readwrite, nonatomic) BugsnagPerformanceConfiguration *configuration;
@property(nonatomic, copy) NSArray<AppStartCallback> *willEndUIInitSpanCallbacks;
@property(nonatomic, copy) NSArray<ViewLoadCallback> *willEndViewLoadSpanCallbacks;

@end


@implementation BugsnagPerformanceCrossTalkAPI

/**
 * You'll call your initialize method during start up.
 */
+ (void)initializeWithSpanStackingHandler:(std::shared_ptr<SpanStackingHandler>) handler tracer:(std::shared_ptr<bugsnag::Tracer>)tracer {
    BugsnagPerformanceCrossTalkAPI.sharedInstance.spanStackingHandler = handler;
    BugsnagPerformanceCrossTalkAPI.sharedInstance.tracer = tracer;
}

#pragma mark Exposed API

// Implement internal functions you want to expose to a CrossTalk client library here.
// NOTE: ALWAYS ALWAYS ALWAYS check the mapping of every single API with a unit test!!!

/**
 * For unit tests only.
 */
- (NSString *)returnStringTestV1 {
    return @"test";
}

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
        [NSString stringWithFormat:@"%llx%llx", span.traceIdHi, span.traceIdLo],
        [NSString stringWithFormat:@"%llx", span.spanId]
    ];
}

/**
 * Return the final configuration that was provided to [BugsnagPerformance start], or return nil if start has not been called.
 */
- (BugsnagPerformanceConfiguration * _Nullable)getConfigurationV1 {
    return (BugsnagPerformanceConfiguration *)[BugsnagPerformanceCrossTalkProxiedObject proxied:self.configuration];
}

- (BugsnagPerformanceSpan * _Nullable)startSpanV1:(NSString * _Nonnull)name options:(BugsnagPerformanceSpanOptions *)optionsIn {
    auto tracer = self.tracer;
    if (tracer == nullptr) {
        return nil;
    }

    auto options = SpanOptions(optionsIn);
    auto span = tracer->startSpan(name, options, BSGTriStateUnset);
    return (BugsnagPerformanceSpan *)[BugsnagPerformanceCrossTalkProxiedObject proxied:span];
}

- (BugsnagPerformanceSpanOptions *)newSpanOptionsV1 {
    return (BugsnagPerformanceSpanOptions *)[BugsnagPerformanceCrossTalkProxiedObject proxied:[BugsnagPerformanceSpanOptions new]];
}

- (BugsnagPerformanceSpanContext *)newSpanContextV1:(uint64_t)traceIdHi traceIdLo:(uint64_t)traceIdLo spanId:(SpanId)spanId {
    BugsnagPerformanceSpanContext *spanContext = [[BugsnagPerformanceSpanContext alloc] initWithTraceIdHi:traceIdHi
                                                                                                traceIdLo:traceIdLo spanId:spanId];
    return (BugsnagPerformanceSpanContext *)[BugsnagPerformanceCrossTalkProxiedObject proxied:spanContext];
}

/**
 * Add a callback that will be fired right before an UI init app start span is ended.
 */
- (void)addWillEndUIInitSpanCallbackV1:(AppStartCallback)callback {
    @synchronized (self) {
        self.willEndUIInitSpanCallbacks = [self.willEndUIInitSpanCallbacks arrayByAddingObject:callback];
    }
}

/**
 * Add a callback that will be fired right before a view load start span is ended.
 */
- (void)addWillEndViewLoadSpanCallbackV1:(ViewLoadCallback)callback {
    @synchronized (self) {
        self.willEndViewLoadSpanCallbacks = [self.willEndViewLoadSpanCallbacks arrayByAddingObject:callback];
    }
}

/**
 * Return the top-most span of a given category from the stack.
 */
- (BugsnagPerformanceSpan *)findSpanForCategoryV1:(NSString *)categoryName {
    return self.spanStackingHandler->findSpanForCategory(categoryName);
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

static NSString *BSGUserInfoKeyIsSafeToCall = @"isSafeToCall";
static NSString *BSGUserInfoKeyWillNOOP = @"willNOOP";

static bool classImplementsSelector(Class cls, SEL selector) {
    bool selectorExists = false;
    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList(cls, &methodCount);
    for (unsigned int i = 0; i < methodCount; i++) {
        if (method_getName(methods[i]) == selector) {
            selectorExists = true;
            break;
        }
    }
    free(methods);
    return selectorExists;
}

/**
 * Map a named API to a method with the specified selector.
 *
 * If an error occurs, the user info dictionary will contain the following NSNumber (boolean) fields:
 *  - "isSafeToCall": If @(YES), this method is safe to call (it has an implementation). Otherwise, calling it WILL throw a selector-not-found exception.
 *  - "willNOOP": If @(YES), calling the mapped method will no-op.
 *
 * Common scenarios:
 *  - The host library isn't linked in: isSafeToCall = YES, willNOOP = YES
 *  - apiName doesn't exist: isSafeToCall = YES, willNOOP = YES
 *  - toSelector already exists: isSafeToCall = YES, willNOOP = NO
 *  - Tried to map the same thing twice: isSafeToCall = YES, willNOOP = NO
 *  - Selector signature clash: isSafeToCall = NO, willNOOP = NO
 */
+ (NSError *)mapAPINamed:(NSString * _Nonnull)apiName toSelector:(SEL)toSelector {
    NSError *err = nil;
    // By default, we map to a "do nothing" implementation in case we don't find a real one.
    SEL fromSelector = @selector(internal_doNothing);

    // apiName should map to an existing method in this API
    SEL apiSelector = NSSelectorFromString(apiName);
    if (classImplementsSelector(self.class, apiSelector)) {
        fromSelector = apiSelector;
    } else {
        err = [NSError errorWithDomain:@"com.bugsnag.BugsnagCocoaPerformance"
                                  code:0
                              userInfo:@{
            NSLocalizedDescriptionKey:[NSString stringWithFormat:@"No such API: %@", apiName],
            BSGUserInfoKeyIsSafeToCall:@YES,
            BSGUserInfoKeyWillNOOP:@YES
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
            BSGUserInfoKeyIsSafeToCall:@NO,
            BSGUserInfoKeyWillNOOP:@NO
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
            BSGUserInfoKeyIsSafeToCall:@NO,
            BSGUserInfoKeyWillNOOP:@NO
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
            BSGUserInfoKeyIsSafeToCall:@NO,
            BSGUserInfoKeyWillNOOP:@NO
        }];
    }

    // Don't add a method that already exists
    if (classImplementsSelector(self.class, toSelector)) {
        return [NSError errorWithDomain:@"com.bugsnag.BugsnagCocoaPerformance"
                                  code:0
                              userInfo:@{
            NSLocalizedDescriptionKey:[NSString stringWithFormat:
                                       @"class_addMethod (while mapping api %@): Instance method %@ already exists in class %@",
                                       apiName,
                                       NSStringFromSelector(fromSelector),
                                       self.class],
            BSGUserInfoKeyIsSafeToCall:@YES,
            BSGUserInfoKeyWillNOOP:@NO
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
            BSGUserInfoKeyIsSafeToCall:@NO,
            BSGUserInfoKeyWillNOOP:@NO
        }];
    }

    return err;
}

- (void * _Nullable)internal_doNothing {
    return NULL;
}

+ (instancetype)sharedInstance {
    static BugsnagPerformanceCrossTalkAPI *sharedInstance;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
        sharedInstance.willEndUIInitSpanCallbacks = [NSArray array];
        sharedInstance.willEndViewLoadSpanCallbacks = [NSArray array];
    });
    return sharedInstance;
}

- (void)willEndUIInitSpan:(BugsnagPerformanceSpan *)span {
    for (AppStartCallback callback in self.willEndUIInitSpanCallbacks) {
        callback(span);
    }
}

- (void)willEndViewLoadSpan:(BugsnagPerformanceSpan *)span viewController:(UIViewController *)viewController {
    for (ViewLoadCallback callback in self.willEndViewLoadSpanCallbacks) {
        callback(span, viewController);
    }
}

@end


#pragma mark BugsnagPerformanceCrossTalkProxiedObject

@interface BugsnagPerformanceCrossTalkProxiedObject ()

@property(nonatomic,strong) id delegate;

@end

@implementation BugsnagPerformanceCrossTalkProxiedObject

+ (instancetype _Nullable) proxied:(id _Nullable)delegate {
    if (delegate == nil) {
        return nil;
    }

    BugsnagPerformanceCrossTalkProxiedObject *proxy = [BugsnagPerformanceCrossTalkProxiedObject alloc];
    proxy.delegate = delegate;
    return proxy;
}

// Allow faster access to ivars in these special cases
#pragma clang diagnostic ignored "-Wdirect-ivar-access"

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    if ([_delegate respondsToSelector:anInvocation.selector]) {
        [anInvocation setTarget:_delegate];
        [anInvocation invoke];
    }
}

-(NSMethodSignature*)methodSignatureForSelector:(SEL)aSelector {
    NSMethodSignature *sig = [_delegate methodSignatureForSelector:aSelector];
    if (sig) {
        return sig;
    }

    BSGLogWarning(@"CrossTalk: Tried to invoke unimplemented selector [%@] on proxied object %@",
                  NSStringFromSelector(aSelector), [_delegate debugDescription]);

    // Return a no-arg signature that's guaranteed to exist
    return [NSObject instanceMethodSignatureForSelector:@selector(init)];
}

#pragma mark NSObject protocol (BugsnagPerformanceCrossTalkProxiedObject)

- (Class)class {
    return [_delegate class];
}

- (Class)superclass {
    return [_delegate superclass];
}

- (BOOL)isKindOfClass:(Class)aClass {
    return [_delegate isKindOfClass:aClass];
}

- (BOOL)isMemberOfClass:(Class)aClass {
    return [_delegate isMemberOfClass:aClass];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    // Be truthful about this
    return [_delegate respondsToSelector:aSelector];
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
    // Be truthful about this
    return [_delegate conformsToProtocol:aProtocol];
}

- (BOOL)isEqual:(id)object {
    return [_delegate isEqual:object];
}

- (NSUInteger)hash {
    return [_delegate hash];
}

- (BOOL)isProxy {
    return YES;
}

- (NSString *)description {
    if (_delegate) {
        return [_delegate description];
    }
    return super.description;
}

- (NSString *)debugDescription {
    if (_delegate) {
        return [_delegate debugDescription];
    }
    return super.debugDescription;
}

@end
