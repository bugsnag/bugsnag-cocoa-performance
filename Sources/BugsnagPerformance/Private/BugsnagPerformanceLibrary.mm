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

void checkStuff(void) {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSURLSessionDataTask *localDataTask = [session dataTaskWithURL:(NSURL * _Nonnull)[NSURL URLWithString:@""]];
    Class currentClass = [localDataTask class];

    SEL setStateSelector = NSSelectorFromString(@"setState:");
    while (class_getInstanceMethod(currentClass, setStateSelector)) {
        Class superClass = [currentClass superclass];
        IMP classResumeIMP = method_getImplementation((Method _Nonnull)class_getInstanceMethod(currentClass, setStateSelector));
        IMP superclassResumeIMP = method_getImplementation((Method _Nonnull)class_getInstanceMethod(superClass, setStateSelector));
        if (classResumeIMP != superclassResumeIMP) {
            NSLog(@"### setState: %@", currentClass);
        }
        currentClass = [currentClass superclass];
    }

    currentClass = [localDataTask class];
    SEL resumeSelector = NSSelectorFromString(@"resume");
    while (class_getInstanceMethod(currentClass, resumeSelector)) {
        Class superClass = [currentClass superclass];
        IMP classResumeIMP = method_getImplementation((Method _Nonnull)class_getInstanceMethod(currentClass, resumeSelector));
        IMP superclassResumeIMP = method_getImplementation((Method _Nonnull)class_getInstanceMethod(superClass, resumeSelector));
        if (classResumeIMP != superclassResumeIMP) {
            NSLog(@"### resume: %@", currentClass);
        }
        currentClass = [currentClass superclass];
    }

    [localDataTask cancel];
    [session finishTasksAndInvalidate];
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
