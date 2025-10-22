//
//  BugsnagPerformanceLibrary.mm
//  
//
//  Created by Karl Stenerud on 11.04.23.
//

#import "BugsnagPerformanceLibrary.h"
#import "../Utils/Reachability.h"

using namespace bugsnag;

[[clang::no_destroy]]
static std::shared_ptr<BugsnagPerformanceLibrary> instance_do_not_access_directly;

BugsnagPerformanceLibrary &BugsnagPerformanceLibrary::sharedInstance() noexcept {
    // This will first be called before main by the static initializer code
    // (via calledAsEarlyAsPossible), which is a single-thread environment.
    if (!instance_do_not_access_directly) {
        instance_do_not_access_directly = std::shared_ptr<BugsnagPerformanceLibrary>(new BugsnagPerformanceLibrary);
        instance_do_not_access_directly->initialize();
    }

    return *instance_do_not_access_directly;
}

void BugsnagPerformanceLibrary::calledAsEarlyAsPossible() noexcept {
    @autoreleasepool {
        BSGLogDebug(@"BugsnagPerformanceLibrary::calledAsEarlyAsPossible");
        auto instance = sharedInstance();
        auto config = [BSGEarlyConfiguration new];
        instance.earlyConfigure(config);
        instance.earlySetup();
    }
}

void BugsnagPerformanceLibrary::calledRightBeforeMain() noexcept {
    @autoreleasepool {
        BSGLogDebug(@"BugsnagPerformanceLibrary::calledRightBeforeMain");
        sharedInstance().bugsnagPerformanceImpl_->willCallMainFunction();
    }
}

void BugsnagPerformanceLibrary::configureLibrary(BugsnagPerformanceConfiguration *config) noexcept {
    @autoreleasepool {
        BSGLogDebug(@"BugsnagPerformanceLibrary::configureLibrary: apiKey = %@", config.apiKey);
        BSGLogDebug(@"BugsnagPerformanceLibrary::configureLibrary: endpoint = %@", config.endpoint);
        BSGLogDebug(@"BugsnagPerformanceLibrary::configureLibrary: autoInstrumentAppStarts = %d", config.autoInstrumentAppStarts);
        BSGLogDebug(@"BugsnagPerformanceLibrary::configureLibrary: autoInstrumentViewControllers = %d", config.autoInstrumentViewControllers);
        BSGLogDebug(@"BugsnagPerformanceLibrary::configureLibrary: autoInstrumentNetworkRequests = %d", config.autoInstrumentNetworkRequests);
        BSGLogDebug(@"BugsnagPerformanceLibrary::configureLibrary: appVersion = %@", config.appVersion);
        BSGLogDebug(@"BugsnagPerformanceLibrary::configureLibrary: bundleVersion = %@", config.bundleVersion);
        BSGLogDebug(@"BugsnagPerformanceLibrary::configureLibrary: releaseStage = %@", config.releaseStage);
        BSGLogDebug(@"BugsnagPerformanceLibrary::configureLibrary: enabledReleaseStages = %@", config.enabledReleaseStages);
        BSGLogDebug(@"BugsnagPerformanceLibrary::configureLibrary: tracePropagationUrls = %@", config.tracePropagationUrls);
        BSGLogDebug(@"BugsnagPerformanceLibrary::configureLibrary: clearPersistenceOnStart = %d", config.internal.clearPersistenceOnStart);
        BSGLogDebug(@"BugsnagPerformanceLibrary::configureLibrary: autoTriggerExportOnBatchSize = %llu", config.internal.autoTriggerExportOnBatchSize);
        BSGLogDebug(@"BugsnagPerformanceLibrary::configureLibrary: performWorkInterval = %f", config.internal.performWorkInterval);
        BSGLogDebug(@"BugsnagPerformanceLibrary::configureLibrary: maxRetryAge = %f", config.internal.maxRetryAge);
        BSGLogDebug(@"BugsnagPerformanceLibrary::configureLibrary: probabilityValueExpiresAfterSeconds = %f", config.internal.probabilityValueExpiresAfterSeconds);
        BSGLogDebug(@"BugsnagPerformanceLibrary::configureLibrary: probabilityRequestsPauseForSeconds = %f", config.internal.probabilityRequestsPauseForSeconds);
        BSGLogDebug(@"BugsnagPerformanceLibrary::configureLibrary: initialSamplingProbability = %f", config.internal.initialSamplingProbability);
        BSGLogDebug(@"BugsnagPerformanceLibrary::configureLibrary: maxPackageContentLength = %llu", config.internal.maxPackageContentLength);

        NSError *__autoreleasing error = nil;
        if (![config validate:&error]) {
            BSGLogError(@"Configuration validation failed with error: %@", error);
        }

        sharedInstance().configure(config);
    }
}

void BugsnagPerformanceLibrary::startLibrary() noexcept {
    @autoreleasepool {
        BSGLogDebug(@"BugsnagPerformanceLibrary::startLibrary");
        sharedInstance().preStartSetup();
        sharedInstance().start();
    }
}

BugsnagPerformanceLibrary::BugsnagPerformanceLibrary() {}

void BugsnagPerformanceLibrary::earlyConfigure(BSGEarlyConfiguration *config) noexcept {
    BSGLogDebug(@"BugsnagPerformanceLibrary::configureLibrary");
    bugsnagPerformanceImpl_->earlyConfigure(config);
}

void BugsnagPerformanceLibrary::earlySetup() noexcept {
    BSGLogDebug(@"BugsnagPerformanceLibrary::earlySetup");
    auto impl = bugsnagPerformanceImpl_;
    bugsnagPerformanceImpl_->earlySetup();
}

void BugsnagPerformanceLibrary::configure(BugsnagPerformanceConfiguration *config) noexcept {
    BSGLogDebug(@"BugsnagPerformanceLibrary::configure");
    bugsnagPerformanceImpl_->configure(config);
}

void BugsnagPerformanceLibrary::preStartSetup() noexcept {
    BSGLogDebug(@"BugsnagPerformanceLibrary::preStartSetup");
    bugsnagPerformanceImpl_->preStartSetup();
}

void BugsnagPerformanceLibrary::start() noexcept {
    BSGLogDebug(@"BugsnagPerformanceLibrary::start");
    bugsnagPerformanceImpl_->start();
}

std::shared_ptr<BugsnagPerformanceImpl> BugsnagPerformanceLibrary::getBugsnagPerformanceImpl() noexcept {
    return sharedInstance().bugsnagPerformanceImpl_;
}

void BugsnagPerformanceLibrary::initialize() noexcept {
    bugsnagPerformanceImpl_ = std::make_shared<BugsnagPerformanceImpl>(std::make_shared<MainModule>(),
                                                                       ^BugsnagPerformanceNetworkRequestInfo * _Nonnull(BugsnagPerformanceNetworkRequestInfo * _Nonnull info) {
                                                                           return info;
                                                                       });
    bugsnagPerformanceImpl_->initialize();
}
