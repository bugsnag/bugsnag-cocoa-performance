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
#import <memory>

namespace bugsnag {

/**
 * Bugsnag backend uploader.
 * Also informs via callback any changes the backend makes to the probability value.
 */
class OtlpUploader: public Uploader {
public:
    OtlpUploader(NSURL *endpoint, NSString *apiKey, NewProbabilityCallback newProbabilityCallback) noexcept
    : endpoint_(endpoint)
    , apiKey_(apiKey)
    , newProbabilityCallback_(newProbabilityCallback)
    {}

    virtual ~OtlpUploader() = default;

    void upload(OtlpPackage &package, UploadResultCallback callback) noexcept override;

private:
    const NSURL *endpoint_{nil};
    NSString *apiKey_{nil};
    NewProbabilityCallback newProbabilityCallback_{nullptr};

    UploadResult getUploadResult(NSURLResponse *response) const;
    double getNewProbability(NSURLResponse *response) const;
};
}
