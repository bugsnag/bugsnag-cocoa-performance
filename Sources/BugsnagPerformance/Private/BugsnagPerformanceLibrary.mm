//
//  BugsnagPerformanceLibrary.mm
//  
//
//  Created by Karl Stenerud on 11.04.23.
//

#import "BugsnagPerformanceLibrary.h"
#import "Reachability.h"

using namespace bugsnag;

[[clang::no_destroy]]
static BugsnagPerformanceLibrary * instance;

void BugsnagPerformanceLibrary::calledAsEarlyAsPossible() noexcept {
    // This will be called before main by the static initializer code, so threading is not an issue.
    if (instance != nullptr) {
        return;
    }

    instance = new BugsnagPerformanceLibrary;
}

void BugsnagPerformanceLibrary::calledRightBeforeMain() noexcept {
    instance->appStartupInstrumentation_->willCallMainFunction();
}

void BugsnagPerformanceLibrary::configure(BugsnagPerformanceConfiguration *config) noexcept {
    instance->configureInstance(config);
}

BugsnagPerformanceLibrary::BugsnagPerformanceLibrary()
: reachability_(new Reachability)
, bugsnagPerformanceImpl_(new BugsnagPerformanceImpl(reachability_))
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
    return instance->bugsnagPerformanceImpl_;
}

std::shared_ptr<AppStartupInstrumentation> BugsnagPerformanceLibrary::getAppStartupInstrumentation() noexcept {
    return instance->appStartupInstrumentation_;
}

std::shared_ptr<Reachability> BugsnagPerformanceLibrary::getReachability() noexcept {
    return instance->reachability_;
}
