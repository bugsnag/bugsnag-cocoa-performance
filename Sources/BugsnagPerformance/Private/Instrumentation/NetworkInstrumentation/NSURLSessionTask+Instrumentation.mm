//
//  NSURLSessionTask+Instrumentation.mm
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 25.04.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import "NSURLSessionTask+Instrumentation.h"
#import "../../Swizzle.h"
#import <objc/runtime.h>

using namespace bugsnag;

static const int associatedSpan = 0;
const void *bsg_associatedNetworkSpanKey = &associatedSpan;

static NSArray<Class> *getURLSessionTaskClassesWithResumeMethod() {
    // Modeled after:
    // https://github.com/AFNetworking/AFNetworking/blob/master/AFNetworking/AFURLSessionManager.m#L355

    if (!NSClassFromString(@"NSURLSessionTask")) {
        return @[];
    }

    /* iOS prior to 14 used various CF classes (such as __NSCFURLSessionTask) to implement
     * the class cluster, after which everything was moved out of Core Framework.
     *
     * To account for this, we walk the inheritance chain to find all classes that implement
     * the methods we're interested in.
     */

    NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:(NSURL * _Nonnull)[NSURL URLWithString:@""]];

    auto classes = ObjCSwizzle::getClassesWithSelector(dataTask.class, @selector(resume));

    [dataTask cancel];
    [session finishTasksAndInvalidate];

    return classes;
}

static void replace_NSURLSessionTask_resume(Class cls, std::shared_ptr<Tracer> tracer) {
    SEL selector = @selector(resume);
    typedef void (*IMPPrototype)(id, SEL);
    __block IMPPrototype originalIMP = (IMPPrototype)ObjCSwizzle::replaceInstanceMethodOverride(cls,
                                                                                            selector,
                                                                                            ^(id self) {
        SpanOptions options;
        auto span = tracer->startNetworkSpan([self originalRequest].HTTPMethod, options);
        objc_setAssociatedObject(self, bsg_associatedNetworkSpanKey, span,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);

        originalIMP(self, selector);
    });
}

void bsg_installNSURLSessionTaskPerformance(std::shared_ptr<Tracer> tracer) noexcept {
    for (Class cls in getURLSessionTaskClassesWithResumeMethod()) {
        replace_NSURLSessionTask_resume(cls, tracer);
    }
}
