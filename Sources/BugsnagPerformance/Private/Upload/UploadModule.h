//
//  UploadModule.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 17/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#import "../Core/Module.h"
#import "../Core/Attributes/ResourceAttributes.h"
#import "../Utils/Persistence.h"
#import "RetryQueue.h"
#import "Otlp/OtlpTraceEncoding.h"
#import "Otlp/OtlpUploader.h"
#import "UploadHandler/UploadHandlerImpl.h"

#import <memory>

namespace bugsnag {
class UploadModule: public Module {
public:
    UploadModule(std::shared_ptr<Persistence> persistence,
                 std::shared_ptr<ResourceAttributes> resourceAttributes)
    : persistence_(persistence)
    , resourceAttributes_(resourceAttributes) {};
    
    ~UploadModule() {};
    
    void earlyConfigure(BSGEarlyConfiguration *config) noexcept;
    void earlySetup() noexcept;
    void configure(BugsnagPerformanceConfiguration *config) noexcept;
    void preStartSetup() noexcept;
    void start() noexcept;
    
    void setUp() noexcept;
    void initializeComponentsCallbacks(ModuleTask clearPersistentDataTask,
                                       UpdateProbabilityTask updateProbabilityTask) noexcept {
        retryQueue_->setOnFilesystemError(clearPersistentDataTask);
        uploader_->setNewProbabilityCallback(updateProbabilityTask);
    }
    
    std::shared_ptr<RetryQueue> getRetryQueue() noexcept { return retryQueue_; }
    std::shared_ptr<OtlpTraceEncoding> getTraceEncoding() noexcept { return traceEncoding_; }
    std::shared_ptr<OtlpUploader> getUploader() noexcept { return uploader_; }
    std::shared_ptr<UploadHandler> getUploadHandler() noexcept { return uploadHandler_; }
    
private:
    
    // Dependencies
    std::shared_ptr<Persistence> persistence_;
    std::shared_ptr<ResourceAttributes> resourceAttributes_;
    
    // Components
    std::shared_ptr<RetryQueue> retryQueue_;
    std::shared_ptr<OtlpTraceEncoding> traceEncoding_;
    std::shared_ptr<OtlpUploader> uploader_;
    std::shared_ptr<UploadHandlerImpl> uploadHandler_;
};
}
