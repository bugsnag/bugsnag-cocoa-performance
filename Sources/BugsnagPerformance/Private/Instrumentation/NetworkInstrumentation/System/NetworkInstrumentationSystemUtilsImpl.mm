//
//  NetworkInstrumentationSystemUtilsImpl.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 02/09/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "NetworkInstrumentationSystemUtilsImpl.h"

#import "../../../Swizzle.h"
#import <objc/runtime.h>

using namespace bugsnag;

NSArray<Class> *
NetworkInstrumentationSystemUtilsImpl::taskClassesToInstrument() noexcept {
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
