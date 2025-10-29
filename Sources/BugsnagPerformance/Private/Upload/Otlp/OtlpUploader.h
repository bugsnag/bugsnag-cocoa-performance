//
//  BugsnagPerformanceUploader.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 04.11.22.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

#pragma once

#import <Foundation/Foundation.h>

#import "Uploader.h"
#import "OtlpPackage.h"
#import "../../Core/PhasedStartup.h"
#import <memory>

namespace bugsnag {

/**
 * Bugsnag backend uploader.
 * Also informs via callback any changes the backend makes to the probability value.
 */
class OtlpUploader: public Uploader, public PhasedStartup {
public:
    OtlpUploader() noexcept {}

    virtual ~OtlpUploader() = default;
    
    void earlyConfigure(BSGEarlyConfiguration *) noexcept {}
    void earlySetup() noexcept {}
    void configure(BugsnagPerformanceConfiguration *config) noexcept {
        endpoint_ = config.endpoint;
        apiKey_ = config.apiKey;
    }
    void preStartSetup() noexcept {}
    void start() noexcept {}

    void upload(OtlpPackage &package, UploadResultCallback callback) noexcept;
    void setNewProbabilityCallback(NewProbabilityCallback newProbabilityCallback) noexcept {
        newProbabilityCallback_ = newProbabilityCallback;
    }

private:
    const NSURL *endpoint_{nil};
    NSString *apiKey_{nil};
    NewProbabilityCallback newProbabilityCallback_{nullptr};

    UploadResult getUploadResult(NSURLResponse *response) const;
    double getNewProbability(NSURLResponse *response) const;
};
}
