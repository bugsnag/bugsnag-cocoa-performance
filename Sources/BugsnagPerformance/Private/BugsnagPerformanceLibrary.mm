//
//  BugsnagPerformanceLibrary.mm
//  
//
//  Created by Karl Stenerud on 11.04.23.
//

#import "BugsnagPerformanceLibrary.h"
#import "Reachability.h"
#import <objc/runtime.h>

using namespace bugsnag;

[[clang::no_destroy]]
static std::shared_ptr<BugsnagPerformanceLibrary> instance_do_not_access_directly;

BugsnagPerformanceLibrary &BugsnagPerformanceLibrary::sharedInstance() noexcept {
    // This will first be called before main by the static initializer code
    // (via calledAsEarlyAsPossible), which is a single-thread environment.
    if (!instance_do_not_access_directly) {
        instance_do_not_access_directly = std::shared_ptr<BugsnagPerformanceLibrary>(new BugsnagPerformanceLibrary);
    }

    return *instance_do_not_access_directly;
}

void BugsnagPerformanceLibrary::calledAsEarlyAsPossible() noexcept {
    sharedInstance();
}

static void getURLSessionTaskClasses(NSMutableArray<Class> *setStateClasses, NSMutableArray<Class> *resumeClasses) {
    // Modeled after:
    // https://github.com/AFNetworking/AFNetworking/blob/master/AFNetworking/AFURLSessionManager.m#L355

    if (!NSClassFromString(@"NSURLSessionTask")) {
        return;
    }

    /* iOS prior to 14 used various CF bridge classes such as __NSCFURLSessionTask to
     * implement the resume and setState methods, after which the functionality was moved
     * out of Core Framework.
     *
     * To account for this, we walk the inheritance chain to find all classes that implement
     * setState and resume.
     *
     * Note: Although resume is implemented in both NSURLSessionTask and CF bridge classes,
     *       the overriden method doesn't call its superclass.
     */

    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSURLSessionDataTask *localDataTask = [session dataTaskWithURL:(NSURL * _Nonnull)[NSURL URLWithString:@""]];
    Class dataTaskClass = [localDataTask class];

    static void (^getClassesWithSelector)(Class cls, SEL selector, NSMutableArray<Class> *result) =
    ^void(Class cls, SEL selector, NSMutableArray<Class> *result) {
        for (Class current = cls; class_getInstanceMethod(current, selector); current = [current superclass]) {
            Class superCls = [current superclass];
            IMP classIMP = method_getImplementation((Method _Nonnull)class_getInstanceMethod(current, selector));
            IMP superIMP = method_getImplementation((Method _Nonnull)class_getInstanceMethod(superCls, selector));
            if (classIMP != superIMP) {
                [result addObject:current];
            }
        }
    };

    getClassesWithSelector(dataTaskClass, NSSelectorFromString(@"setState:"), setStateClasses);
    getClassesWithSelector(dataTaskClass, NSSelectorFromString(@"resume"), resumeClasses);

    [localDataTask cancel];
    [session finishTasksAndInvalidate];
}

void checkStuff(void) {
    NSMutableArray<Class> *setStateClasses = [NSMutableArray new];
    NSMutableArray<Class> *resumeClasses = [NSMutableArray new];
    getURLSessionTaskClasses(setStateClasses, resumeClasses);
    NSLog(@"### setState: %@, resume %@", setStateClasses, resumeClasses);
}

void BugsnagPerformanceLibrary::calledRightBeforeMain() noexcept {
    checkStuff();

    sharedInstance().appStartupInstrumentation_->willCallMainFunction();
}

void BugsnagPerformanceLibrary::configure(BugsnagPerformanceConfiguration *config) noexcept {
    NSError *__autoreleasing error = nil;
    if (![config validate:&error]) {
        BSGLogError(@"Configuration validation failed with error: %@", error);
    }

    sharedInstance().configureInstance(config);
}

BugsnagPerformanceLibrary::BugsnagPerformanceLibrary()
: appStateTracker_([[AppStateTracker alloc] init])
, reachability_(new Reachability)
, bugsnagPerformanceImpl_(new BugsnagPerformanceImpl(reachability_, appStateTracker_))
, appStartupInstrumentation_(new AppStartupInstrumentation(bugsnagPerformanceImpl_))
{
    bugsnagPerformanceImpl_->tracer_.setOnViewLoadSpanStarted(^(NSString *className) {
        appStartupInstrumentation_->didStartViewLoadSpan(className);
    });
}

void BugsnagPerformanceLibrary::configureInstance(BugsnagPerformanceConfiguration *config) noexcept {
    bugsnagPerformanceImpl_->configure(config);
    appStartupInstrumentation_->configure(config);
}

std::shared_ptr<BugsnagPerformanceImpl> BugsnagPerformanceLibrary::getBugsnagPerformanceImpl() noexcept {
    return sharedInstance().bugsnagPerformanceImpl_;
}

std::shared_ptr<AppStartupInstrumentation> BugsnagPerformanceLibrary::getAppStartupInstrumentation() noexcept {
    return sharedInstance().appStartupInstrumentation_;
}

std::shared_ptr<Reachability> BugsnagPerformanceLibrary::getReachability() noexcept {
    return sharedInstance().reachability_;
}

AppStateTracker *BugsnagPerformanceLibrary::getAppStateTracker() noexcept {
    return sharedInstance().appStateTracker_;
}

// Keep old instances around while testing so that lingering callbacks don't reference
// a defunct instance.
[[clang::no_destroy]]
static std::vector<std::shared_ptr<BugsnagPerformanceLibrary>> testing_previous_instances;

void BugsnagPerformanceLibrary::testing_reset() {
    testing_previous_instances.push_back(instance_do_not_access_directly);
    instance_do_not_access_directly.reset();
    calledAsEarlyAsPossible();
    calledRightBeforeMain();
}
