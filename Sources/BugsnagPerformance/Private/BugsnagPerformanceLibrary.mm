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
    auto instance = sharedInstance();
    auto config = [BSGEarlyConfiguration new];
    instance.earlyConfigure(config);
    instance.earlySetup();
}

void BugsnagPerformanceLibrary::calledRightBeforeMain() noexcept {
    sharedInstance().bugsnagPerformanceImpl_->willCallMainFunction();
}

void BugsnagPerformanceLibrary::configureLibrary(BugsnagPerformanceConfiguration *config) noexcept {
    NSError *__autoreleasing error = nil;
    if (![config validate:&error]) {
        BSGLogError(@"Configuration validation failed with error: %@", error);
    }

    sharedInstance().configure(config);
}

void BugsnagPerformanceLibrary::startLibrary() noexcept {
    sharedInstance().start();
}

BugsnagPerformanceLibrary::BugsnagPerformanceLibrary()
: appStateTracker_([[AppStateTracker alloc] init])
, reachability_(std::make_shared<Reachability>())
, bugsnagPerformanceImpl_(std::make_shared<BugsnagPerformanceImpl>(reachability_, appStateTracker_))
{
    auto impl = bugsnagPerformanceImpl_;
    bugsnagPerformanceImpl_->setOnViewLoadSpanStarted([=](NSString *className) {
        impl->didStartViewLoadSpan(className);
    });
}

void BugsnagPerformanceLibrary::earlyConfigure(BSGEarlyConfiguration *config) noexcept {
    bugsnagPerformanceImpl_->earlyConfigure(config);
}

void BugsnagPerformanceLibrary::earlySetup() noexcept {
    bugsnagPerformanceImpl_->earlySetup();
}

void BugsnagPerformanceLibrary::configure(BugsnagPerformanceConfiguration *config) noexcept {
    bugsnagPerformanceImpl_->configure(config);
}

void BugsnagPerformanceLibrary::start() noexcept {
    bugsnagPerformanceImpl_->start();
}

std::shared_ptr<BugsnagPerformanceImpl> BugsnagPerformanceLibrary::getBugsnagPerformanceImpl() noexcept {
    return sharedInstance().bugsnagPerformanceImpl_;
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
