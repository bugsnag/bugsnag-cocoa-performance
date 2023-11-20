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

static void replace_NSURLSessionTask_resume(Class cls, BSGSessionTaskResumeCallback onResume) {
    __weak BSGSessionTaskResumeCallback weakOnResume = onResume;
    __block SEL selector = @selector(resume);
    __block IMP resume = ObjCSwizzle::replaceInstanceMethodOverride(cls, selector, ^(id self) {
        BSGSessionTaskResumeCallback localOnResume = weakOnResume;
        if (localOnResume != nil) {
            localOnResume(self);
        }
        if (resume) {
            reinterpret_cast<void (*)(id, SEL)>(resume)(self, selector);
        }
    });
}

void bsg_installNSURLSessionTaskPerformance(void (^onResume)(NSURLSessionTask *)) noexcept {
    for (Class cls in getURLSessionTaskClassesWithResumeMethod()) {
        replace_NSURLSessionTask_resume(cls, onResume);
    }
}
